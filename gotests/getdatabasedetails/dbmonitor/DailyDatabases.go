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

type DailyDatabases struct {
	ServerName          string
	DatabaseName        string
	create_date         string
	collation_name      sql.NullString
	user_access_desc    string
	state_desc          string
	recovery_model_desc string
}

func QueryDailyDatabases() string {
	return `
	SELECT
	convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as DatabaseName, create_date, collation_name,user_access_desc,state_desc,recovery_model_desc  
	FROM sys.databases SD; `
}

func TrimDailyDatabases(input *DailyDatabases) (result DailyDatabases) {
	result.ServerName = strings.TrimSpace(input.ServerName)
	result.DatabaseName = strings.TrimSpace(input.DatabaseName)
	result.create_date = strings.TrimSpace(input.create_date)
	result.collation_name = input.collation_name //strings.TrimSpace(input.collation_name)
	result.user_access_desc = strings.TrimSpace(input.user_access_desc)
	result.state_desc = strings.TrimSpace(input.state_desc)
	result.recovery_model_desc = strings.TrimSpace(input.recovery_model_desc)
	return result
}

func PrintDailyDatabases(c <-chan DailyDatabases, done <-chan bool) {
	for {
		select {
		case data := <-c: // receiving value from channel
			fmt.Printf("DD: %s  %s\n", data.ServerName, data.DatabaseName)
		case <-done:
			return
		}
	}
}

func FetchDailyDatabases(connString string, c chan DailyDatabases) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()
	// query starts here
	stmt, err := conn.Query(QueryDailyDatabases())
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user DailyDatabases
		var usertrimmed DailyDatabases
		err = stmt.Scan(&user.ServerName, &user.DatabaseName, &user.create_date, &user.collation_name, &user.user_access_desc, &user.state_desc, &user.recovery_model_desc)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		usertrimmed = TrimDailyDatabases(&user)
		c <- usertrimmed
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
}
