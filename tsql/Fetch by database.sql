 -- Get List of Tables in Current Database
SELECT 
convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName, 
DB_NAME () as DBName,
    s.name AS SchemaName,
    t.name AS TableName
FROM 
    sys.tables t
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id

-- Get Table Schemas of current database spRecordTableColumns NO  VIEW
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

-- Get Table Sizes - NO VIEW
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

 -- Get Table Rows - NO VIEW
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
GROUP BY 
    t.name, s.name, p.rows
