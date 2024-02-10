package dbmonitor

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
)

// RealTimeUsers
type ConfigTables struct {
	ServerName   string
	DatabaseName string
	SchemaName   string
	TableName    string
}

func QueryConfigTables() string {
	return `SELECT 
	convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, 
	DB_NAME () as DatabaseName,
		s.name AS SchemaName,
		t.name AS TableName
	FROM 
		sys.tables t
	LEFT OUTER JOIN 
		sys.schemas s ON t.schema_id = s.schema_id `
}

func TrimConfigTables(input *ConfigTables) (result ConfigTables) {
	result.ServerName = strings.TrimSpace(input.ServerName)
	result.DatabaseName = strings.TrimSpace(input.DatabaseName)
	result.SchemaName = strings.TrimSpace(input.SchemaName)
	result.TableName = strings.TrimSpace(input.TableName)
	return result
}

func PrintConfigTables(c <-chan ConfigTables, done <-chan bool) {
	for {
		select {
		case data := <-c: // receiving value from channel
			fmt.Printf("CT: %s  %s  %s  %s \n", data.ServerName, data.DatabaseName, data.SchemaName, data.TableName)
		case <-done:
			return
		}
	}
}

func FetchConfigTables(connString string, c chan ConfigTables) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()

	// query starts here
	stmt, err := conn.Query(QueryConfigTables())
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user ConfigTables
		var usertrimmed ConfigTables
		err = stmt.Scan(&user.ServerName, &user.DatabaseName, &user.SchemaName, &user.TableName)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		usertrimmed = TrimConfigTables(&user)
		c <- usertrimmed
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
}
