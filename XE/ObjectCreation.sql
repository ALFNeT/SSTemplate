CREATE EVENT SESSION [TempTableCreation] ON SERVER
ADD EVENT sqlserver.object_created (
    ACTION (-- you may not need all of these columns
    sqlserver.session_nt_username, sqlserver.server_principal_name, sqlserver.session_id, sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.sql_text)
    WHERE 
  (sqlserver.like_i_sql_unicode_string([object_name], N'#%')
   AND ddl_phase = 1   -- just capture COMMIT, not BEGIN
   ))
ADD TARGET package0.asynchronous_file_target (SET FILENAME = '<path>.xel'
                                             ,
  -- you may want to set different limits depending on
  -- temp table creation rate and available disk space
                                              MAX_FILE_SIZE = 32768
                                             ,MAX_ROLLOVER_FILES = 10)
WITH (-- if temp table creation rate is high, consider
  -- ALLOW_SINGLE/MULTIPLE_EVENT_LOSS instead
    EVENT_RETENTION_MODE = NO_EVENT_LOSS);
GO
ALTER EVENT SESSION [TempTableCreation] ON SERVER STATE = START;



---------


DECLARE @delta INT = DATEDIFF(MINUTE, SYSUTCDATETIME(), SYSDATETIME());

WITH    xe
          AS (SELECT    [obj_name] = xe.d.value(N'(event/data[@name="object_name"]/value)[1]', N'sysname')
                       ,[object_id] = xe.d.value(N'(event/data[@name="object_id"]/value)[1]', N'int')
                       ,[timestamp] = DATEADD(MINUTE, @delta, xe.d.value(N'(event/@timestamp)[1]', N'datetime2'))
                       ,SPID = xe.d.value(N'(event/action[@name="session_id"]/value)[1]', N'int')
                       ,NTUserName = xe.d.value(N'(event/action[@name="session_nt_username"]/value)[1]', N'sysname')
                       ,SQLLogin = xe.d.value(N'(event/action[@name="server_principal_name"]/value)[1]', N'sysname')
                       ,HostName = xe.d.value(N'(event/action[@name="client_hostname"]/value)[1]', N'sysname')
                       ,AppName = xe.d.value(N'(event/action[@name="client_app_name"]/value)[1]', N'nvarchar(max)')
                       ,SQLBatch = xe.d.value(N'(event/action[@name="sql_text"]/value)[1]', N'nvarchar(max)')
              FROM      sys.fn_xe_file_target_read_file(N'<path>*.xel', NULL, NULL, NULL) AS ft
              CROSS APPLY (SELECT CONVERT( XML, ft.event_data)) AS xe (d))
    SELECT  DefinedName = xe.obj_name
           ,GeneratedName = o.name
           ,o.[object_id]
           ,xe.[timestamp]
           ,o.create_date
           ,xe.SPID
           ,xe.NTUserName
           ,xe.SQLLogin
           ,xe.HostName
           ,ApplicationName = xe.AppName
           ,TextData = xe.SQLBatch
           ,row_count = x.rc
           ,reserved_page_count = x.rpc
    FROM    xe
    INNER JOIN tempdb.sys.objects AS o --change to left join if #temp table doesnt exist anymore
            ON o.[object_id] = xe.[object_id]
               AND o.create_date >= DATEADD(SECOND, -2, xe.[timestamp])
               AND o.create_date <= DATEADD(SECOND, 2, xe.[timestamp])
    INNER JOIN --change to left join if #temp table doesnt exist anymore
            (SELECT [object_id]
                   ,rc = SUM(CASE WHEN index_id IN (0, 1) THEN row_count
                             END)
                   ,rpc = SUM(reserved_page_count)
             FROM   tempdb.sys.dm_db_partition_stats
             GROUP BY [object_id]) AS x ON o.[object_id] = x.[object_id];