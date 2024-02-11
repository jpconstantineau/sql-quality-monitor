package dbmonitor

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
)

// RealTimeUsers
type DailyTables struct {
	ServerName       string
	DatabaseName     string
	SchemaName       string
	TableName        string
	Rows             sql.NullInt32
	TotalSpaceKB     sql.NullInt32
	TotalSpaceMB     sql.NullFloat64
	UsedSpaceKB      sql.NullInt32
	UsedSpaceMB      sql.NullFloat64
	UnusedSpaceKB    sql.NullInt32
	UnusedSpaceMB    sql.NullFloat64
	last_access      sql.NullTime
	last_user_update sql.NullTime
}

func QueryDailyTables(dbname string) string {
	return `USE ` + dbname + `;
	SELECT TBD.ServerName, TBD.DatabaseName,SchemaName,TableName, rows,TotalSpaceKB,TotalSpaceMB,UsedSpaceKB,UsedSpaceMB,UnusedSpaceKB,UnusedSpaceMB, last_access,last_user_update  
	FROM (SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, 
		DB_NAME () as DatabaseName,
		s.name AS SchemaName,
		t.name AS TableName,
		p.rows,
		SUM(a.total_pages) * 8 AS TotalSpaceKB, 
		CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
		SUM(a.used_pages) * 8 AS UsedSpaceKB, 
		CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
		(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
		CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
	FROM 
		sys.tables t
	INNER JOIN      
		sys.indexes i ON t.object_id = i.object_id
	INNER JOIN 
		sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
	INNER JOIN 
		sys.allocation_units a ON p.partition_id = a.container_id
	LEFT OUTER JOIN 
		sys.schemas s ON t.schema_id = s.schema_id
	GROUP BY  t.name, s.name, p.rows ) TBD
	LEFT OUTER JOIN (
	select [schema_name], table_name, 
		   max(last_access) as last_access, 
		   max(last_user_update) as last_user_update 
	from( select schema_name(schema_id) as schema_name,
			   name as table_name,
			   (select max(last_access) 
				from (values(last_user_seek),
							(last_user_scan),
							(last_user_lookup), 
							(last_user_update)) as tmp(last_access))
					as last_access,
					last_user_update
	from sys.dm_db_index_usage_stats sta
	join sys.objects obj
		 on obj.object_id = sta.object_id
		 and obj.type = 'U'
		 and sta.database_id = DB_ID()
	) usage
	group by schema_name, table_name) TBACC ON
	TBD.SchemaName = TBACC.schema_name AND
	TBD.TableName = TBACC.table_name`
}

func TrimDailyTables(input *DailyTables) (result DailyTables) {
	result.ServerName = strings.TrimSpace(input.ServerName)
	result.DatabaseName = strings.TrimSpace(input.DatabaseName)
	result.SchemaName = strings.TrimSpace(input.SchemaName)
	result.TableName = strings.TrimSpace(input.TableName)
	result.Rows = input.Rows
	result.TotalSpaceKB = input.TotalSpaceKB
	result.TotalSpaceMB = input.TotalSpaceMB
	result.UsedSpaceKB = input.UsedSpaceKB
	result.UsedSpaceMB = input.UsedSpaceMB
	result.UnusedSpaceKB = input.UnusedSpaceKB
	result.UnusedSpaceMB = input.UnusedSpaceMB

	result.last_access = input.last_access
	result.last_user_update = input.last_user_update
	return result
}

func PrintDailyTables(c <-chan DailyTables, done <-chan bool) {
	for {
		select {
		case data := <-c: // receiving value from channel
			fmt.Printf("DT: %s.%s.%s.%s \t %d\n", data.ServerName, data.DatabaseName, data.SchemaName, data.TableName, data.Rows)
		case <-done:
			return
		}
	}
}

func FetchDailyTables(connString string, dbname string, c chan DailyTables) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()

	// query starts here
	stmt, err := conn.Query(QueryDailyTables(dbname))
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user DailyTables
		var usertrimmed DailyTables
		err = stmt.Scan(&user.ServerName, &user.DatabaseName, &user.SchemaName, &user.TableName, &user.Rows,
			&user.TotalSpaceKB,
			&user.TotalSpaceMB,
			&user.UsedSpaceKB,
			&user.UsedSpaceMB,
			&user.UnusedSpaceKB,
			&user.UnusedSpaceMB,
			&user.last_access,
			&user.last_user_update)
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
