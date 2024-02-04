 
SELECT *
FROM   RealTime.TableRowCount FOR SYSTEM_TIME ALL
where DatabaseName = 'SQLDataQualityMonitor'
order by TableName,ValidFrom;
