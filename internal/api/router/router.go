package router

import (
	"allaboutapps.dev/aw/go-starter/internal/api"
	"allaboutapps.dev/aw/go-starter/internal/api/handlers"
	"allaboutapps.dev/aw/go-starter/internal/api/middleware"
	"github.com/labstack/echo/v4"
	echoMiddleware "github.com/labstack/echo/v4/middleware"
	"github.com/rs/zerolog/log"
)

func Init(s *api.Server) {
	s.Echo = echo.New()

	s.Echo.Debug = s.Config.Echo.Debug
	s.Echo.HideBanner = true
	s.Echo.Logger.SetOutput(&echoLogger{level: s.Config.Logger.RequestLevel, log: log.With().Str("component", "echo").Logger()})

	s.Echo.HTTPErrorHandler = HTTPErrorHandlerWithConfig(HTTPErrorHandlerConfig{
		HideInternalServerErrorDetails: s.Config.Echo.HideInternalServerErrorDetails,
	})

	// ---
	// General middleware
	s.Echo.Pre(echoMiddleware.RemoveTrailingSlash())

	s.Echo.Use(echoMiddleware.Recover())
	s.Echo.Use(echoMiddleware.RequestID())
	s.Echo.Use(middleware.LoggerWithConfig(middleware.LoggerConfig{
		Level:             s.Config.Logger.RequestLevel,
		LogRequestBody:    s.Config.Logger.LogRequestBody,
		LogRequestHeader:  s.Config.Logger.LogRequestHeader,
		LogRequestQuery:   s.Config.Logger.LogRequestQuery,
		LogResponseBody:   s.Config.Logger.LogResponseBody,
		LogResponseHeader: s.Config.Logger.LogResponseHeader,
	}))
	s.Echo.Use(echoMiddleware.CORS())

	// ---
	// Initialize our general groups and set middleware to use above them
	s.Router = &api.Router{
		Routes: nil, // will be populated by handlers.AttachAllRoutes(s)

		// Unsecured base group available at /**
		Root: s.Echo.Group(""),

		// Management endpoints, secured by key auth (query param), available at /-/**
		Management: s.Echo.Group("/-", echoMiddleware.KeyAuthWithConfig(echoMiddleware.KeyAuthConfig{
			KeyLookup: "query:mgmt-secret",
			Validator: func(key string, c echo.Context) (bool, error) {
				return key == s.Config.Management.Secret, nil
			},
			Skipper: func(c echo.Context) bool {
				switch c.Path() {
				case "/-/ready":
					return true
				}
				return false
			},
		})),

		// OAuth2, unsecured or secured by bearer auth, available at /api/v1/auth/**
		APIV1Auth: s.Echo.Group("/api/v1/auth", middleware.AuthWithConfig(middleware.AuthConfig{
			S:    s,
			Mode: middleware.AuthModeRequired,
			Skipper: func(c echo.Context) bool {
				switch c.Path() {
				case "/api/v1/auth/forgot-password",
					"/api/v1/auth/forgot-password/complete",
					"/api/v1/auth/login",
					"/api/v1/auth/refresh",
					"/api/v1/auth/register":
					return true
				}
				return false
			},
		})),

		// Your other endpoints, typically secured by bearer auth, available at /api/v1/**
		APIV1Push: s.Echo.Group("/api/v1/push", middleware.Auth(s)),
	}

	// ---
	// Finally attach our handlers
	handlers.AttachAllRoutes(s)
}
