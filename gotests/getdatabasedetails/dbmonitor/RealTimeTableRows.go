package dbmonitor

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
)

// RealTimeUsers
type RealTimeTableRows struct {
	ServerName   string
	DatabaseName string
	SchemaName   string
	TableName    string
	Rows         int32
}

func QueryRealTimeTableRows(dbname string) string {
	return `USE ` + dbname + `;
		SELECT 
			convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName,
			DB_NAME () as DatabaseName,
			s.name AS SchemaName,
			t.name AS TableName,
			p.rows
		FROM sys.tables t
		INNER JOIN sys.indexes i ON t.object_id = i.object_id
		INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
		LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
		GROUP BY  t.name, s.name, p.rows`
}

func TrimRealTimeTableRows(input *RealTimeTableRows) (result RealTimeTableRows) {
	result.ServerName = strings.TrimSpace(input.ServerName)
	result.DatabaseName = strings.TrimSpace(input.DatabaseName)
	result.SchemaName = strings.TrimSpace(input.SchemaName)
	result.TableName = strings.TrimSpace(input.TableName)
	result.Rows = input.Rows
	return result
}

func PrintRealTimeTableRows(c <-chan RealTimeTableRows, done <-chan bool) {
	for {
		select {
		case data := <-c: // receiving value from channel
			fmt.Printf("RROWS: %s.%s.%s.%s \t %d\n", data.ServerName, data.DatabaseName, data.SchemaName, data.TableName, data.Rows)
		case <-done:
			return
		}
	}
}

func FetchRealTimeTableRows(connString string, dbname string, c chan RealTimeTableRows) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()

	// query starts here
	stmt, err := conn.Query(QueryRealTimeTableRows(dbname))
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user RealTimeTableRows
		var usertrimmed RealTimeTableRows
		err = stmt.Scan(&user.ServerName, &user.DatabaseName, &user.SchemaName, &user.TableName, &user.Rows)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		usertrimmed = TrimRealTimeTableRows(&user)
		c <- usertrimmed
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
}
