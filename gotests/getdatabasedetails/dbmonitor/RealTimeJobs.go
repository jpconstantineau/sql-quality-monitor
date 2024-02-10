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

type RealTimeJobs struct {
	ServerName string
	JobName    string
	TimeRun    string
	JobStatus  string
	enabled    string
	JobOutcome string
	run_status string
}

func QueryRealTimeJobs() string {
	return `SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName,
	name AS [JobName]
			 ,CONVERT(VARCHAR,DATEADD(S,(run_time/10000)*60*60 /* hours */ 
			  +((run_time - (run_time/10000) * 10000)/100) * 60 /* mins */ 
			  + (run_time - (run_time/100) * 100)  /* secs */
			   ,CONVERT(DATETIME,RTRIM(run_date),113)),100) AS [TimeRun]
			 ,CASE WHEN enabled=1 THEN 'Enabled' 
				   ELSE 'Disabled' 
			  END [JobStatus]
			  , enabled
			 ,CASE WHEN SJH.run_status=0 THEN 'Failed'
						 WHEN SJH.run_status=1 THEN 'Succeeded'
						 WHEN SJH.run_status=2 THEN 'Retry'
						 WHEN SJH.run_status=3 THEN 'Cancelled'
				   ELSE 'Unknown' 
			  END [JobOutcome]
			  , run_status
	FROM   msdb.dbo.sysjobhistory SJH 
	JOIN   msdb.dbo.sysjobs SJ 
	ON     SJH.job_id=sj.job_id 
	WHERE  step_id=0 
	AND    DATEADD(S, 
	  (run_time/10000)*60*60 /* hours */ 
	  +((run_time - (run_time/10000) * 10000)/100) * 60 /* mins */ 
	  + (run_time - (run_time/100) * 100)  /* secs */, 
	  CONVERT(DATETIME,RTRIM(run_date),113)) >= DATEADD(d,-1,GetDate())`
}

func TrimRealTimeJobs(input *RealTimeJobs) (result RealTimeJobs) {
	result.ServerName = strings.TrimSpace(input.ServerName)
	result.JobName = strings.TrimSpace(input.JobName)
	result.TimeRun = strings.TrimSpace(input.TimeRun)
	result.JobStatus = strings.TrimSpace(input.JobStatus)
	result.enabled = strings.TrimSpace(input.enabled)
	result.JobOutcome = strings.TrimSpace(input.JobOutcome)
	result.run_status = strings.TrimSpace(input.run_status)
	return result
}

func PrintRealTimeJobs(c <-chan RealTimeJobs, done <-chan bool) {
	for {
		select {
		case data := <-c: // receiving value from channel
			fmt.Printf("RJ: %s  %s\n", data.ServerName, data.JobName)
		case <-done:
			return
		}
	}
}

func FetchRealTimeJobs(connString string, c chan RealTimeJobs) {
	conn, err := sql.Open("mssql", connString)

	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer conn.Close()
	// query starts here
	stmt, err := conn.Query(QueryRealTimeJobs())
	if err != nil {
		log.Fatal("Prepare failed:", err.Error())
	}
	defer stmt.Close()

	for stmt.Next() {
		var user RealTimeJobs
		var usertrimmed RealTimeJobs
		err = stmt.Scan(&user.ServerName, &user.JobName, &user.TimeRun, &user.JobStatus, &user.enabled, &user.JobOutcome, &user.run_status)
		if err != nil {
			log.Fatal("Scan failed:", err.Error())
		}
		usertrimmed = TrimRealTimeJobs(&user)
		c <- usertrimmed
	}
	// Check for errors from iterating over rows
	if err := stmt.Err(); err != nil {
		panic(err.Error())
	}
	// query ends here
}
