/*
Check file names!
*/
--Create XE
CREATE EVENT SESSION TrackLockEscalation ON SERVER
ADD EVENT sqlserver.lock_escalation (
    ACTION (sqlserver.sql_text, sqlserver.database_name, sqlserver.client_hostname, sqlserver.username, sqlserver.tsql_stack, sqlserver.server_instance_name, sqlserver.session_id))
ADD TARGET Package0.asynchronous_file_target (SET filename = '<path>.xel')
WITH (MAX_MEMORY = 4096 KB
     ,EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
     ,MAX_DISPATCH_LATENCY = 30 SECONDS
     ,MAX_EVENT_SIZE = 0 KB
     ,MEMORY_PARTITION_MODE = NONE
     ,TRACK_CAUSALITY = OFF
     ,STARTUP_STATE = OFF);
GO


--Start Session
ALTER EVENT SESSION TrackLockEscalation;
ON SERVER
STATE=START
GO

--Read Data
WITH    AsyncFileData
          AS (SELECT    CAST(event_data AS XML) AS xmldata
              FROM      sys.fn_xe_file_target_read_file('<path>*.xel', NULL, NULL, NULL))
    SELECT --TOP 100
            FinalData.R.value('@name', 'nvarchar(50)') AS EventName
           ,DATEADD(HOUR, 12, FinalData.R.value('@timestamp', 'datetime')) AS EventTimeStamp
           ,FinalData.R.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(2000)') AS [SQL Text]
           ,FinalData.R.value('(data[@name="escalation_cause"]/value)[1]', 'varchar(50)') + ' - ' + FinalData.R.value('(data[@name="escalation_cause"]/text)[1]', 'varchar(50)') AS [Lock Escalation cause]
           ,FinalData.R.value('(data[@name="hobt_lock_count"]/value)[1]', 'varchar(50)') AS [IntegerData]
           ,FinalData.R.value('(data[@name="escalated_lock_count"]/value)[1]', 'varchar(50)') AS [IntegerData2]
           ,FinalData.R.value('(data[@name="mode"]/value)[1]', 'varchar(50)') + ' - ' + FinalData.R.value('(data[@name="mode"]/text)[1]', 'varchar(50)') AS [Resource Mode]
           ,FinalData.R.value('(data[@name="resource_type"]/value)[1]', 'varchar(50)') + ' - ' + FinalData.R.value('(data[@name="resource_type"]/text)[1]', 'varchar(50)') AS [Resource Type]
           ,OBJECT_NAME(FinalData.R.value('(data[@name="object_id"]/value)[1]', 'varchar(50)'), FinalData.R.value('(data[@name="database_id"]/value)[1]', 'INT')) AS [ObjectID]
    FROM    AsyncFileData
    CROSS APPLY xmldata.nodes('//event') AS FinalData (R)
    ORDER BY [EventTimeStamp] DESC;



/*Clean up
ALTER EVENT SESSION TrackLockEscalation
ON SERVER
STATE=STOP
GO

DROP EVENT SESSION TrackLockEscalation ON SERVER
GO
*/