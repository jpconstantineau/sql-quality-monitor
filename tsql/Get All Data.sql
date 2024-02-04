SELECT * FROM SQLDataQualityMonitor.Config.Servers

SELECT * FROM SQLDataQualityMonitor.Config.Databases

SELECT * FROM SQLDataQualityMonitor.Config.vDatabases

SELECT * FROM SQLDataQualityMonitor.Config.Tables

SELECT * FROM SQLDataQualityMonitor.Config.vTables

SELECT * FROM SQLDataQualityMonitor.Daily.Databases

SELECT * FROM SQLDataQualityMonitor.Daily.Tables

SELECT * FROM SQLDataQualityMonitor.Daily.ServerPrincipals

SELECT * FROM SQLDataQualityMonitor.Daily.TableColumns

SELECT * FROM SQLDataQualityMonitor.RealTime.Jobs

SELECT * FROM SQLDataQualityMonitor.RealTime.Users

SELECT * FROM SQLDataQualityMonitor.RealTime.TableRows


UPDATE SQLDataQualityMonitor.Config.Servers
SET Monitored = 1, RealTime = 1
WHERE ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) 
AND (Monitored = 0 OR RealTime = 0);

UPDATE SQLDataQualityMonitor.Config.Databases
SET Monitored = 1
WHERE ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) 
AND DatabaseName NOT IN ('master', 'model', 'msdb', 'tempdb', 'ReportServer', 'ReportServerTempDB')

UPDATE SQLDataQualityMonitor.Config.Databases
SET RealTime = 1
WHERE ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) 
AND DatabaseName  = 'SQLDataQualityMonitor'

UPDATE SQLDataQualityMonitor.Config.Tables
SET  RealTime = 1
WHERE ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) 
AND DatabaseName ='SQLDataQualityMonitor'
AND TableName = 'Tables' AND SchemaName = 'Daily'