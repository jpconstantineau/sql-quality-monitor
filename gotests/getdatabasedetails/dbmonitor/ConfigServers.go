package dbmonitor

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
)

//--- Database Queries
//ConfigDatabases
//ConfigServers
//DailyDatabases
//RealTimeJobs

type ConfigServers struct {
	ServerName string
}

func QueryConfigServers() string {
	return "SELECT SERVERPROPERTY('ServerName') as ServerName"
}

func TrimConfigServers(input *ConfigServers) (result ConfigServers) {
	result.ServerName = strings.TrimSpace(input.ServerName)
	return result
}

func PrintConfigServers(c <-chan ConfigServers, done <-chan bool) {
	for {
		select {
		case data := <-c: // receiving value from channel
			fmt.Printf("CS: %s \n", data.ServerName)
		case <-done:
			fmt.Printf("CS: DONE RECEIVED \n")
			return
		}
	}
}
func FetchConfigServers(connString string, c chan ConfigServers) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()
	// query starts here
	stmt, err := conn.Query(QueryConfigServers())
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user ConfigServers
		var usertrimmed ConfigServers
		err = stmt.Scan(&user.ServerName)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		usertrimmed = TrimConfigServers(&user)
		c <- usertrimmed
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
}
