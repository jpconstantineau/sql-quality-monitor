package dbmonitor

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
)

// RealTimeUsers
type DailyTableColumns struct {
	ServerName               string
	DatabaseName             string
	SchemaName               string
	TableName                string
	COLUMN_NAME              sql.NullString
	ORDINAL_POSITION         sql.NullInt16
	COLUMN_DEFAULT           sql.NullString
	IS_NULLABLE              sql.NullString
	DATA_TYPE                sql.NullString
	CHARACTER_MAXIMUM_LENGTH sql.NullInt16
	CHARACTER_OCTET_LENGTH   sql.NullInt16
	NUMERIC_PRECISION        sql.NullInt16
	NUMERIC_PRECISION_RADIX  sql.NullInt16
	NUMERIC_SCALE            sql.NullInt16
	DATETIME_PRECISION       sql.NullInt16
	CHARACTER_SET_CATALOG    sql.NullString
	CHARACTER_SET_SCHEMA     sql.NullString
	CHARACTER_SET_NAME       sql.NullString
	COLLATION_CATALOG        sql.NullString
	COLLATION_SCHEMA         sql.NullString
	COLLATION_NAME           sql.NullString
	DOMAIN_CATALOG           sql.NullString
	DOMAIN_SCHEMA            sql.NullString
	DOMAIN_NAME              sql.NullString
}

func QueryDailyTableColumns(dbname string) string {
	return `USE ` + dbname + `;
	select	DISTINCT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName,
	TABLE_CATALOG as DatabaseName,
	TABLE_SCHEMA as SchemaName,
	TABLE_NAME as TableName,
	COLUMN_NAME,
	ORDINAL_POSITION,
	COLUMN_DEFAULT,
	IS_NULLABLE,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	CHARACTER_OCTET_LENGTH,
	NUMERIC_PRECISION,
	NUMERIC_PRECISION_RADIX,
	NUMERIC_SCALE,
	DATETIME_PRECISION,
	CHARACTER_SET_CATALOG,
	CHARACTER_SET_SCHEMA,
	CHARACTER_SET_NAME,
	COLLATION_CATALOG,
	COLLATION_SCHEMA,
	COLLATION_NAME,
	DOMAIN_CATALOG,
	DOMAIN_SCHEMA,
	DOMAIN_NAME
	from INFORMATION_SCHEMA.COLUMNS SC
	`
}

func TrimDailyTableColumns(input *DailyTableColumns) (result DailyTableColumns) {
	result = *input
	result.ServerName = strings.TrimSpace(input.ServerName)
	result.DatabaseName = strings.TrimSpace(input.DatabaseName)
	result.SchemaName = strings.TrimSpace(input.SchemaName)
	result.TableName = strings.TrimSpace(input.TableName)
	return result
}

func PrintDailyTableColumns(c <-chan DailyTableColumns, done <-chan bool) {
	for {
		select {
		case data := <-c: // receiving value from channel
			fmt.Printf("DC: %s.%s.%s.%s.%s\n", data.ServerName, data.DatabaseName, data.SchemaName, data.TableName, data.COLUMN_NAME.String)
		case <-done:
			return
		}
	}
}

func FetchDailyTableColumns(connString string, dbname string, c chan DailyTableColumns) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()

	// query starts here
	stmt, err := conn.Query(QueryDailyTableColumns(dbname))
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user DailyTableColumns
		var usertrimmed DailyTableColumns
		err = stmt.Scan(&user.ServerName, &user.DatabaseName,
			&user.SchemaName,
			&user.TableName,
			&user.COLUMN_NAME,
			&user.ORDINAL_POSITION,
			&user.COLUMN_DEFAULT,
			&user.IS_NULLABLE,
			&user.DATA_TYPE,
			&user.CHARACTER_MAXIMUM_LENGTH,
			&user.CHARACTER_OCTET_LENGTH,
			&user.NUMERIC_PRECISION,
			&user.NUMERIC_PRECISION_RADIX,
			&user.NUMERIC_SCALE,
			&user.DATETIME_PRECISION,
			&user.CHARACTER_SET_CATALOG,
			&user.CHARACTER_SET_SCHEMA,
			&user.CHARACTER_SET_NAME,
			&user.COLLATION_CATALOG,
			&user.COLLATION_SCHEMA,
			&user.COLLATION_NAME,
			&user.DOMAIN_CATALOG,
			&user.DOMAIN_SCHEMA,
			&user.DOMAIN_NAME)

		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		usertrimmed = TrimDailyTableColumns(&user)
		c <- usertrimmed
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
}
