package models

import "time"

type Album struct {
	ID        int       `json:"id"`
	UserID    int       `json:"user_id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
	Photos    []Photo   `json:"photos,omitempty"`
}

type AlbumPhoto struct {
	AlbumID int `json:"album_id"`
	PhotoID int `json:"photo_id"`
}
