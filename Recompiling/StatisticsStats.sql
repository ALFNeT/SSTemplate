SELECT  [sch].[name] + '.' + [so].[name] AS [TableName]
       ,[ss].[name] AS [Statistic]
       ,[sp].[last_updated] AS [StatsLastUpdated]
       ,[sp].[rows] AS [RowsInTable]
       ,[sp].[rows_sampled] AS [RowsSampled]
       ,[sp].[modification_counter] AS [RowModifications]
	   ,CAST(sp.modification_counter AS	DECIMAL) / [sp].[rows_sampled]  AS [ModRatio]
FROM    [sys].[stats] [ss]
JOIN    [sys].[objects] [so] ON [ss].[object_id] = [so].[object_id]
JOIN    [sys].[schemas] [sch] ON [so].[schema_id] = [sch].[schema_id]
OUTER APPLY [sys].[dm_db_stats_properties]([so].[object_id], [ss].[stats_id]) sp
WHERE   [so].[type] = 'U'
        AND [sp].[modification_counter] > 0
ORDER BY [ModRatio] DESC , [sp].[last_updated] DESC;