/*
CREATE EVENT SESSION [recommendations] ON SERVER
ADD EVENT sqlserver.rpc_completed (SET collect_statement = (1)
    ACTION (package0.last_error, sqlserver.database_name, sqlserver.nt_username)
    WHERE ([sqlserver].[equal_i_sql_unicode_string]([object_name], N'<object1_name>')
           OR [sqlserver].[equal_i_sql_unicode_string]([object_name], N'<object2_name>')
           AND [sqlserver].[database_id] = (15))) ,
ADD EVENT sqlserver.rpc_starting (
    ACTION (package0.last_error, sqlserver.database_name, sqlserver.nt_username)
    WHERE ([object_name] = N'<object1_name>'
           OR [object_name] = N'<object2_name>'
           AND [sqlserver].[database_id] = (15)))
ADD TARGET package0.event_file (SET filename = N'c:\temp\xe\<trace_name>'
                               ,max_file_size = (256)
                               ,max_rollover_files = (2))
WITH (MAX_MEMORY = 4096 KB
     ,EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
     ,MAX_DISPATCH_LATENCY = 20 SECONDS
     ,MAX_EVENT_SIZE = 0 KB
     ,MEMORY_PARTITION_MODE = NONE
     ,TRACK_CAUSALITY = OFF
     ,STARTUP_STATE = OFF)
GO


*/

IF OBJECT_ID('tempdb..#xeData') IS NOT NULL
    DROP TABLE #xeData;

WITH    AsyncFileData
          AS (SELECT    CAST(event_data AS XML) AS xmldata
              FROM      sys.fn_xe_file_target_read_file('<path>*.xel', NULL, NULL, NULL))
        SELECT
                 FinalData.R.value('@name', 'nvarchar(50)') AS EventName
                ,DATEADD(HOUR, 12, FinalData.R.value('@timestamp', 'datetime')) AS EventTimeStamp
                ,FinalData.R.value('(data[@name="statement"]/value)[1]', 'nvarchar(2000)') AS [statement]
                ,FinalData.R.value('(data[@name="duration"]/value)[1]', 'integer')/1000 AS [duration]
                ,FinalData.R.value('(data[@name="cpu_time"]/value)[1]', 'integer') AS [cpu_time]
                ,FinalData.R.value('(data[@name="physical_reads"]/value)[1]', 'integer') AS [physical_reads]
                ,FinalData.R.value('(data[@name="logical_reads"]/value)[1]', 'integer') AS [logical_reads]
                ,FinalData.R.value('(data[@name="writes"]/value)[1]', 'integer') AS [writes]
                ,FinalData.R.value('(data[@name="row_count"]/value)[1]', 'integer') AS [row_count]
                ,FinalData.R.value('(data[@name="last_error"]/value)[1]', 'integer') AS [last_error]
        INTO #xeData
        FROM    AsyncFileData
        CROSS APPLY xmldata.nodes('//event') AS FinalData (R)
        ORDER BY [EventTimeStamp] DESC;


SELECT memberid, COUNT(*) [count], AVG(duration) [avg_duration], MIN(duration) [min_duration],MAX(duration) [max_duration] FROM #xedata
WHERE EventName = 'rpc_completed'
GROUP BY memberid
ORDER BY AVG(duration) desc