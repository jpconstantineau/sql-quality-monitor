SELECT TBD.*, last_access,last_user_update  from (SELECT 
SERVERPROPERTY('ServerName') as ServerName, 
DB_NAME () as DBName,
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
--into SQLDataQualityMonitor.dbo.TableSizes
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
--WHERE 
   -- t.name NOT LIKE 'dt%' 
  --  AND t.is_ms_shipped = 0
   -- AND i.object_id > 255 
GROUP BY  t.name, s.name, p.rows ) TBD
LEFT OUTER JOIN (

select [schema_name], 
       table_name, 
       max(last_access) as last_access, 
	   max(last_user_update) as last_user_update 

	  -- into SQLDataQualityMonitor.dbo.TableAccess
from(
    select schema_name(schema_id) as schema_name,
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