--SELECT
--    D.name,
--    F.Name AS FileType,
--    F.physical_name AS PhysicalFile,
--    F.state_desc AS OnlineStatus,
--    CAST((F.size*8)/1024 AS VARCHAR(26)) + ' MB' AS FileSize,
--    CAST(F.size*8 AS VARCHAR(32)) + ' Bytes' as SizeInBytes
--FROM 
--    sys.master_files F
--    INNER JOIN sys.databases D ON D.database_id = F.database_id
--ORDER BY
--    D.name

--	select *
--from sys.sysdatabases

--SELECT
--    name,
--    size,
--    size * 8/1024 'Size (MB)',
--    max_size,
--*
--FROM sys.master_files;

INSERT into SQLDataQualityMonitor.dbo.Servers (ServerName, Monitored)
SELECT
convert(varchar(255),SERVERPROPERTY('ServerName')) as ServerName, 1 as Monitored 

INSERT into SQLDataQualityMonitor.dbo.Databases (ServerName, name,create_date,collation_name,user_access_desc,state_desc,recovery_model_desc)
SELECT
convert(varchar(255),SERVERPROPERTY('ServerName')) as ServerName, name, create_date,collation_name,user_access_desc,state_desc,recovery_model_desc  
FROM sys.databases; 




--MERGE INTO SQLDataQualityMonitor.dbo.Databases
--USING (SELECT
--convert(varchar(255),SERVERPROPERTY('ServerName')) as ServerName, name, create_date,collation_name,user_access_desc,state_desc,recovery_model_desc  
--FROM sys.databases) AS source 
--ON Databases.ServerName = source.ServerName
--AND Databases.name = source.name
--WHEN MATCHED AND (
--Databases.create_date <> source.create_date
--OR Databases.collation_name <> source.collation_name
--OR Databases.user_access_desc <> source.user_access_desc
--OR Databases.state_desc <> source.state_desc
--OR Databases.recovery_model_desc <> source.recovery_model_desc) THEN
	
-- UPDATE SET 
--	create_date = source.create_date,
--	collation_name = source.collation_name,
--	user_access_desc = source.user_access_desc,
--	state_desc = source.state_desc,
--	recovery_model_desc = source.recovery_model_desc

--WHEN NOT MATCHED THEN
 
-- INSERT (ServerName, name,create_date,collation_name,user_access_desc,state_desc,recovery_model_desc)
-- VALUES (source.ServerName, source.name,source.create_date,source.collation_name,source.user_access_desc,source.state_desc,source.recovery_model_desc)
 
-- WHEN NOT MATCHED BY SOURCE THEN
-- DELETE;