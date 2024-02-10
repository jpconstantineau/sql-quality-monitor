 -- Get Databases Details - NO VIEW
 SELECT
	convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as DatabaseName, create_date, collation_name,user_access_desc,state_desc,recovery_model_desc  
	FROM sys.databases SD; 

-- Get Server Principals (users)
	select convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as UserName, type_desc, is_disabled, create_date, modify_date, default_database_name, default_language_name 
from master.sys.server_principals; 

-- Get Active Users
-- spRecordUsers
 SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, 
        sd.name DatabaseName, 
        loginame [Login],
        hostname, 
        [program_name] ProgramName,
		max(last_batch) LastBatch 
FROM master.dbo.sysprocesses sp 
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
group by loginame, hostname, sd.name, [program_name]  

-- Get Job Results
-- spRecordJobs
 SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName,
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
  CONVERT(DATETIME,RTRIM(run_date),113)) >= DATEADD(d,-1,GetDate())

