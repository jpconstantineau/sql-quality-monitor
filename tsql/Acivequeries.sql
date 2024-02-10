SELECT 
    qs.execution_count AS [Execution Count],
    qs.total_logical_reads AS [Total Logical Reads],
    qs.total_logical_writes AS [Total Logical Writes],
    qs.total_physical_reads AS [Total Physical Reads],
    qs.total_elapsed_time AS [Total Elapsed Time],
    qs.total_worker_time AS [Total Worker Time],
    qs.total_clr_time AS [Total CLR Time],
    qs.creation_time AS [Creation Time],
    qs.last_execution_time AS [Last Execution Time],
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
    ((CASE qs.statement_end_offset
      WHEN -1 THEN DATALENGTH(st.text)
      ELSE qs.statement_end_offset
    END - qs.statement_start_offset)/2) + 1) AS [SQL Statement]
FROM 
    sys.dm_exec_query_stats AS qs
CROSS APPLY 
    sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY 
    qs.execution_count DESC;
