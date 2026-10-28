package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	_ "github.com/go-sql-driver/mysql"

	"github.com/joho/godotenv"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var db *sql.DB

var (
	httpRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "app_http_requests_total",
			Help: "Total number of HTTP requests.",
		},
		[]string{"method", "route", "status"},
	)

	httpDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "app_http_request_duration_seconds",
			Help:    "HTTP request duration in seconds.",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "route"},
	)

	httpErrors = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "app_http_errors_total",
			Help: "Total number of HTTP 5xx responses.",
		},
		[]string{"route"},
	)
)

func init() {
	prometheus.MustRegister(
		httpRequests,
		httpDuration,
		httpErrors,
	)
}

// Records request count, duration, and HTTP status.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(status int) {
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}

func instrumentHandler(route string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		recorder := &statusRecorder{
			ResponseWriter: w,
			status:         http.StatusOK,
		}

		next.ServeHTTP(recorder, r)

		status := strconv.Itoa(recorder.status)

		httpRequests.WithLabelValues(
			r.Method, route, status,
		).Inc()

		httpDuration.WithLabelValues(
			r.Method, route,
		).Observe(time.Since(start).Seconds())

		if recorder.status >= 500 {
			httpErrors.WithLabelValues(route).Inc()
		}
	})
}

func nameHandler(w http.ResponseWriter, r *http.Request) {
	var name string

	err := db.QueryRow("SELECT name FROM users LIMIT 1").Scan(&name)
	if err != nil {
		log.Printf("Database query failed: %v", err)
		http.Error(
			w,
			"Internal server error",
			http.StatusInternalServerError,
		)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	if err := json.NewEncoder(w).Encode(map[string]string{
		"name": name,
	}); err != nil {
		log.Printf("Failed to encode JSON response: %v", err)
	}
}

func main() {
	err_load := godotenv.Load("/var/secrets/sql.txt")
	if err_load != nil {
        panic(err_load)
    }

	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	name := os.Getenv("DB_NAME")

	dsn := fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s",
		user,
		password,
		host,
		port,
		name,
	)

	var err error

	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal(err)
	}

	defer func() {
		if err := db.Close(); err != nil {
			log.Printf("failed to close database: %v", err)
		}
	}()

	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/api/name", nameHandler)

	// Expose metrics for Prometheus.
	http.Handle("/metrics", promhttp.Handler())

	// Serve UI.
	http.Handle(
		"/",
		instrumentHandler(
			"/",
			http.FileServer(http.Dir(".")),
		),
	)

	log.Println("Server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))

}
