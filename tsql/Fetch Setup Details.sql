-- Get Server Name
 SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName

 -- Get List of Databases
  SELECT
	convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as DatabaseName
	FROM sys.databases; 

    