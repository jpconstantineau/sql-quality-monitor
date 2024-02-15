package forms

import "fmt"

type DatabaseInputForm struct {
	ServerId     int
	DatabaseName string
	Monitored    bool
	Daily        bool
	RealTime     bool
}

func EditDatabaseMonitoredStatus(databaselist []DatabaseInputForm) []DatabaseInputForm {
	// figure out a dynamic multi select...
	fmt.Println("TODO figure out a dynamic multi select...")
	return databaselist
}

func EditDatabaseDailyStatus(databaselist []DatabaseInputForm) []DatabaseInputForm {
	// figure out a dynamic multi select...
	fmt.Println("TODO figure out a dynamic multi select...")
	return databaselist
}

func EditDatabaseRealTimeStatus(databaselist []DatabaseInputForm) []DatabaseInputForm {
	// figure out a dynamic multi select...
	fmt.Println("TODO figure out a dynamic multi select...")
	return databaselist
}
