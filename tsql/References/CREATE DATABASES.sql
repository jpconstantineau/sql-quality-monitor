USE [SQLDataQualityMonitor]
GO

/****** Object:  Table [dbo].[Databases]    Script Date: 2024-01-31 6:08:57 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Databases]
(
	[ServerName] [nvarchar](255) NOT NULL,
	[name] [nvarchar](128) NOT NULL,
	[create_date] [datetime] NOT NULL,
	[collation_name] [nvarchar](128) NULL,
	[user_access_desc] [nvarchar](60) NULL,
	[state_desc] [nvarchar](60) NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),    
	CONSTRAINT FK_Databases_ServerName FOREIGN KEY ([ServerName]) REFERENCES Servers([ServerName]),
	CONSTRAINT PK_Databases_ServerName_Name PRIMARY KEY ([ServerName],[name] )
)
WITH (SYSTEM_VERSIONING = ON);

GO