--Current Memory Usage
SELECT  counter_name
       ,instance_name
       ,mb = cntr_value / 1024.0
FROM    sys.dm_os_performance_counters
WHERE   (counter_name = N'Cursor memory usage'
         AND instance_name <> N'_Total')
        OR (instance_name = N''
            AND counter_name IN (N'Connection Memory (KB)', N'Granted Workspace Memory (KB)', N'Lock Memory (KB)', N'Optimizer Memory (KB)', N'Stolen Server Memory (KB)', N'Log Pool Memory (KB)', N'Free Memory (KB)'))
ORDER BY mb DESC;



--User Connections
SELECT  object_name
       ,counter_name
       ,cntr_value
FROM    sys.dm_os_performance_counters
WHERE   [counter_name] = 'User Connections';

--Locks
SELECT  object_name
       ,counter_name
       ,cntr_value
FROM    sys.dm_os_performance_counters
WHERE   [counter_name] IN ('Lock Blocks', 'Lock Blocks Allocated', 'Lock Memory (KB)', 'Lock Owner Blocks');


--Memory locked per Node
SELECT  osn.node_id
       ,osn.memory_node_id
       ,osn.node_state_desc
       ,omn.locked_page_allocations_kb
FROM    sys.dm_os_memory_nodes omn
INNER JOIN sys.dm_os_nodes osn ON (omn.memory_node_id = osn.memory_node_id)
WHERE   osn.node_state_desc <> 'ONLINE DAC';


SELECT  *
FROM    sys.dm_os_memory_clerks
WHERE   type LIKE 'OBJECTSTORE_LOCK_MANAGER';

--Resource Monitor thread info
SELECT  STasks.session_id
       ,SThreads.os_thread_id
       ,b.command
       ,*
FROM    sys.dm_os_tasks AS STasks
INNER JOIN sys.dm_os_threads AS SThreads ON STasks.worker_address = SThreads.worker_address
LEFT OUTER JOIN sys.dm_exec_requests b ON STasks.session_id = b.session_id
WHERE   STasks.session_id IS NOT NULL
        AND command = 'RESOURCE MONITOR'
ORDER BY SThreads.os_thread_id;



SELECT  s.name AS 'Sessions'
FROM    sys.server_event_sessions AS s
WHERE   s.name <> 'system_health'
        AND s.name <> 'AlwaysOn_health';


DBCC MEMORYSTATUS;


---performance counters



--Top 20 clerks
SELECT TOP (21)
        [type] = COALESCE([type], 'Total')
       ,mb = SUM(pages_kb / 1024.0)
FROM    sys.dm_os_memory_clerks
GROUP BY GROUPING SETS((type), ())
ORDER BY mb DESC;

--thread stack size, First, make sure this is zero, and not some custom number (if it is not 0, find out why, and fix it):
SELECT  value_in_use
FROM    sys.configurations
WHERE   name = N'max worker threads';

--How much memory is being taken up by thread stacks
SELECT  stack_size_in_bytes / 1024.0 / 1024 AS [stackSizeInGb]
FROM    sys.dm_os_sys_info;

--3rd party modules loaded
SELECT  base_address
       ,description
       ,name
FROM    sys.dm_os_loaded_modules
WHERE   company NOT LIKE N'Microsoft%';
--can probably trace down memory usage using the base_address

--memory-related DMVs
SELECT  *
FROM    sys.dm_os_sys_memory;
SELECT  *
FROM    sys.dm_os_memory_nodes
WHERE   memory_node_id <> 64;

;
WITH    cte([totalCPU])
          AS (SELECT    SUM(cpu)
              FROM      master.dbo.sysprocesses)
    SELECT  tblSysprocess.spid
           ,tblSysprocess.cpu
           ,(tblSysprocess.cpu) / cte.totalCPU AS [percentileCPU]
           ,tblSysprocess.physical_io
           ,tblSysprocess.memusage
           ,tblSysprocess.cmd
           ,tblSysprocess.lastwaittype
    FROM    master.dbo.sysprocesses tblSysprocess
    CROSS APPLY cte
    ORDER BY tblSysprocess.cpu DESC;
GO


SELECT  EventTime
       ,record.value('(/Record/ResourceMonitor/Notification)[1]', 'varchar(max)') AS [Type]
       ,record.value('(/Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') AS [IndicatorsProcess]
       ,record.value('(/Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') AS [IndicatorsSystem]
       ,record.value('(/Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [Avail Phys Mem, Kb]
       ,record.value('(/Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [Avail VAS, Kb]
FROM    (SELECT DATEADD(ss, (-1 * ((cpu_ticks / CONVERT (FLOAT, (cpu_ticks / ms_ticks))) - [timestamp]) / 1000), GETDATE()) AS EventTime
               ,CONVERT (XML, record) AS record
         FROM   sys.dm_os_ring_buffers
         CROSS JOIN sys.dm_os_sys_info
         WHERE  ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR') AS tab
ORDER BY EventTime DESC;


SELECT  *
FROM    sys.dm_os_memory_cache_clock_hands;



SELECT  CONVERT (VARCHAR(30), GETDATE(), 121) AS [RunTime]
       ,DATEADD(ms, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) AS [Notification_Time]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') AS [Notification_type]
       ,CAST(record AS XML).value('(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint') AS [MemoryUtilization %]
       ,CAST(record AS XML).value('(//Record/MemoryNode/@id)[1]', 'bigint') AS [Node Id]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') AS [Process_Indicator]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') AS [System_Indicator]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect/@type)[1]', 'varchar(30)') AS [type]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect/@state)[1]', 'varchar(30)') AS [state]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect/@reversed)[1]', 'int') AS [reserved]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect)[1]', 'bigint') AS [Effect]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[2]/@type)[1]', 'varchar(30)') AS [type]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[2]/@state)[1]', 'varchar(30)') AS [state]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[2]/@reversed)[1]', 'int') AS [reserved]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect)[2]', 'bigint') AS [Effect]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[3]/@type)[1]', 'varchar(30)') AS [type]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[3]/@state)[1]', 'varchar(30)') AS [state]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[3]/@reversed)[1]', 'int') AS [reserved]
       ,CAST(record AS XML).value('(//Record/ResourceMonitor/Effect)[3]', 'bigint') AS [Effect]
       ,CAST(record AS XML).value('(//Record/MemoryNode/ReservedMemory)[1]', 'bigint') AS [SQL_ReservedMemory_KB]
       ,CAST(record AS XML).value('(//Record/MemoryNode/CommittedMemory)[1]', 'bigint') AS [SQL_CommittedMemory_KB]
       ,CAST(record AS XML).value('(//Record/MemoryNode/AWEMemory)[1]', 'bigint') AS [SQL_AWEMemory]
       ,CAST(record AS XML).value('(//Record/MemoryNode/SinglePagesMemory)[1]', 'bigint') AS [SinglePagesMemory]
       ,CAST(record AS XML).value('(//Record/MemoryNode/MultiplePagesMemory)[1]', 'bigint') AS [MultiplePagesMemory]
       ,CAST(record AS XML).value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') AS [TotalPhysicalMemory_KB]
       ,CAST(record AS XML).value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [AvailablePhysicalMemory_KB]
       ,CAST(record AS XML).value('(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint') AS [TotalPageFile_KB]
       ,CAST(record AS XML).value('(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint') AS [AvailablePageFile_KB]
       ,CAST(record AS XML).value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') AS [TotalVirtualAddressSpace_KB]
       ,CAST(record AS XML).value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [AvailableVirtualAddressSpace_KB]
       ,CAST(record AS XML).value('(//Record/@id)[1]', 'bigint') AS [Record Id]
       ,CAST(record AS XML).value('(//Record/@type)[1]', 'varchar(30)') AS [Type]
       ,CAST(record AS XML).value('(//Record/@time)[1]', 'bigint') AS [Record Time]
       ,tme.ms_ticks AS [Current Time]
FROM    sys.dm_os_ring_buffers rbf
CROSS JOIN sys.dm_os_sys_info tme
WHERE   rbf.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR' --and cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') = 'RESOURCE_MEMPHYSICAL_LOW'
ORDER BY rbf.timestamp DESC;


DECLARE @total_buffer INT;

SELECT  @total_buffer = cntr_value
FROM    sys.dm_os_performance_counters
WHERE   RTRIM([object_name]) LIKE '%Buffer Manager'
        AND counter_name = 'Target Pages';

;
WITH    src
          AS (SELECT    database_id
                       ,db_buffer_pages = COUNT_BIG(*)
              FROM      sys.dm_os_buffer_descriptors
--WHERE database_id BETWEEN 5 AND 32766
GROUP BY                database_id)
    SELECT  [db_name] = CASE [database_id]
                          WHEN 32767 THEN 'Resource DB'
                          ELSE DB_NAME([database_id])
                        END
           ,db_buffer_pages
           ,db_buffer_MB = db_buffer_pages / 128
           ,db_buffer_percent = CONVERT(DECIMAL(6, 3), db_buffer_pages * 100.0 / @total_buffer)
    FROM    src
    ORDER BY db_buffer_MB DESC;


SELECT  *
FROM    sys.dm_os_memory_clerks
--ORDER BY pages_kb DESC
ORDER BY (single_pages_kb + multi_pages_kb + awe_allocated_kb) DESC;


WITH    src
          AS (SELECT    [Object] = o.name
                       ,[Type] = o.type_desc
                       ,[Index] = COALESCE(i.name, '')
                       ,[Index_Type] = i.type_desc
                       ,p.[object_id]
                       ,p.index_id
                       ,au.allocation_unit_id
              FROM      sys.partitions AS p
              INNER JOIN sys.allocation_units AS au ON p.hobt_id = au.container_id
              INNER JOIN sys.objects AS o ON p.[object_id] = o.[object_id]
              INNER JOIN sys.indexes AS i ON o.[object_id] = i.[object_id]
                                             AND p.index_id = i.index_id
              WHERE     au.[type] IN (1, 2, 3)
                        AND o.is_ms_shipped = 0)
    SELECT  src.[Object]
           ,src.[Type]
           ,src.[Index]
           ,src.Index_Type
           ,buffer_pages = COUNT_BIG(b.page_id)
           ,buffer_mb = COUNT_BIG(b.page_id) / 128
    FROM    src
    INNER JOIN sys.dm_os_buffer_descriptors AS b ON src.allocation_unit_id = b.allocation_unit_id
    WHERE   b.database_id = DB_ID()
    GROUP BY src.[Object]
           ,src.[Type]
           ,src.[Index]
           ,src.Index_Type
    ORDER BY buffer_pages DESC;



WITH    src
          AS (SELECT    [Object] = o.name
                       ,[Type] = o.type_desc
                       ,[Index] = COALESCE(i.name, '')
                       ,[Index_Type] = i.type_desc
                       ,p.[object_id]
                       ,p.index_id
                       ,au.allocation_unit_id
              FROM      sys.partitions AS p
              INNER JOIN sys.allocation_units AS au ON p.hobt_id = au.container_id
              INNER JOIN sys.objects AS o ON p.[object_id] = o.[object_id]
              INNER JOIN sys.indexes AS i ON o.[object_id] = i.[object_id]
                                             AND p.index_id = i.index_id
              WHERE     au.[type] IN (1, 2, 3)
                        AND o.is_ms_shipped = 0)
    SELECT  src.[Object]
           ,src.[Type]
           ,src.[Index]
           ,src.Index_Type
           ,buffer_pages = COUNT_BIG(b.page_id)
           ,buffer_mb = COUNT_BIG(b.page_id) / 128
    FROM    src
    INNER JOIN sys.dm_os_buffer_descriptors AS b ON src.allocation_unit_id = b.allocation_unit_id
    WHERE   b.database_id = DB_ID()
    GROUP BY src.[Object]
           ,src.[Type]
           ,src.[Index]
           ,src.Index_Type
    ORDER BY buffer_pages DESC;


SELECT  STasks.session_id
       ,SThreads.os_thread_id
       ,b.command
FROM    sys.dm_os_tasks AS STasks
INNER JOIN sys.dm_os_threads AS SThreads ON STasks.worker_address = SThreads.worker_address
LEFT OUTER JOIN sys.dm_exec_requests b ON STasks.session_id = b.session_id
WHERE   STasks.session_id IS NOT NULL
        AND command = 'RESOURCE MONITOR'
ORDER BY SThreads.os_thread_id;

--CPU delta calculator
DECLARE @curCPU INT
   ,@prevCPU INT
   ,@delta INT
   ,@msg VARCHAR(MAX);
SET @curCPU = 0;
SET @prevCPU = 0;

WHILE 1 = 1
BEGIN

    SELECT  @curCPU = SUM(cpu_time)
    FROM    sys.dm_exec_requests
    WHERE   command LIKE '%Resource%Monitor%';
    SET @delta = @curCPU - @prevCPU;
    SET @prevCPU = @curCPU;
    SET @msg = CAST(GETDATE() AS VARCHAR(20)) + ' -- delta in CPU in sec (wait time 60 sec, ignore first run): ' + CAST((@delta / 1000.00) AS VARCHAR(MAX));
    RAISERROR (@msg, 10, 1) WITH NOWAIT;
    WAITFOR DELAY '0:1:0';
END;