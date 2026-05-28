package handlers

import (
	"crypto/sha256"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"photosync-server/database"
	"photosync-server/models"
	"photosync-server/utils"

	"github.com/gin-gonic/gin"
)

type PhotoHandler struct {
	StorageDir string
}

func (h *PhotoHandler) Upload(c *gin.Context) {
	userID := c.GetInt("user_id")

	file, header, err := c.Request.FormFile("photo")
	if err != nil {
		utils.Error(c, http.StatusBadRequest, "no photo file provided")
		return
	}
	defer file.Close()

	// Calculate hash
	hasher := sha256.New()
	if _, err := io.Copy(hasher, file); err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to process file")
		return
	}
	fileHash := fmt.Sprintf("%x", hasher.Sum(nil))

	// Check if already exists
	var existingID int
	err = database.DB.QueryRow(
		"SELECT id FROM photos WHERE user_id = ? AND file_hash = ?",
		userID, fileHash,
	).Scan(&existingID)
	if err == nil {
		utils.Success(c, gin.H{"id": existingID, "message": "already synced"})
		return
	}

	// Reset file reader
	file.Seek(0, io.SeekStart)

	// Create user directory: /storage/user_id/year/month/
	now := time.Now()
	relDir := filepath.Join(strconv.Itoa(userID), now.Format("2006"), now.Format("01"))
	absDir := filepath.Join(h.StorageDir, relDir)
	os.MkdirAll(absDir, 0755)

	// Generate filename
	ext := filepath.Ext(header.Filename)
	newFilename := fmt.Sprintf("%s%s", fileHash[:16], ext)
	absPath := filepath.Join(absDir, newFilename)

	// Save file
	dst, err := os.Create(absPath)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to save file")
		return
	}
	defer dst.Close()

	written, err := io.Copy(dst, file)
	if err != nil {
		os.Remove(absPath)
		utils.Error(c, http.StatusInternalServerError, "failed to write file")
		return
	}

	// Parse created_at from form or use now
	createdAt := c.PostForm("created_at")
	if createdAt == "" {
		createdAt = now.Format(time.RFC3339)
	}

	width, _ := strconv.Atoi(c.PostForm("width"))
	height, _ := strconv.Atoi(c.PostForm("height"))

	// Insert into database
	relPath := filepath.Join(relDir, newFilename)
	result, err := database.DB.Exec(
		`INSERT INTO photos (user_id, filename, file_path, file_size, mime_type, width, height, file_hash, created_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		userID, header.Filename, relPath, written, header.Header.Get("Content-Type"),
		width, height, fileHash, createdAt,
	)
	if err != nil {
		os.Remove(absPath)
		utils.Error(c, http.StatusInternalServerError, "failed to save photo metadata")
		return
	}

	photoID, _ := result.LastInsertId()
	utils.Created(c, gin.H{"id": photoID, "file_hash": fileHash})
}

func (h *PhotoHandler) List(c *gin.Context) {
	userID := c.GetInt("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 200 {
		limit = 50
	}
	offset := (page - 1) * limit

	rows, err := database.DB.Query(
		`SELECT id, filename, file_size, mime_type, width, height, file_hash, created_at, uploaded_at
		 FROM photos WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?`,
		userID, limit, offset,
	)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to query photos")
		return
	}
	defer rows.Close()

	photos := []models.Photo{}
	for rows.Next() {
		var p models.Photo
		rows.Scan(&p.ID, &p.Filename, &p.FileSize, &p.MimeType,
			&p.Width, &p.Height, &p.FileHash, &p.CreatedAt, &p.UploadedAt)
		photos = append(photos, p)
	}

	// Get total count
	var total int
	database.DB.QueryRow("SELECT COUNT(*) FROM photos WHERE user_id = ?", userID).Scan(&total)

	utils.Success(c, gin.H{
		"photos": photos,
		"total":  total,
		"page":   page,
		"limit":  limit,
	})
}

func (h *PhotoHandler) GetFile(c *gin.Context) {
	userID := c.GetInt("user_id")
	photoID := c.Param("id")

	var filePath string
	err := database.DB.QueryRow(
		"SELECT file_path FROM photos WHERE id = ? AND user_id = ?",
		photoID, userID,
	).Scan(&filePath)
	if err != nil {
		utils.Error(c, http.StatusNotFound, "photo not found")
		return
	}

	absPath := filepath.Join(h.StorageDir, filePath)
	c.File(absPath)
}

func (h *PhotoHandler) Delete(c *gin.Context) {
	userID := c.GetInt("user_id")
	photoID := c.Param("id")

	var filePath string
	err := database.DB.QueryRow(
		"SELECT file_path FROM photos WHERE id = ? AND user_id = ?",
		photoID, userID,
	).Scan(&filePath)
	if err != nil {
		utils.Error(c, http.StatusNotFound, "photo not found")
		return
	}

	// Delete file
	absPath := filepath.Join(h.StorageDir, filePath)
	os.Remove(absPath)

	// Delete from database
	database.DB.Exec("DELETE FROM photos WHERE id = ? AND user_id = ?", photoID, userID)

	utils.Success(c, nil)
}

func (h *PhotoHandler) CheckSync(c *gin.Context) {
	userID := c.GetInt("user_id")

	var req models.CheckSyncRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "invalid input")
		return
	}

	if len(req.Hashes) == 0 {
		utils.Success(c, models.CheckSyncResponse{SyncedHashes: []string{}})
		return
	}

	// Build query with placeholders
	query := "SELECT file_hash FROM photos WHERE user_id = ? AND file_hash IN ("
	args := []interface{}{userID}
	for i, hash := range req.Hashes {
		if i > 0 {
			query += ","
		}
		query += "?"
		args = append(args, hash)
	}
	query += ")"

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to check sync status")
		return
	}
	defer rows.Close()

	synced := []string{}
	for rows.Next() {
		var hash string
		rows.Scan(&hash)
		synced = append(synced, hash)
	}

	utils.Success(c, models.CheckSyncResponse{SyncedHashes: synced})
}
