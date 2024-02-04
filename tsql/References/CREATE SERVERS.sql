USE [SQLDataQualityMonitor]
GO

ALTER TABLE [dbo].[Servers] DROP CONSTRAINT [DF_Servers_Monitored]
GO

/****** Object:  Table [dbo].[Servers]    Script Date: 2024-01-31 8:19:51 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Servers]') AND type in (N'U'))
DROP TABLE [dbo].[Servers]
GO

/****** Object:  Table [dbo].[Servers]    Script Date: 2024-01-31 8:19:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Servers](
	[ServerName] [nvarchar](255) NOT NULL,
	[Monitored] [bit] NOT NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),   
	CONSTRAINT PK_Servers_ServerName PRIMARY KEY ([ServerName] )
) WITH (SYSTEM_VERSIONING = ON);
GO

ALTER TABLE [dbo].[Servers] ADD  CONSTRAINT [DF_Servers_Monitored]  DEFAULT ((0)) FOR [Monitored]
GO


