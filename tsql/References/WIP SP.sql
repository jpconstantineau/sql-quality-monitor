CREATE PROCEDURE spRecordTableRows @dbname nvarchar(30)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @sql as nvarchar(4000)

	DECLARE @results TABLE
	(
	[ServerName] [nvarchar](128) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
	[rows] [bigint] NULL
	)

    -- Insert statements for procedure here
 
 select @sql = ' USE ['+@dbname+']
SELECT 
convert(varchar(128),SERVERPROPERTY(''ServerName'')) as ServerName,
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
'

-- PRINT(@sql) 

INSERT INTO @results 
EXEC (@sql)

--SELECT * FROM @results

MERGE dbo.TableRowCount AS T
USING @results	AS S
ON  S.ServerName = T.ServerName
AND S.DatabaseName = T.DatabaseName
AND S.SchemaName = T.SchemaName 
AND S.TableName = T.TableName 

-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ServerName, DatabaseName,SchemaName,TableName, rows) 
    VALUES (S.ServerName, S.DatabaseName, S.SchemaName, S.TableName,  S.rows)
    ;
END
GO

