package main

import (
	"flag"
	"fmt"
	"time"

	_ "github.com/denisenkom/go-mssqldb"
	"github.com/jpconstantineau/sql-quality-monitor/gotests/getdatabasedetails/dbmonitor"
)

var (
	password       = flag.String("password", "", "the database password")
	port      *int = flag.Int("port", 1433, "the database port")
	server         = flag.String("server", "localhost\\SQLExpress", "the database server")
	user           = flag.String("user", "sa", "the database user")
	monitored      = flag.String("monitored", "Zen-Corrology\\SQLEXPRESS", "the monitored server")
)

func scanDaily(connString string, in <-chan dbmonitor.MonitoredDatabases, DailyTablesChannel chan dbmonitor.DailyTables, DailyTableColumnsChannel chan dbmonitor.DailyTableColumns) {
	go func() {
		for n := range in {
			dbname := n.DatabaseName
			dbmonitor.FetchDailyTables(connString, dbname, DailyTablesChannel)
			dbmonitor.FetchDailyTableColumns(connString, dbname, DailyTableColumnsChannel)
		}
	}()
}

func scanRealTime(connString string, in <-chan dbmonitor.MonitoredDatabases, RealTimeTableRowsChannel chan dbmonitor.RealTimeTableRows) {
	go func() {
		for n := range in {
			dbname := n.DatabaseName
			dbmonitor.FetchRealTimeTableRows(connString, dbname, RealTimeTableRowsChannel)
		}
	}()
}

func main() {
	flag.Parse()
	done := make(chan bool)

	// check that database server is available
	connSvrString := fmt.Sprintf("server=%s;user id=%s;password=%s;port=%d;app name=GoLangAccess", *server, *user, *password, *port)
	dbmonitor.FetchServerConnected(connSvrString)

	// check that monitored servers are available
	connMonString := fmt.Sprintf("server=%s;user id=%s;password=%s;port=%d;app name=DataMonitor", *monitored, *user, *password, *port)
	dbmonitor.FetchServerConnected(connMonString)

	// start monitoring
	ConfigServersChannel := make(chan dbmonitor.ConfigServers, 5)
	ConfigDatabasesChannel := make(chan dbmonitor.ConfigDatabases, 5)
	ConfigTablesChannel := make(chan dbmonitor.ConfigTables, 5)
	DailyDatabasesChannel := make(chan dbmonitor.DailyDatabases, 5)
	RealTimeJobsChannel := make(chan dbmonitor.RealTimeJobs, 5)
	RealTimeUsersChannel := make(chan dbmonitor.RealTimeUsers, 5)
	MonitoredDatabasesChannel := make(chan dbmonitor.MonitoredDatabases, 5)

	DailyTablesChannel := make(chan dbmonitor.DailyTables, 5)
	DailyTableColumnsChannel := make(chan dbmonitor.DailyTableColumns, 5)
	RealTimeTableRowsChannel := make(chan dbmonitor.RealTimeTableRows, 5)

	defer close(ConfigServersChannel)
	defer close(ConfigDatabasesChannel)
	defer close(ConfigTablesChannel)
	defer close(DailyDatabasesChannel)
	defer close(DailyTablesChannel)
	defer close(DailyTableColumnsChannel)
	defer close(RealTimeJobsChannel)
	defer close(RealTimeUsersChannel)
	defer close(RealTimeTableRowsChannel)
	defer close(MonitoredDatabasesChannel)

	go dbmonitor.PrintConfigServers(ConfigServersChannel, done)
	go dbmonitor.PrintConfigDatabases(ConfigDatabasesChannel, done)
	go dbmonitor.PrintConfigTables(ConfigTablesChannel, done)
	go dbmonitor.PrintDailyDatabases(DailyDatabasesChannel, done)
	go dbmonitor.PrintDailyTables(DailyTablesChannel, done)
	go dbmonitor.PrintDailyTableColumns(DailyTableColumnsChannel, done)
	go dbmonitor.PrintRealTimeJobs(RealTimeJobsChannel, done)
	go dbmonitor.PrintRealTimeUsers(RealTimeUsersChannel, done)
	go dbmonitor.PrintRealTimeTableRows(RealTimeTableRowsChannel, done)
	go dbmonitor.PrintMonitoredDatabases(MonitoredDatabasesChannel, done)

	// run once when launching - saves details around a new server
	// will run daily in case changes are done on a server
	dbmonitor.FetchConfigServers(connMonString, ConfigServersChannel)
	dbmonitor.FetchConfigDatabases(connMonString, ConfigDatabasesChannel)
	dbmonitor.FetchConfigTables(connMonString, ConfigTablesChannel)

	// get list of databases in monitored server

	dailystep := 3 // should be 60 for every hour or 1440 for daily
	tickcount := dailystep

	for {
		// run regularly
		if tickcount > dailystep-1 {
			// for each server
			dbmonitor.FetchDailyDatabases(connMonString, DailyDatabasesChannel)
			// for each database in monitored servers
			scanDaily(connMonString, dbmonitor.GetMonitoredDatabases(connSvrString, *monitored), DailyTablesChannel, DailyTableColumnsChannel)
			tickcount = 0
		}

		// run in "real time" i.e. every minute
		// for each server
		dbmonitor.FetchRealTimeUsers(connMonString, RealTimeUsersChannel)
		dbmonitor.FetchRealTimeJobs(connMonString, RealTimeJobsChannel)
		// for each database in server
		scanRealTime(connMonString, dbmonitor.GetMonitoredDatabases(connSvrString, *monitored), RealTimeTableRowsChannel)

		tickcount++
		time.Sleep(60 * time.Second)
	}
	channelcount := 10
	for i := 0; i < channelcount; i++ {
		done <- true
	}
	fmt.Printf("bye\n")
}
