package main

import (
	"flag"
	"fmt"

	_ "github.com/denisenkom/go-mssqldb"
	"github.com/jpconstantineau/sql-quality-monitor/gotests/getdatabasedetails/dbmonitor"
)

var (
	password      = flag.String("password", "", "the database password")
	port     *int = flag.Int("port", 1433, "the database port")
	server        = flag.String("server", "localhost\\SQLExpress", "the database server")
	user          = flag.String("user", "sa", "the database user")
)

func main() {
	flag.Parse()
	done := make(chan bool)
	ConfigServersChannel := make(chan dbmonitor.ConfigServers, 5)
	ConfigDatabasesChannel := make(chan dbmonitor.ConfigDatabases, 5)
	ConfigTablesChannel := make(chan dbmonitor.ConfigTables, 5)
	DailyDatabasesChannel := make(chan dbmonitor.DailyDatabases, 5)
	DailyTablesChannel := make(chan dbmonitor.DailyTables, 5)
	DailyTableColumnsChannel := make(chan dbmonitor.DailyTableColumns, 5)
	RealTimeJobsChannel := make(chan dbmonitor.RealTimeJobs, 5)
	RealTimeUsersChannel := make(chan dbmonitor.RealTimeUsers, 5)
	RealTimeTableRowsChannel := make(chan dbmonitor.RealTimeTableRows, 5)

	connString := fmt.Sprintf("server=%s;user id=%s;password=%s;port=%d;app name=GoLangAccess", *server, *user, *password, *port)

	defer close(ConfigServersChannel)
	defer close(ConfigDatabasesChannel)
	defer close(ConfigTablesChannel)
	defer close(DailyDatabasesChannel)
	defer close(DailyTablesChannel)
	defer close(DailyTableColumnsChannel)
	defer close(RealTimeJobsChannel)
	defer close(RealTimeUsersChannel)
	defer close(RealTimeTableRowsChannel)

	go dbmonitor.PrintConfigServers(ConfigServersChannel, done)
	go dbmonitor.PrintConfigDatabases(ConfigDatabasesChannel, done)
	go dbmonitor.PrintConfigTables(ConfigTablesChannel, done)
	go dbmonitor.PrintDailyDatabases(DailyDatabasesChannel, done)
	go dbmonitor.PrintDailyTables(DailyTablesChannel, done)
	go dbmonitor.PrintDailyTableColumns(DailyTableColumnsChannel, done)
	go dbmonitor.PrintRealTimeJobs(RealTimeJobsChannel, done)
	go dbmonitor.PrintRealTimeUsers(RealTimeUsersChannel, done)
	go dbmonitor.PrintRealTimeTableRows(RealTimeTableRowsChannel, done)

	dbmonitor.FetchConfigServers(connString, ConfigServersChannel)
	dbmonitor.FetchConfigDatabases(connString, ConfigDatabasesChannel)
	dbmonitor.FetchConfigTables(connString, ConfigTablesChannel)
	dbmonitor.FetchDailyDatabases(connString, DailyDatabasesChannel)
	dbmonitor.FetchRealTimeUsers(connString, RealTimeUsersChannel)
	dbmonitor.FetchDailyTables(connString, DailyTablesChannel)
	dbmonitor.FetchDailyTableColumns(connString, DailyTableColumnsChannel)
	dbmonitor.FetchRealTimeTableRows(connString, RealTimeTableRowsChannel)
	dbmonitor.FetchRealTimeJobs(connString, RealTimeJobsChannel)

	done <- true
	done <- true
	done <- true
	done <- true
	done <- true
	done <- true
	done <- true
	done <- true
	done <- true
	fmt.Printf("bye\n")
}
