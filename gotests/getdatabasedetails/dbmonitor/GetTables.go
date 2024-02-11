/*
SELECT [DatabaseName], Daily, RealTime
FROM [SQLDataQualityMonitor].[Config].[Databases]
WHERE [Monitored] = 1 AND [ServerName] = 'Zen-Corrology\SQLEXPRESS'
*/

package dbmonitor

type MonitoredTables struct {
	ServerName   string
	DatabaseName string
}
