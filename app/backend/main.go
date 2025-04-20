package main

import (
	"crypto/tls"
	"crypto/x509"
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/go-sql-driver/mysql"
)

type Patient struct {
	ID         int    `json:"id"`
	FullName   string `json:"full_name"`
	Department string `json:"department"`
	BedNumber  int    `json:"bed_number"`
}

var db *sql.DB

func initDB() {
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")
	dbHost := os.Getenv("DB_HOST")

	rootCertPool := x509.NewCertPool()
	pem, err := ioutil.ReadFile("DigiCertGlobalRootCA.crt.pem")
	if err != nil {
		log.Fatalf("Failed to read certificate: %v", err)
	}
	if ok := rootCertPool.AppendCertsFromPEM(pem); !ok {
		log.Fatal("Failed to append certificate to root CA pool")
	}

	err = mysql.RegisterTLSConfig("custom", &tls.Config{
		RootCAs: rootCertPool,
	})
	if err != nil {
		log.Fatalf("Failed to register TLS config: %v", err)
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s:3306)/%s?tls=custom", dbUser, dbPassword, dbHost, dbName)

	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal(err)
	}

	if err = db.Ping(); err != nil {
		log.Fatalf("Database connection failed: %v", err)
	}

	statement, err := db.Prepare("CREATE TABLE IF NOT EXISTS patient (id INT AUTO_INCREMENT PRIMARY KEY, full_name TEXT, department TEXT, bed_number INT)")
	if err != nil {
		log.Fatal(err)
	}
	statement.Exec()
}

func enableCORS(w http.ResponseWriter, r *http.Request) {
	// Replace "*" with your frontend URL in production
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

func getPatients(w http.ResponseWriter, r *http.Request) {
	enableCORS(w, r)
	if r.Method == http.MethodOptions {
		return
	}

	rows, err := db.Query("SELECT id, full_name, department, bed_number FROM patient")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	patients := []Patient{}
	for rows.Next() {
		var patient Patient
		rows.Scan(&patient.ID, &patient.FullName, &patient.Department, &patient.BedNumber)
		patients = append(patients, patient)
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(patients)
}

func addPatient(w http.ResponseWriter, r *http.Request) {
	enableCORS(w, r)
	if r.Method == http.MethodOptions {
		return
	}

	var patient Patient
	json.NewDecoder(r.Body).Decode(&patient)
	statement, err := db.Prepare("INSERT INTO patient (full_name, department, bed_number) VALUES (?, ?, ?)")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	statement.Exec(patient.FullName, patient.Department, patient.BedNumber)
	w.WriteHeader(http.StatusCreated)
}

func deletePatient(w http.ResponseWriter, r *http.Request) {
	enableCORS(w, r)
	if r.Method == http.MethodOptions {
		return
	}

	idParam := r.URL.Query().Get("id")
	if idParam == "" {
		http.Error(w, "Missing id parameter", http.StatusBadRequest)
		return
	}
	statement, err := db.Prepare("DELETE FROM patient WHERE id = ?")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	_, err = statement.Exec(idParam)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func main() {
	initDB()

	http.HandleFunc("/patients", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			getPatients(w, r)
		case http.MethodPost:
			addPatient(w, r)
		case http.MethodDelete:
			deletePatient(w, r)
		case http.MethodOptions:
			enableCORS(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	log.Println("Backend server started on :8081")
	log.Fatal(http.ListenAndServe(":8081", nil))
}
