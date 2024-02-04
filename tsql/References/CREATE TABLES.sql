USE [SQLDataQualityMonitor]
GO

/****** Object:  Table [dbo].[Tables]    Script Date: 2024-01-31 8:02:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Tables](
	[ServerName] [nvarchar](255) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	RapidScan bit,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_Tables_SvrName_DBName_SchName_name PRIMARY KEY ([ServerName],[DatabaseName],[SchemaName],[TableName]),
	CONSTRAINT FK_Tables_ServerName_Databases FOREIGN KEY ([ServerName],[DatabaseName]) REFERENCES Databases([ServerName],[name]), 
)
WITH (SYSTEM_VERSIONING = ON);

GO


