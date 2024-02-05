 -- Get Databases Details - CALLS VIEW
 SELECT
	convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, name as DatabaseName, create_date, collation_name,user_access_desc,state_desc,recovery_model_desc  
	FROM sys.databases SD
	INNER JOIN SQLDataQualityMonitor.Config.vDatabases VD
	ON SD.name = VD.DatabaseName
	WHERE VD.ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) AND VD.Monitored = 1
	; 


-- Get Table Schemas if current database spRecordTableColumns CALLS VIEW
select	DISTINCT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName,
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
WHERE VD.ServerName = convert(varchar(128),SERVERPROPERTY('ServerName')) AND VD.Monitored = 1

-- Get Table Sizes - CALLS VIEW
-- spRecordTableSizes
SELECT TBD.ServerName, TBD.DatabaseName,SchemaName,TableName, rows,TotalSpaceKB,TotalSpaceMB,UsedSpaceKB,UsedSpaceMB,UnusedSpaceKB,UnusedSpaceMB, last_access,last_user_update  
FROM (SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, 
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
     and obj.type = 'U'
     and sta.database_id = DB_ID()
) usage
group by schema_name, table_name) TBACC ON
TBD.SchemaName = TBACC.schema_name AND
TBD.TableName = TBACC.table_name



  -- Get Table Rows - CALLS VIEW
  -- spRecordTableRows

  SELECT 
convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName,
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
TBL.ServerName = convert(varchar(128),SERVERPROPERTY('ServerName'))
AND TBL.DatabaseName = DB_NAME ()
AND TBL.[RealTime] = 1 
GROUP BY 
    t.name, s.name, p.rows

	 