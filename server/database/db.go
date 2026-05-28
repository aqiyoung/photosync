package database

import (
	"database/sql"
	_ "modernc.org/sqlite"
)

var DB *sql.DB

func Init(dbPath string) error {
	var err error
	DB, err = sql.Open("sqlite", dbPath+"?_journal_mode=WAL")
	if err != nil {
		return err
	}

	if err = DB.Ping(); err != nil {
		return err
	}

	return migrate()
}

func migrate() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			username TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			created_at TEXT DEFAULT (datetime('now'))
		)`,
		`CREATE TABLE IF NOT EXISTS photos (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			filename TEXT NOT NULL,
			file_path TEXT NOT NULL,
			file_size INTEGER,
			mime_type TEXT,
			width INTEGER,
			height INTEGER,
			file_hash TEXT,
			created_at TEXT,
			uploaded_at TEXT DEFAULT (datetime('now')),
			FOREIGN KEY (user_id) REFERENCES users(id),
			UNIQUE(user_id, file_hash)
		)`,
		`CREATE TABLE IF NOT EXISTS albums (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			name TEXT NOT NULL,
			created_at TEXT DEFAULT (datetime('now')),
			FOREIGN KEY (user_id) REFERENCES users(id)
		)`,
		`CREATE TABLE IF NOT EXISTS album_photos (
			album_id INTEGER,
			photo_id INTEGER,
			PRIMARY KEY (album_id, photo_id),
			FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
			FOREIGN KEY (photo_id) REFERENCES photos(id) ON DELETE CASCADE
		)`,
		`CREATE INDEX IF NOT EXISTS idx_photos_user ON photos(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_photos_hash ON photos(user_id, file_hash)`,
	}

	for _, q := range queries {
		if _, err := DB.Exec(q); err != nil {
			return err
		}
	}
	return nil
}

func Close() {
	if DB != nil {
		DB.Close()
	}
}
