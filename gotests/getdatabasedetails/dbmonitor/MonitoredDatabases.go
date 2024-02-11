package dbmonitor

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
)

type MonitoredDatabases struct {
	ServerName   string
	DatabaseName string
	Monitored    bool
	Daily        bool
	RealTime     bool
}

func QueryMonitoredDatabases(ServerName string) string {
	return `
	SELECT [ServerName],[DatabaseName], Monitored, Daily, RealTime
	FROM [SQLDataQualityMonitor].[Config].[Databases]
	WHERE [Monitored] = 1 AND [ServerName] = '` + ServerName + `'`
}

func TrimMonitoredDatabases(input *MonitoredDatabases) (result MonitoredDatabases) {
	result.ServerName = strings.TrimSpace(input.ServerName)
	result.DatabaseName = strings.TrimSpace(input.DatabaseName)
	result.Monitored = input.Monitored
	result.Daily = input.Daily
	result.RealTime = input.RealTime
	return result
}

func PrintMonitoredDatabases(c <-chan MonitoredDatabases, done <-chan bool) {
	for {
		select {
		case data := <-c: // receiving value from channel
			fmt.Printf("MD: %s  %s\n", data.ServerName, data.DatabaseName)
		case <-done:
			return
		}
	}
}

func FetchMonitoredDatabases(connString string, ServerName string, c chan MonitoredDatabases) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()
	// query starts here
	stmt, err := conn.Query(QueryMonitoredDatabases(ServerName))
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user MonitoredDatabases
		var usertrimmed MonitoredDatabases
		err = stmt.Scan(&user.ServerName, &user.DatabaseName, &user.Monitored, &user.Daily, &user.RealTime)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		usertrimmed = TrimMonitoredDatabases(&user)
		c <- usertrimmed
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
}

func GetMonitoredDatabases(connString string, ServerName string) <-chan MonitoredDatabases {
	out := make(chan MonitoredDatabases)
	go func() {
		FetchMonitoredDatabases(connString, ServerName, out)
		close(out)
	}()
	return out
}
