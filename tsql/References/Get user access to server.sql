
-- sp_Who2

-- SELECT  spid,
--        sp.[status],
--        loginame [Login],
--        hostname, 
--        blocked BlkBy,
--        sd.name DBName, 
--        cmd Command,
--        cpu CPUTime,
--        physical_io DiskIO,
--        last_batch LastBatch,
--        [program_name] ProgramName   
--FROM master.dbo.sysprocesses sp 
--JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
--ORDER BY spid 

-- SELECT  spid,
--        sp.[status],
--        loginame [Login],
--        hostname, 
--        blocked BlkBy,
--        sd.name DBName, 
--        cmd Command,
--        cpu CPUTime,
--        physical_io DiskIO,
--        last_batch LastBatch,
--        [program_name] ProgramName   
--FROM master.dbo.sysprocesses sp 
--JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
--ORDER BY spid 



 SELECT  SERVERPROPERTY('ServerName') as ServerName, 
        sd.name DBName, 
        loginame [Login],
        hostname, 
        [program_name] ProgramName,
		max(last_batch) LastBatch into SQLDataQualityMonitor.dbo.Users
FROM master.dbo.sysprocesses sp 
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
group by loginame, hostname, sd.name, [program_name]  