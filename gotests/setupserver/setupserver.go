package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log"
	"strings"

	_ "github.com/denisenkom/go-mssqldb"
)

/*
type CurrentUsers struct {
	ServerName  string
	DatabaseName      string
	Login       string
	HostName    string
	ProgramName string
	LastBatch   string
}
*/

type Databases struct {
	ServerName   string
	DatabaseName string
}

var (
	debug         = flag.Bool("debug", false, "enable debugging")
	password      = flag.String("password", "", "the database password")
	port     *int = flag.Int("port", 1433, "the database port")
	server        = flag.String("server", "localhost\\SQLExpress", "the database server")
	user          = flag.String("user", "sa", "the database user")
)

func main() {
	flag.Parse()

	if *debug {
		fmt.Printf(" password:%s\n", *password)
		fmt.Printf(" port:%d\n", *port)
		fmt.Printf(" server:%s\n", *server)
		fmt.Printf(" user:%s\n", *user)
	}

	connString := fmt.Sprintf("server=%s;user id=%s;password=%s;port=%d;app name=GoLangAccess", *server, *user, *password, *port)

	if *debug {
		fmt.Printf(" connString:%s\n", connString)
	}
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()

	stmt, err := conn.Query("SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as DatabaseName FROM sys.databases;")
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	var DBs []Databases

	for stmt.Next() {
		var db Databases
		var dbtrimmed Databases
		err = stmt.Scan(&db.ServerName, &db.DatabaseName)
		dbtrimmed.ServerName = strings.TrimSpace(db.ServerName)
		dbtrimmed.DatabaseName = strings.TrimSpace(db.DatabaseName)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		// Append the person to the array
		DBs = append(DBs, dbtrimmed)
	}

	// Print the results
	for _, row := range DBs {
		fmt.Printf("%s  %s\n", row.ServerName, row.DatabaseName)
	}

	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	fmt.Printf("bye\n")
}
