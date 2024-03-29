package monitoreddatabase

import (
	"database/sql"
	"fmt"
	"jpconstantineau/sqlqmon/configdatabase"
	"jpconstantineau/sqlqmon/forms"
	"log"
	"strconv"

	_ "github.com/denisenkom/go-mssqldb"
)

func GetConnString(data configdatabase.Server) string {
	port, err := strconv.Atoi(data.Port)
	if err != nil {
		log.Fatal("AtoI Failed for port:", err.Error())
	}

	return fmt.Sprintf("server=%s;user id=%s;password=%s;port=%d;app name=SQLQMon", data.Server, data.User, data.Password, port)
}

func GetConnStringForm(data forms.ServerInputForm) string {
	port, err := strconv.Atoi(data.Port)
	if err != nil {
		log.Fatal("AtoI Failed for port:", err.Error())
	}

	return fmt.Sprintf("server=%s;user id=%s;password=%s;port=%d;app name=SQLQMon", data.HostName, data.UserName, data.Password, port)
}

func GetServerName(data forms.ServerInputForm) forms.ServerInputForm {

	conn, err := sql.Open("mssql", GetConnStringForm(data))
	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()

	stmt, err := conn.Query("SELECT  SERVERPROPERTY('ServerName') as ServerName;")
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	var name string
	for stmt.Next() {
		err = stmt.Scan(&name)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
	}
	data.ServerName = name
	return data
}
