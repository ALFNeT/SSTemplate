CREATE EVENT SESSION [blocked_process] ON SERVER
ADD EVENT sqlos.wait_info (
    ACTION (sqlos.task_time, sqlserver.plan_handle, sqlserver.query_hash, sqlserver.session_id, sqlserver.sql_text,
    sqlserver.tsql_frame, sqlserver.tsql_stack)
    WHERE ([package0].[equal_uint64]([sqlserver].[database_id], (<database_id>))
           AND [package0].[greater_than_uint64]([duration], (1000))  --significant duration
           AND [package0].[not_equal_uint64]([wait_type], (121))     --wait types to discard
           AND [package0].[not_equal_uint64]([wait_type], (109))
           AND [package0].[not_equal_uint64]([wait_type], (195))
           AND [sqlserver].[session_id] > (50))),
ADD EVENT sqlserver.blocked_process_report (
    ACTION (sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_name)
    WHERE ([package0].[equal_int64]([database_id], (6)))),
ADD EVENT sqlserver.xml_deadlock_report (
    ACTION (sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_name)
    WHERE ([sqlserver].[database_id] = (6)))
ADD TARGET package0.event_file (SET FILENAME = N'<path>'
                               ,max_file_size = (65536)
                               ,max_rollover_files = (2))
WITH (MAX_MEMORY = 4096 KB
     ,EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
     ,MAX_DISPATCH_LATENCY = 5 SECONDS
     ,MAX_EVENT_SIZE = 0 KB
     ,MEMORY_PARTITION_MODE = NONE
     ,TRACK_CAUSALITY = ON
     ,STARTUP_STATE = OFF)
GO


EXEC sp_configure 'blocked process threshold', '3';
 --by default its 0 seconds,	blocked process report is done on a best effort basis
RECONFIGURE
GO
/* Start the Extended Events session */
ALTER EVENT SESSION [blocked_process] ON SERVER
STATE = START;


/* CLEAN UP CODE
ALTER EVENT SESSION [blocked_process] ON SERVER
STATE = STOP;

EXEC sp_configure 'blocked process threshold', '0';--Back to default
RECONFIGURE
GO
*/

SELECT  CAST(event_data AS XML) AS xmldata
FROM    sys.fn_xe_file_target_read_file('<path>*.xel', NULL, NULL, NULL);