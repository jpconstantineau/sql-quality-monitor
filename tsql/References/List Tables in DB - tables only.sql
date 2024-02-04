SELECT 
SERVERPROPERTY('ServerName') as ServerName, 
DB_NAME () as DBName,
    s.name AS SchemaName,
    t.name AS TableName

	--into SQLDataQualityMonitor.dbo.Tables
FROM 
    sys.tables t
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
--WHERE 
   -- t.name NOT LIKE 'dt%' 
  --  AND t.is_ms_shipped = 0
   -- AND i.object_id > 255 
