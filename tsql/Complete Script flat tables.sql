-- ================================================
-- 
-- ================================================

USE master;
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- DELETE OLD DATABASE BEFORE RE-CREATING
IF DB_ID (N'SQLDataQualityMonitor') IS NOT NULL
BEGIN
  alter database [SQLDataQualityMonitor] set single_user with rollback immediate
  DROP DATABASE SQLDataQualityMonitor;
END
GO

-- ================================================
CREATE DATABASE SQLDataQualityMonitor;
GO

-- ================================================
-- Verify the database files and sizes
SELECT name, size, size*1.0/128 AS [Size in MBs]
FROM sys.master_files
WHERE name = N'SQLDataQualityMonitor';
GO

-- ================================================
USE [SQLDataQualityMonitor]
GO

-- ================================================
CREATE SCHEMA Config;
GO
CREATE SCHEMA Daily;
GO
CREATE SCHEMA RealTime;
GO

-- ================================================
CREATE TABLE [Config].[Servers](
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[Monitored] [bit] NOT NULL,
	[Daily] [bit] NOT NULL,
	[RealTime] [bit] NOT NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_Servers_ServerName PRIMARY KEY (ID),
) 
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));
GO

ALTER TABLE [Config].[Servers] ADD  CONSTRAINT [DF_Servers_Monitored]  DEFAULT ((0)) FOR [Monitored]
ALTER TABLE [Config].[Servers] ADD  CONSTRAINT [DF_Servers_Daily]  DEFAULT ((1)) FOR [Daily]
ALTER TABLE [Config].[Servers] ADD  CONSTRAINT [DF_Servers_RealTime]  DEFAULT ((0)) FOR [RealTime]

GO

-- ================================================
CREATE TABLE [Config].[Databases]
(
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[Monitored] [bit] NOT NULL,
	[Daily] [bit] NOT NULL,
	[RealTime] [bit] NOT NULL,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),    
	CONSTRAINT UC_Databases UNIQUE (ServerName,DatabaseName),
	CONSTRAINT PK_Databases PRIMARY KEY (ID )
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO
ALTER TABLE [Config].[Databases] ADD  CONSTRAINT [DF_Databases_Monitored]  DEFAULT ((0)) FOR [Monitored]
ALTER TABLE [Config].[Databases] ADD  CONSTRAINT [DF_Databases_Daily]  DEFAULT ((1)) FOR [Daily]
ALTER TABLE [Config].[Databases] ADD  CONSTRAINT [DF_Databases_RealTime]  DEFAULT ((0)) FOR [RealTime]

-- ================================================
CREATE TABLE [Daily].[Databases]
(
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[create_date] [datetime] NOT NULL,
	[collation_name] [nvarchar](128) NULL,
	[user_access_desc] [nvarchar](60) NULL,
	[state_desc] [nvarchar](60) NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),    
	CONSTRAINT UC_Databases UNIQUE (ServerName,DatabaseName),
	CONSTRAINT PK_Databases PRIMARY KEY (ID )
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

-- ================================================
CREATE TABLE [Config].[Tables](
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[Daily] [bit] NOT NULL,
	[RealTime] [bit] NOT NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_Tables PRIMARY KEY (ID),
	CONSTRAINT UC_Tables UNIQUE (ServerName,DatabaseName,SchemaName,TableName),
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

ALTER TABLE [Config].[Tables] ADD  CONSTRAINT [DF_Tables_Daily]  DEFAULT ((0)) FOR [Daily]
ALTER TABLE [Config].[Tables] ADD  CONSTRAINT [DF_Tables_RealTime]  DEFAULT ((0)) FOR [RealTime]

GO

-- ================================================

CREATE VIEW [Config].[vDatabases]
AS
SELECT        D.ServerName, D.DatabaseName, D.Monitored, S.RealTime & D.RealTime AS Realtime
FROM            Config.Servers AS S INNER JOIN
                         Config.Databases AS D ON S.ServerName = D.ServerName
WHERE        (S.Monitored = 1) AND (D.Monitored = 1)
GO


-- ================================================

CREATE VIEW [Config].[vTables]
AS
SELECT        D.ServerName, D.DatabaseName,T.SchemaName,T.TableName, D.Monitored, (S.RealTime & D.RealTime & T.RealTime)AS Realtime
FROM            Config.Servers AS S INNER JOIN
                Config.Databases AS D ON S.ServerName = D.ServerName INNER JOIN
				Config.Tables AS T ON D.ServerName = T.ServerName AND D.DatabaseName = T.DatabaseName  
WHERE        (S.Monitored = 1) AND (D.Monitored = 1)
GO

-- ================================================
-- DAILY MONITORING TABLES
-- ================================================
CREATE TABLE [Daily].[Tables](
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[rows] [bigint] NULL,
	[TotalSpaceKB] [bigint] NULL,
	[TotalSpaceMB] [numeric](36, 2) NULL,
	[UsedSpaceKB] [bigint] NULL,
	[UsedSpaceMB] [numeric](36, 2) NULL,
	[UnusedSpaceKB] [bigint] NULL,
	[UnusedSpaceMB] [numeric](36, 2) NULL,
	[last_access] [datetime] NULL,
	[last_user_update] [datetime] NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_TableData PRIMARY KEY (ID),
	CONSTRAINT UC_TableData UNIQUE (ServerName,DatabaseName,SchemaName,TableName),
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

-- ================================================
CREATE TABLE [Daily].[TableColumns](
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[COLUMN_NAME] [nvarchar](128) NULL,
	[ORDINAL_POSITION] [int] NULL,
	[COLUMN_DEFAULT] [nvarchar](4000) NULL,
	[IS_NULLABLE] [varchar](3) NULL,
	[DATA_TYPE] [nvarchar](128) NULL,
	[CHARACTER_MAXIMUM_LENGTH] [int] NULL,
	[CHARACTER_OCTET_LENGTH] [int] NULL,
	[NUMERIC_PRECISION] [tinyint] NULL,
	[NUMERIC_PRECISION_RADIX] [smallint] NULL,
	[NUMERIC_SCALE] [int] NULL,
	[DATETIME_PRECISION] [smallint] NULL,
	[CHARACTER_SET_CATALOG] [nvarchar](128) NULL,
	[CHARACTER_SET_SCHEMA] [nvarchar](128) NULL,
	[CHARACTER_SET_NAME] [nvarchar](128) NULL,
	[COLLATION_CATALOG] [nvarchar](128) NULL,
	[COLLATION_SCHEMA] [nvarchar](128) NULL,
	[COLLATION_NAME] [nvarchar](128) NULL,
	[DOMAIN_CATALOG] [nvarchar](128) NULL,
	[DOMAIN_SCHEMA] [nvarchar](128) NULL,
	[DOMAIN_NAME] [nvarchar](128) NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_TableColumns PRIMARY KEY (ID),
	CONSTRAINT UC_TableColumns UNIQUE (ServerName,DatabaseName,SchemaName,TableName,COLUMN_NAME),
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

-- ================================================
CREATE TABLE [Daily].[ServerPrincipals](
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[UserName] [nvarchar](128) NOT NULL,
	[type_desc] [nvarchar](60) NULL,
	is_disabled bit NULL,
	create_date [datetime] NOT NULL,
	modify_date [datetime] NOT NULL,
	default_database_name [nvarchar](128) NULL,
	default_language_name [nvarchar](128) NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_UsersinServer PRIMARY KEY (ID),
	CONSTRAINT UC_UsersinServer UNIQUE (ServerName,UserName),
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

-- ================================================
-- REALTIME MONITORING TABLES
-- ================================================
CREATE TABLE [RealTime].[TableRows](
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[rows] [bigint] NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_TableRows PRIMARY KEY (ID),
	CONSTRAINT UC_TableRows UNIQUE (ServerName,DatabaseName,SchemaName,TableName),
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

-- ================================================
CREATE TABLE [RealTime].[Users](
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[Login] [nchar](128) NOT NULL,
	[hostname] [nchar](128) NOT NULL,
	[ProgramName] [nchar](128) NULL,
	[LastBatch] [datetime] NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_Users PRIMARY KEY (ID),
	CONSTRAINT UC_Users UNIQUE (ServerName,DatabaseName,[Login],hostname,ProgramName),
) 
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO
-- ================================================
CREATE TABLE [RealTime].[Jobs](
	ID int IDENTITY,
	[ServerName] [nvarchar](128) NOT NULL,
	[JobName] [nvarchar](128) NOT NULL,
	[TimeRun] [varchar](30) NULL,
	[JobStatus] [varchar](8) NOT NULL,
	[enabled] [tinyint] NOT NULL,
	[JobOutcome] [varchar](9) NOT NULL,
	[run_status] [int] NOT NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_JobStatus PRIMARY KEY (ID),
	CONSTRAINT UC_JobStatus UNIQUE (ServerName,JobName),
) WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

-- ================================================
-- STORED PROCEDURES - Config
-- ================================================
CREATE PROCEDURE spSetupServer
AS
BEGIN
    SET NOCOUNT ON

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL
	)

    -- Insert statements for procedure here
 INSERT INTO @results (ServerName)
 SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName

MERGE Config.Servers AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
    
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName) 
    VALUES (S.ServerName);
END
GO

-- ================================================
CREATE PROCEDURE spSetupDatabases
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL
	)

    -- Insert statements for procedure here


 INSERT INTO @results (ServerName, DatabaseName)
 SELECT
	convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as DatabaseName
	FROM sys.databases; 

 

-- SELECT * FROM @results

MERGE Config.Databases AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.DatabaseName = T.DatabaseName
    
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName, DatabaseName) 
    VALUES (S.ServerName, S.DatabaseName);

END
GO

-- ================================================
CREATE PROCEDURE spSetupTables @dbname nvarchar(30)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @sql as nvarchar(1024)

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL
	)

    -- Insert statements for procedure here
 
 select @sql = ' USE ['+@dbname+']
 SELECT 
convert(varchar(128),SERVERPROPERTY(''ServerName'')) as ServerName, 
DB_NAME () as DBName,
    s.name AS SchemaName,
    t.name AS TableName
FROM 
    sys.tables t
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
'
INSERT INTO @results 
EXEC (@sql)

-- SELECT * FROM @results

MERGE Config.Tables AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.DatabaseName = T.DatabaseName
AND S.SchemaName = T.SchemaName 
AND S.TableName = T.TableName 

    
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName, DatabaseName, SchemaName, TableName) 
    VALUES (S.ServerName, S.DatabaseName, S.SchemaName, S.TableName)
    ;
END
GO

-- ================================================
-- STORED PROCEDURES - Daily
-- ================================================
CREATE PROCEDURE spRecordDatabases
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[create_date] [datetime] NOT NULL,
	[collation_name] [nvarchar](128) NULL,
	[user_access_desc] [nvarchar](60) NULL,
	[state_desc] [nvarchar](60) NULL,
	[recovery_model_desc] [nvarchar](60) NULL
	)

    -- Insert statements for procedure here


 INSERT INTO @results (ServerName, DatabaseName, create_date,collation_name,user_access_desc,state_desc,recovery_model_desc)
 SELECT
	convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as DatabaseName, create_date, collation_name,user_access_desc,state_desc,recovery_model_desc  
	FROM sys.databases SD
	INNER JOIN SQLDataQualityMonitor.Config.vDatabases VD
	ON SD.name = VD.DatabaseName
	WHERE VD.ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) AND VD.Monitored = 1
	; 

-- SELECT * FROM @results

MERGE Daily.Databases AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.DatabaseName = T.DatabaseName
    
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName, DatabaseName, create_date,collation_name,user_access_desc,state_desc,recovery_model_desc) 
    VALUES (S.ServerName, S.DatabaseName, S.create_date,S.collation_name,S.user_access_desc,S.state_desc,S.recovery_model_desc)
WHEN MATCHED 
    AND EXISTS (
        SELECT S.ServerName, S.DatabaseName, S.create_date,S.collation_name,S.user_access_desc,S.state_desc,S.recovery_model_desc
        EXCEPT
        SELECT T.ServerName, T.DatabaseName, T.create_date,T.collation_name,T.user_access_desc,T.state_desc,T.recovery_model_desc
        )
THEN UPDATE SET
    T.create_date = S.create_date,
	T.collation_name = S.collation_name, 
	T.user_access_desc= S.user_access_desc,
	T.state_desc = S.state_desc,
	T.recovery_model_desc = S.recovery_model_desc
    ;
END
GO

-- ================================================
CREATE PROCEDURE spRecordServerPrincipals
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[UserName] [nvarchar](128) NOT NULL,
	[type_desc] [nvarchar](60) NULL,
	is_disabled bit NULL,
	create_date [datetime] NOT NULL,
	modify_date [datetime] NOT NULL,
	default_database_name [nvarchar](128) NULL,
	default_language_name [nvarchar](128) NULL
	)

    -- Insert statements for procedure here


 INSERT INTO @results (ServerName, UserName, type_desc, is_disabled, create_date, modify_date, default_database_name, default_language_name)
select convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as UserName, type_desc, is_disabled, create_date, modify_date, default_database_name, default_language_name 
from master.sys.server_principals; 

-- SELECT * FROM @results

MERGE Daily.ServerPrincipals AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.UserName = T.UserName
    
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName, UserName, type_desc, is_disabled, create_date, modify_date, default_database_name, default_language_name) 
    VALUES (S.ServerName, S.UserName, S.type_desc, S.is_disabled, S.create_date, S.modify_date, S.default_database_name, S.default_language_name)
WHEN MATCHED 
    AND EXISTS (
        SELECT S.ServerName, S.UserName, S.type_desc, S.is_disabled, S.create_date, S.modify_date, S.default_database_name, S.default_language_name
        EXCEPT
        SELECT T.ServerName, T.UserName, T.type_desc, T.is_disabled, T.create_date, T.modify_date, T.default_database_name, T.default_language_name
        )
THEN UPDATE SET
	T.type_desc = S.type_desc, 
	T.is_disabled = S.is_disabled, 
	T.create_date = S.create_date, 
	T.modify_date = S.modify_date, 
	T.default_database_name = S.default_database_name, 
	T.default_language_name  = S.default_language_name      ;
END
GO


-- ================================================
CREATE PROCEDURE spRecordTableColumns  @dbname nvarchar(30)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @sql as nvarchar(1024)

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[COLUMN_NAME] [nvarchar](128) NULL,
	[ORDINAL_POSITION] [int] NULL,
	[COLUMN_DEFAULT] [nvarchar](4000) NULL,
	[IS_NULLABLE] [varchar](3) NULL,
	[DATA_TYPE] [nvarchar](128) NULL,
	[CHARACTER_MAXIMUM_LENGTH] [int] NULL,
	[CHARACTER_OCTET_LENGTH] [int] NULL,
	[NUMERIC_PRECISION] [tinyint] NULL,
	[NUMERIC_PRECISION_RADIX] [smallint] NULL,
	[NUMERIC_SCALE] [int] NULL,
	[DATETIME_PRECISION] [smallint] NULL,
	[CHARACTER_SET_CATALOG] [nvarchar](128) NULL,
	[CHARACTER_SET_SCHEMA] [nvarchar](128) NULL,
	[CHARACTER_SET_NAME] [nvarchar](128) NULL,
	[COLLATION_CATALOG] [nvarchar](128) NULL,
	[COLLATION_SCHEMA] [nvarchar](128) NULL,
	[COLLATION_NAME] [nvarchar](128) NULL,
	[DOMAIN_CATALOG] [nvarchar](128) NULL,
	[DOMAIN_SCHEMA] [nvarchar](128) NULL,
	[DOMAIN_NAME] [nvarchar](128) NULL
	)

select @sql = ' USE ['+@dbname+']

	select	DISTINCT convert(varchar(128),SERVERPROPERTY(''ServerName'')) as ServerName,
		TABLE_CATALOG as DatabaseName,
		TABLE_SCHEMA as SchemaName,
		TABLE_NAME as TableName,
		COLUMN_NAME,
		ORDINAL_POSITION,
	COLUMN_DEFAULT,
	IS_NULLABLE,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	CHARACTER_OCTET_LENGTH,
	NUMERIC_PRECISION,
	NUMERIC_PRECISION_RADIX,
	NUMERIC_SCALE,
	DATETIME_PRECISION,
	CHARACTER_SET_CATALOG,
	CHARACTER_SET_SCHEMA,
	CHARACTER_SET_NAME,
	COLLATION_CATALOG,
	COLLATION_SCHEMA,
	COLLATION_NAME,
	DOMAIN_CATALOG,
	DOMAIN_SCHEMA,
	DOMAIN_NAME
from INFORMATION_SCHEMA.COLUMNS SC
INNER JOIN SQLDataQualityMonitor.Config.vTables VD
ON SC.TABLE_CATALOG = VD.DatabaseName AND SC.TABLE_SCHEMA = VD.SchemaName
WHERE VD.ServerName = convert(varchar(128),SERVERPROPERTY(''ServerName'')) AND VD.Monitored = 1
'
INSERT INTO @results 
EXEC (@sql)

-- SELECT * FROM @results

MERGE Daily.TableColumns AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.DatabaseName = T.DatabaseName
AND S.SchemaName = T.SchemaName 
AND S.TableName = T.TableName
AND S.COLUMN_NAME = T.COLUMN_NAME
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName,DatabaseName,SchemaName,TableName, COLUMN_NAME,		ORDINAL_POSITION,	COLUMN_DEFAULT,	IS_NULLABLE,	DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,	CHARACTER_OCTET_LENGTH,	NUMERIC_PRECISION,	NUMERIC_PRECISION_RADIX,	NUMERIC_SCALE,	DATETIME_PRECISION,	CHARACTER_SET_CATALOG,	CHARACTER_SET_SCHEMA,	CHARACTER_SET_NAME,	COLLATION_CATALOG,	COLLATION_SCHEMA,	COLLATION_NAME,	DOMAIN_CATALOG,DOMAIN_SCHEMA,DOMAIN_NAME) 
    VALUES (S.ServerName,S.DatabaseName,S.SchemaName,S.TableName, S.COLUMN_NAME,S.ORDINAL_POSITION,	S.COLUMN_DEFAULT,S.IS_NULLABLE,	S.DATA_TYPE,S.CHARACTER_MAXIMUM_LENGTH,	S.CHARACTER_OCTET_LENGTH,	S.NUMERIC_PRECISION,	S.NUMERIC_PRECISION_RADIX,	S.NUMERIC_SCALE,	S.DATETIME_PRECISION,	S.CHARACTER_SET_CATALOG,	S.CHARACTER_SET_SCHEMA,	S.CHARACTER_SET_NAME,	S.COLLATION_CATALOG,	S.COLLATION_SCHEMA,	S.COLLATION_NAME,	S.DOMAIN_CATALOG,S.DOMAIN_SCHEMA,S.DOMAIN_NAME)

	-- For Updates
WHEN MATCHED 
    AND EXISTS (
        SELECT S.ServerName,S.DatabaseName,S.SchemaName,S.TableName, S.COLUMN_NAME,S.ORDINAL_POSITION,	S.COLUMN_DEFAULT,S.IS_NULLABLE,	S.DATA_TYPE,S.CHARACTER_MAXIMUM_LENGTH,	S.CHARACTER_OCTET_LENGTH,	S.NUMERIC_PRECISION,	S.NUMERIC_PRECISION_RADIX,	S.NUMERIC_SCALE,	S.DATETIME_PRECISION,	S.CHARACTER_SET_CATALOG,	S.CHARACTER_SET_SCHEMA,	S.CHARACTER_SET_NAME,	S.COLLATION_CATALOG,	S.COLLATION_SCHEMA,	S.COLLATION_NAME,	S.DOMAIN_CATALOG,S.DOMAIN_SCHEMA,S.DOMAIN_NAME
        EXCEPT
        SELECT T.ServerName,T.DatabaseName,T.SchemaName,T.TableName, T.COLUMN_NAME,T.ORDINAL_POSITION,	T.COLUMN_DEFAULT,T.IS_NULLABLE,	T.DATA_TYPE,T.CHARACTER_MAXIMUM_LENGTH,	T.CHARACTER_OCTET_LENGTH,	T.NUMERIC_PRECISION,	T.NUMERIC_PRECISION_RADIX,	T.NUMERIC_SCALE,	T.DATETIME_PRECISION,	T.CHARACTER_SET_CATALOG,	T.CHARACTER_SET_SCHEMA,	T.CHARACTER_SET_NAME,	T.COLLATION_CATALOG,	T.COLLATION_SCHEMA,	T.COLLATION_NAME,	T.DOMAIN_CATALOG,T.DOMAIN_SCHEMA,T.DOMAIN_NAME
        )
THEN UPDATE SET
T.ORDINAL_POSITION = S.ORDINAL_POSITION	,
T.COLUMN_DEFAULT = S.COLUMN_DEFAULT,
T.IS_NULLABLE = S.IS_NULLABLE	,
T.DATA_TYPE = S.DATA_TYPE,
T.CHARACTER_MAXIMUM_LENGTH = S.CHARACTER_MAXIMUM_LENGTH	,
T.CHARACTER_OCTET_LENGTH = S.CHARACTER_OCTET_LENGTH	,
T.NUMERIC_PRECISION = S.NUMERIC_PRECISION	,
T.NUMERIC_PRECISION_RADIX = S.NUMERIC_PRECISION_RADIX	,
T.NUMERIC_SCALE = S.NUMERIC_SCALE	,
T.DATETIME_PRECISION = S.DATETIME_PRECISION	,
T.CHARACTER_SET_CATALOG = S.CHARACTER_SET_CATALOG,	
T.CHARACTER_SET_SCHEMA = S.CHARACTER_SET_SCHEMA	,
T.CHARACTER_SET_NAME = S.CHARACTER_SET_NAME	,
T.COLLATION_CATALOG = S.COLLATION_CATALOG	,
T.COLLATION_SCHEMA = S.COLLATION_SCHEMA	,
T.COLLATION_NAME = S.COLLATION_NAME	,
T.DOMAIN_CATALOG = S.DOMAIN_CATALOG,
T.DOMAIN_SCHEMA = S.DOMAIN_SCHEMA,
T.DOMAIN_NAME = S.DOMAIN_NAME
;
END
GO

-- ================================================
CREATE PROCEDURE spRecordTableSizes @dbname nvarchar(30)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @sql as nvarchar(4000)

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[rows] [bigint] NULL,
	[TotalSpaceKB] [bigint] NULL,
	[TotalSpaceMB] [numeric](36, 2) NULL,
	[UsedSpaceKB] [bigint] NULL,
	[UsedSpaceMB] [numeric](36, 2) NULL,
	[UnusedSpaceKB] [bigint] NULL,
	[UnusedSpaceMB] [numeric](36, 2) NULL,
	[last_access] [datetime] NULL,
	[last_user_update] [datetime] NULL
	)

    -- Insert statements for procedure here
 
 select @sql = ' USE ['+@dbname+']
SELECT TBD.ServerName, TBD.DatabaseName,SchemaName,TableName, rows,TotalSpaceKB,TotalSpaceMB,UsedSpaceKB,UsedSpaceMB,UnusedSpaceKB,UnusedSpaceMB, last_access,last_user_update  
FROM (SELECT convert(varchar(128),SERVERPROPERTY(''ServerName'')) as ServerName, 
	DB_NAME () as DatabaseName,
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
GROUP BY  t.name, s.name, p.rows ) TBD
INNER JOIN SQLDataQualityMonitor.Config.vDatabases SD ON
TBD.ServerName = SD.ServerName AND
TBD.DatabaseName = SD.DatabaseName 
LEFT OUTER JOIN (
select [schema_name], table_name, 
       max(last_access) as last_access, 
	   max(last_user_update) as last_user_update 
from( select schema_name(schema_id) as schema_name,
           name as table_name,
           (select max(last_access) 
            from (values(last_user_seek),
                        (last_user_scan),
                        (last_user_lookup), 
                        (last_user_update)) as tmp(last_access))
                as last_access,
				last_user_update
from sys.dm_db_index_usage_stats sta
join sys.objects obj
     on obj.object_id = sta.object_id
     and obj.type = ''U''
     and sta.database_id = DB_ID()
) usage
group by schema_name, table_name) TBACC ON
TBD.SchemaName = TBACC.schema_name AND
TBD.TableName = TBACC.table_name'

-- PRINT(@sql) 

INSERT INTO @results 
EXEC (@sql)

--SELECT * FROM @results

MERGE Daily.Tables AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.DatabaseName = T.DatabaseName
AND S.SchemaName = T.SchemaName 
AND S.TableName = T.TableName 

    
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName, DatabaseName,SchemaName,TableName, rows,TotalSpaceKB,TotalSpaceMB,UsedSpaceKB,UsedSpaceMB,UnusedSpaceKB,UnusedSpaceMB, last_access,last_user_update) 
    VALUES (S.ServerName, S.DatabaseName, S.SchemaName, S.TableName,  S.rows,S.TotalSpaceKB,S.TotalSpaceMB,S.UsedSpaceKB,S.UsedSpaceMB,S.UnusedSpaceKB,S.UnusedSpaceMB, S.last_access,S.last_user_update)

WHEN MATCHED
    AND EXISTS (
        SELECT S.ServerName, S.DatabaseName, S.SchemaName, S.TableName,  S.rows,S.TotalSpaceKB,S.TotalSpaceMB,S.UsedSpaceKB,S.UsedSpaceMB,S.UnusedSpaceKB,S.UnusedSpaceMB, S.last_access,S.last_user_update
        EXCEPT
        SELECT T.ServerName, T.DatabaseName, T.SchemaName, T.TableName,  T.rows,T.TotalSpaceKB,T.TotalSpaceMB,T.UsedSpaceKB,T.UsedSpaceMB,T.UnusedSpaceKB,T.UnusedSpaceMB, T.last_access,T.last_user_update
        )
    THEN
        UPDATE
        SET 
		T.rows = S.rows ,
		T.TotalSpaceKB = S.TotalSpaceKB ,
		T.TotalSpaceMB = S.TotalSpaceMB ,
		T.UsedSpaceKB = S.UsedSpaceKB ,
		T.UsedSpaceMB = S.UsedSpaceMB,
		T.UnusedSpaceKB = S.UnusedSpaceKB,
		T.UnusedSpaceMB = S.UnusedSpaceMB, 
		T.last_access = S.last_access,
		T.last_user_update = S.last_user_update
    ;
END
GO

-- ================================================
-- STORED PROCEDURES - RealTime
-- ================================================
CREATE PROCEDURE spRecordUsers
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[Login] [nchar](128) NOT NULL,
	[hostname] [nchar](128) NOT NULL,
	[ProgramName] [nchar](128) NULL,
	[LastBatch] [datetime] NULL
	)

    -- Insert statements for procedure here
 INSERT INTO @results (ServerName, DatabaseName, Login, hostname, ProgramName, LastBatch)
 SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, 
        sd.name DBName, 
        loginame [Login],
        hostname, 
        [program_name] ProgramName,
		max(last_batch) LastBatch 
FROM master.dbo.sysprocesses sp 
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
group by loginame, hostname, sd.name, [program_name]  

MERGE RealTime.Users AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.DatabaseName = T.DatabaseName
AND S.Login = T.Login
AND S.hostname = T.hostname
AND S.ProgramName = T.ProgramName
    
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName, DatabaseName, Login, hostname, ProgramName, LastBatch) 
    VALUES (S.ServerName, S.DatabaseName, S.Login, S.hostname, S.ProgramName, S.LastBatch)
    
-- For Updates
WHEN MATCHED THEN UPDATE SET
    T.LastBatch	= S.LastBatch
    
-- For Deletes
WHEN NOT MATCHED BY Source THEN
    DELETE;

END
GO

-- ================================================
CREATE PROCEDURE spRecordJobs
AS
BEGIN
    SET NOCOUNT ON

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[JobName] [nvarchar](128) NOT NULL,
	[TimeRun] [varchar](30) NULL,
	[JobStatus] [varchar](8) NOT NULL,
	[enabled] [tinyint] NOT NULL,
	[JobOutcome] [varchar](9) NOT NULL,
	[run_status] [int] NOT NULL
	)

    -- Insert statements for procedure here
 INSERT INTO @results (ServerName, JobName, TimeRun, JobStatus, enabled, JobOutcome, run_status)
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

MERGE RealTime.Jobs AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.JobName = T.JobName
    
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName, JobName, TimeRun, JobStatus, enabled, JobOutcome, run_status) 
    VALUES (S.ServerName, S.JobName, S.TimeRun, S.JobStatus, S.enabled, S.JobOutcome, S.run_status)
WHEN MATCHED 
    AND EXISTS (
        SELECT S.ServerName, S.JobName, S.TimeRun, S.JobStatus, S.enabled, S.JobOutcome, S.run_status
        EXCEPT
        SELECT T.ServerName, T.JobName, T.TimeRun, T.JobStatus, T.enabled, T.JobOutcome, T.run_status
        )
THEN UPDATE SET
    T.TimeRun = S.TimeRun, 
	T.JobStatus = S.JobStatus, 
	T.enabled= S.enabled, 
	T.JobOutcome = S.JobOutcome, 
	T.run_status = S.run_status
    ;
END
GO

-- ================================================
CREATE PROCEDURE spRecordTableRows @dbname nvarchar(30), @periodcolumn nvarchar(30)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @sql as nvarchar(4000)

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[rows] [bigint] NULL
	)

    -- Insert statements for procedure here
 
 select @sql = ' USE ['+@dbname+']
SELECT 
convert(varchar(128),SERVERPROPERTY(''ServerName'')) as ServerName,
DB_NAME () as DatabaseName,
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN
    SQLDataQualityMonitor.Config.vTables TBL ON t.name = TBL.TableName AND s.name = TBL.SchemaName 
WHERE 
TBL.ServerName = convert(varchar(128),SERVERPROPERTY(''ServerName''))
AND TBL.DatabaseName = DB_NAME ()
AND TBL.['+@periodcolumn+'] = 1 
GROUP BY 
    t.name, s.name, p.rows
'

-- PRINT(@sql) 

INSERT INTO @results 
EXEC (@sql)

--SELECT * FROM @results

MERGE RealTime.TableRows AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.DatabaseName = T.DatabaseName
AND S.SchemaName = T.SchemaName 
AND S.TableName = T.TableName 

-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName, DatabaseName,SchemaName,TableName, rows) 
    VALUES (S.ServerName, S.DatabaseName, S.SchemaName, S.TableName,  S.rows)
WHEN MATCHED
    THEN
        UPDATE
        SET 
		T.rows = S.rows 
    ;
END
GO

-- ================================================
-- STORED PROCEDURES - SQL AGENT STEPS FOR JOBS
-- ================================================
CREATE PROCEDURE spAgentDaily
AS
BEGIN
    SET NOCOUNT ON
	exec SQLDataQualityMonitor.dbo.spSetupServer


	DECLARE @daily  as bit
	DECLARE @monitored  as bit

	SELECT @monitored = Monitored FROM Config.Servers WHERE ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) 

	IF @monitored = 1
	BEGIN
		SELECT @daily = Daily FROM Config.Servers WHERE ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) 
		IF @daily = 1
			BEGIN
				exec SQLDataQualityMonitor.dbo.spSetupDatabases
				exec SQLDataQualityMonitor.dbo.spRecordServerPrincipals
				exec SQLDataQualityMonitor.dbo.spRecordDatabases
				exec sp_msforeachdb 'SQLDataQualityMonitor.dbo.spSetupTables ?'
				exec sp_msforeachdb 'SQLDataQualityMonitor.dbo.spRecordTableSizes ?'
				exec sp_msforeachdb 'SQLDataQualityMonitor.dbo.spRecordTableColumns ?'
			END
	END

END
GO

-- ================================================
CREATE PROCEDURE spAgentRealTime
AS
BEGIN
    SET NOCOUNT ON
	DECLARE @fast  as bit
	DECLARE @monitored  as bit

	SELECT @monitored = Monitored FROM Config.Servers WHERE ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) 

	IF @monitored = 1
	BEGIN
		SELECT @fast = RealTime FROM Config.Servers WHERE ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) 
		-- fast - every minute - Entire Server
		IF @fast = 1
			BEGIN
				exec SQLDataQualityMonitor.dbo.spRecordUsers
				exec SQLDataQualityMonitor.dbo.spRecordJobs
				exec sp_msforeachdb 'SQLDataQualityMonitor.dbo.spRecordTableRows ?,''RealTime'' '
			END 
	END
END
GO
-- ================================================
