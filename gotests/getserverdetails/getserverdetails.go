package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log"
	"strings"

	_ "github.com/denisenkom/go-mssqldb"
)

type CurrentUsers struct {
	ServerName  string
	DBName      string
	Login       string
	HostName    string
	ProgramName string
	LastBatch   string
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
	//connString := fmt.Sprintf("server=%s;user id=%s;password=%s;port=%d;app name=GoLangAccess", *server, *user, *password, *port)

	if *debug {
		fmt.Printf(" connString:%s\n", connString)
	}
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()

	stmt, err := conn.Query("SELECT  SERVERPROPERTY('ServerName') as ServerName, sd.name DBName, loginame [Login],	hostname, [program_name] ProgramName, max(last_batch) LastBatch FROM master.dbo.sysprocesses sp  JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid group by loginame, hostname, sd.name, [program_name]")
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	var users []CurrentUsers

	for stmt.Next() {
		var user CurrentUsers
		var usertrimmed CurrentUsers
		err = stmt.Scan(&user.ServerName, &user.DBName, &user.Login, &user.HostName, &user.ProgramName, &user.LastBatch)
		usertrimmed.ServerName = strings.TrimSpace(user.ServerName)
		usertrimmed.DBName = strings.TrimSpace(user.DBName)
		usertrimmed.Login = strings.TrimSpace(user.Login)
		usertrimmed.HostName = strings.TrimSpace(user.HostName)
		usertrimmed.ProgramName = strings.TrimSpace(user.ProgramName)
		usertrimmed.LastBatch = strings.TrimSpace(user.LastBatch)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		// Append the person to the array
		users = append(users, usertrimmed)
	}

	// Print the results
	for _, user := range users {
		fmt.Printf("%s  %s  %s  %s  %s  %s\n", user.ServerName, user.DBName, user.Login, user.HostName, user.ProgramName, user.LastBatch)
	}

	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	fmt.Printf("bye\n")
}
