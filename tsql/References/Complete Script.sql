USE master;
GO
IF DB_ID (N'SQLDataQualityMonitor') IS NOT NULL
DROP DATABASE SQLDataQualityMonitor;
GO
CREATE DATABASE SQLDataQualityMonitor;
GO
-- Verify the database files and sizes
SELECT name, size, size*1.0/128 AS [Size in MBs]
FROM sys.master_files
WHERE name = N'SQLDataQualityMonitor';
GO


USE [SQLDataQualityMonitor]
GO
CREATE TABLE [dbo].[Servers](
	ID int IDENTITY,
	[ServerName] [nvarchar](255) NOT NULL,
	[Monitored] [bit] NOT NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_Servers_ServerName PRIMARY KEY (ID),
) 
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));
GO

ALTER TABLE [dbo].[Servers] ADD  CONSTRAINT [DF_Servers_Monitored]  DEFAULT ((0)) FOR [Monitored]
GO


CREATE TABLE [dbo].[Databases]
(
	ID int IDENTITY,
	[ServerID] int NOT NULL,
	[name] [nvarchar](128) NOT NULL,
	[create_date] [datetime] NOT NULL,
	[collation_name] [nvarchar](128) NULL,
	[user_access_desc] [nvarchar](60) NULL,
	[state_desc] [nvarchar](60) NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),    
	CONSTRAINT FK_Databases_ServerID FOREIGN KEY (ServerID) REFERENCES Servers(ID),
	CONSTRAINT PK_Databases PRIMARY KEY (ID )
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO



CREATE TABLE [dbo].[Tables](
	ID int IDENTITY,
	[DatabaseID] int NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	RapidScan bit,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_Tables PRIMARY KEY (ID),
	CONSTRAINT FK_Tables_ServerName_Databases FOREIGN KEY (DatabaseID) REFERENCES Databases(ID), 
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

CREATE TABLE [dbo].[TableData](
	ID int IDENTITY,
	[TableID] int NOT NULL,
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
	CONSTRAINT FK_TableData_Tables FOREIGN KEY (TableID) REFERENCES Tables(ID) 
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

CREATE TABLE [dbo].[TableSchemas](
	ID int IDENTITY,
	[TableID] int NOT NULL,
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
	CONSTRAINT PK_TableSchema PRIMARY KEY (ID),
	CONSTRAINT FK_TableSchema_Tables FOREIGN KEY (TableID) REFERENCES Tables(ID) 
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO


CREATE TABLE [dbo].[Users](
	ID int IDENTITY,
	[DatabaseID] int NOT NULL,
	[Login] [nchar](128) NOT NULL,
	[hostname] [nchar](128) NOT NULL,
	[ProgramName] [nchar](128) NULL,
	[LastBatch] [datetime] NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_Users PRIMARY KEY (ID),
	CONSTRAINT FK_Users_Databases FOREIGN KEY (DatabaseID) REFERENCES Databases(ID)

) 
WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO

CREATE TABLE [dbo].[JobStatus](
	ID int IDENTITY,
	[ServerID] int NOT NULL,
	[JobName] [nvarchar](128) NOT NULL,
	[Time Run] [varchar](30) NULL,
	[JobStatus] [varchar](8) NOT NULL,
	[enabled] [tinyint] NOT NULL,
	[JobOutcome] [varchar](9) NOT NULL,
	[run_status] [int] NOT NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_JobStatus PRIMARY KEY (ID),
	CONSTRAINT FK_JobStatus_Servers FOREIGN KEY (ServerID) REFERENCES Servers(ID)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_RETENTION_PERIOD = 18 MONTHS));

GO
