select SERVERPROPERTY('ServerName') as ServerName, TABLE_CATALOG as DatabaseName, TABLE_SCHEMA as TableSchema, TABLE_NAME as name, COLUMN_NAME as ColumnName, *

--into SQLDataQualityMonitor.dbo.TableSchemas
from INFORMATION_SCHEMA.COLUMNS