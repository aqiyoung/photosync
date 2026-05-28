package main

import (
	"log"

	"photosync-server/config"
	"photosync-server/database"
	"photosync-server/handlers"
	"photosync-server/middleware"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()

	if err := database.Init(cfg.DBPath); err != nil {
		log.Fatalf("failed to initialize database: %v", err)
	}
	defer database.Close()

	authHandler := &handlers.AuthHandler{JWTSecret: cfg.JWTSecret}
	photoHandler := &handlers.PhotoHandler{StorageDir: cfg.StorageDir}
	albumHandler := &handlers.AlbumHandler{}

	r := gin.Default()
	r.Use(middleware.CORSMiddleware())

	api := r.Group("/api")
	{
		// Auth routes (public)
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
		}

		// Protected routes
		protected := api.Group("")
		protected.Use(middleware.AuthMiddleware(cfg.JWTSecret))
		{
			// Photos
			protected.POST("/photos/upload", photoHandler.Upload)
			protected.GET("/photos", photoHandler.List)
			protected.GET("/photos/:id/file", photoHandler.GetFile)
			protected.DELETE("/photos/:id", photoHandler.Delete)
			protected.POST("/photos/check-sync", photoHandler.CheckSync)

			// Albums
			protected.GET("/albums", albumHandler.List)
			protected.POST("/albums", albumHandler.Create)
			protected.GET("/albums/:id", albumHandler.Get)
			protected.PUT("/albums/:id", albumHandler.Update)
			protected.DELETE("/albums/:id", albumHandler.Delete)
			protected.POST("/albums/:id/photos", albumHandler.AddPhoto)
			protected.DELETE("/albums/:id/photos/:photoId", albumHandler.RemovePhoto)
		}
	}

	if cfg.TLSCert != "" && cfg.TLSKey != "" {
		log.Printf("Server starting on :%s (HTTPS)", cfg.Port)
		if err := r.RunTLS(":"+cfg.Port, cfg.TLSCert, cfg.TLSKey); err != nil {
			log.Fatalf("failed to start server: %v", err)
		}
	} else {
		log.Printf("Server starting on :%s (HTTP)", cfg.Port)
		if err := r.Run(":" + cfg.Port); err != nil {
			log.Fatalf("failed to start server: %v", err)
		}
	}
}
