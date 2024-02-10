package dbmonitor

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
)

//--- Database Queries
//ConfigDatabases

type ConfigDatabases struct {
	ServerName   string
	DatabaseName string
}

func QueryConfigDatabases() string {
	return "SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as DatabaseName FROM sys.databases; "
}

func TrimConfigDatabases(input *ConfigDatabases) (result ConfigDatabases) {
	result.ServerName = strings.TrimSpace(input.ServerName)
	result.DatabaseName = strings.TrimSpace(input.DatabaseName)
	return result
}

func PrintConfigDatabases(c <-chan ConfigDatabases, done <-chan bool) {
	select {
	case data := <-c: // receiving value from channel
		fmt.Printf("CD:%s  %s\n", data.ServerName, data.DatabaseName)
	case <-done:
		return
	}
}

func FetchConfigDatabases(connString string, c chan ConfigDatabases) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()
	// query starts here
	stmt, err := conn.Query(QueryConfigDatabases())
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user ConfigDatabases
		var usertrimmed ConfigDatabases
		err = stmt.Scan(&user.ServerName, &user.DatabaseName)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		usertrimmed = TrimConfigDatabases(&user)
		c <- usertrimmed
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
}
