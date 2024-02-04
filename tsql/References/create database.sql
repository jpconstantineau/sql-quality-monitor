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