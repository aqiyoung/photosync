package handlers

import (
	"net/http"

	"photosync-server/database"
	"photosync-server/models"
	"photosync-server/utils"

	"github.com/gin-gonic/gin"
)

type AlbumHandler struct{}

type CreateAlbumRequest struct {
	Name string `json:"name" binding:"required"`
}

func (h *AlbumHandler) List(c *gin.Context) {
	userID := c.GetInt("user_id")

	rows, err := database.DB.Query(
		"SELECT id, name, created_at FROM albums WHERE user_id = ? ORDER BY created_at DESC",
		userID,
	)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to query albums")
		return
	}
	defer rows.Close()

	albums := []models.Album{}
	for rows.Next() {
		var a models.Album
		rows.Scan(&a.ID, &a.Name, &a.CreatedAt)
		albums = append(albums, a)
	}

	utils.Success(c, albums)
}

func (h *AlbumHandler) Create(c *gin.Context) {
	userID := c.GetInt("user_id")

	var req CreateAlbumRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "invalid input")
		return
	}

	result, err := database.DB.Exec(
		"INSERT INTO albums (user_id, name) VALUES (?, ?)",
		userID, req.Name,
	)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to create album")
		return
	}

	albumID, _ := result.LastInsertId()
	utils.Created(c, gin.H{"id": albumID, "name": req.Name})
}

func (h *AlbumHandler) Get(c *gin.Context) {
	userID := c.GetInt("user_id")
	albumID := c.Param("id")

	var album models.Album
	err := database.DB.QueryRow(
		"SELECT id, name, created_at FROM albums WHERE id = ? AND user_id = ?",
		albumID, userID,
	).Scan(&album.ID, &album.Name, &album.CreatedAt)
	if err != nil {
		utils.Error(c, http.StatusNotFound, "album not found")
		return
	}

	// Get photos in album
	rows, err := database.DB.Query(
		`SELECT p.id, p.filename, p.file_size, p.mime_type, p.width, p.height, p.file_hash, p.created_at, p.uploaded_at
		 FROM photos p JOIN album_photos ap ON p.id = ap.photo_id
		 WHERE ap.album_id = ? ORDER BY p.created_at DESC`,
		albumID,
	)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var p models.Photo
			rows.Scan(&p.ID, &p.Filename, &p.FileSize, &p.MimeType,
				&p.Width, &p.Height, &p.FileHash, &p.CreatedAt, &p.UploadedAt)
			album.Photos = append(album.Photos, p)
		}
	}

	utils.Success(c, album)
}

func (h *AlbumHandler) Update(c *gin.Context) {
	userID := c.GetInt("user_id")
	albumID := c.Param("id")

	var req CreateAlbumRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "invalid input")
		return
	}

	result, err := database.DB.Exec(
		"UPDATE albums SET name = ? WHERE id = ? AND user_id = ?",
		req.Name, albumID, userID,
	)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to update album")
		return
	}

	affected, _ := result.RowsAffected()
	if affected == 0 {
		utils.Error(c, http.StatusNotFound, "album not found")
		return
	}

	utils.Success(c, nil)
}

func (h *AlbumHandler) Delete(c *gin.Context) {
	userID := c.GetInt("user_id")
	albumID := c.Param("id")

	result, err := database.DB.Exec(
		"DELETE FROM albums WHERE id = ? AND user_id = ?",
		albumID, userID,
	)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to delete album")
		return
	}

	affected, _ := result.RowsAffected()
	if affected == 0 {
		utils.Error(c, http.StatusNotFound, "album not found")
		return
	}

	utils.Success(c, nil)
}

func (h *AlbumHandler) AddPhoto(c *gin.Context) {
	albumID := c.Param("id")

	var req struct {
		PhotoID int `json:"photo_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, http.StatusBadRequest, "invalid input")
		return
	}

	_, err := database.DB.Exec(
		"INSERT OR IGNORE INTO album_photos (album_id, photo_id) VALUES (?, ?)",
		albumID, req.PhotoID,
	)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to add photo to album")
		return
	}

	utils.Success(c, nil)
}

func (h *AlbumHandler) RemovePhoto(c *gin.Context) {
	albumID := c.Param("id")
	photoID := c.Param("photoId")

	_, err := database.DB.Exec(
		"DELETE FROM album_photos WHERE album_id = ? AND photo_id = ?",
		albumID, photoID,
	)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "failed to remove photo from album")
		return
	}

	utils.Success(c, nil)
}
