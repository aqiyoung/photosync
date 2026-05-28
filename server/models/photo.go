package models

import "time"

type Photo struct {
	ID         int       `json:"id"`
	UserID     int       `json:"user_id"`
	Filename   string    `json:"filename"`
	FilePath   string    `json:"-"`
	FileSize   int64     `json:"file_size"`
	MimeType   string    `json:"mime_type"`
	Width      int       `json:"width"`
	Height     int       `json:"height"`
	FileHash   string    `json:"file_hash"`
	CreatedAt  string    `json:"created_at"`
	UploadedAt time.Time `json:"uploaded_at"`
}

type CheckSyncRequest struct {
	Hashes []string `json:"hashes" binding:"required"`
}

type CheckSyncResponse struct {
	SyncedHashes []string `json:"synced_hashes"`
}
