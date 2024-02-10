package dbmonitor

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
)

// RealTimeUsers
type DailyTables struct {
	ServerName   string
	DatabaseName string
	Login        string
	HostName     string
	ProgramName  string
	LastBatch    string
}

func QueryDailyTables() string {
	return "SELECT  SERVERPROPERTY('ServerName') as ServerName, sd.name DBName, loginame [Login],	hostname, [program_name] ProgramName, max(last_batch) LastBatch FROM master.dbo.sysprocesses sp  JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid group by loginame, hostname, sd.name, [program_name]"
}

func TrimDailyTables(input *DailyTables) (result DailyTables) {
	result.ServerName = strings.TrimSpace(input.ServerName)
	result.DatabaseName = strings.TrimSpace(input.DatabaseName)
	result.Login = strings.TrimSpace(input.Login)
	result.HostName = strings.TrimSpace(input.HostName)
	result.ProgramName = strings.TrimSpace(input.ProgramName)
	result.LastBatch = strings.TrimSpace(input.LastBatch)
	return result
}

func PrintDailyTables(c <-chan DailyTables, done <-chan bool) {
	for {
		select {
		case data := <-c: // receiving value from channel
			fmt.Printf("DT: %s  %s  %s  %s  %s  %s\n", data.ServerName, data.DatabaseName, data.Login, data.HostName, data.ProgramName, data.LastBatch)
		case <-done:
			return
		}
	}
}

func FetchDailyTables(connString string, c chan DailyTables) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()

	// query starts here
	stmt, err := conn.Query(QueryDailyTables())
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user DailyTables
		var usertrimmed DailyTables
		err = stmt.Scan(&user.ServerName, &user.DatabaseName, &user.Login, &user.HostName, &user.ProgramName, &user.LastBatch)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		usertrimmed = TrimDailyTables(&user)
		c <- usertrimmed
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
}
