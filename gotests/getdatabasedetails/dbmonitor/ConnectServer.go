package dbmonitor

import (
	"database/sql"
	"log"
)

type ServerConnected struct {
	Connected bool
}

func QueryServerConnected() string {
	return "SELECT 1 as ServerName"
}

func FetchServerConnected(connString string) bool {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()
	// query starts here
	stmt, err := conn.Query(QueryServerConnected())
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user ServerConnected
		err = stmt.Scan(&user.Connected)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		return user.Connected
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
	return false
}
