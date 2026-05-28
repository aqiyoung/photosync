package config

import (
	"os"
	"path/filepath"
)

type Config struct {
	Port       string
	DBPath     string
	StorageDir string
	JWTSecret  string
	TLSCert    string
	TLSKey     string
}

func Load() *Config {
	port := os.Getenv("PORT")
	if port == "" {
		port = "18080"
	}

	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "/vol1/1000/相册/photosync.db"
	}

	storageDir := os.Getenv("STORAGE_DIR")
	if storageDir == "" {
		storageDir = "/vol1/1000/相册/photos"
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "photosync-default-secret-change-me"
	}

	tlsCert := os.Getenv("TLS_CERT")
	tlsKey := os.Getenv("TLS_KEY")

	// Ensure storage directory exists
	os.MkdirAll(filepath.Dir(dbPath), 0755)
	os.MkdirAll(storageDir, 0755)

	return &Config{
		Port:       port,
		DBPath:     dbPath,
		StorageDir: storageDir,
		JWTSecret:  jwtSecret,
		TLSCert:    tlsCert,
		TLSKey:     tlsKey,
	}
}
