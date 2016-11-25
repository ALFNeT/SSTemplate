SELECT TOP 20
        total_worker_time / execution_count AS AvgCPU ,
        total_worker_time AS TotalCPU ,
        CAST(ROUND(100.00 * total_worker_time / (SELECT SUM(total_worker_time)
                                                 FROM   sys.dm_exec_query_stats
                                                ),2) AS MONEY) AS PercentCPU ,
        total_elapsed_time / execution_count AS AvgDuration ,
        total_elapsed_time AS TotalDuration ,
        CAST(ROUND(100.00 * total_elapsed_time / (SELECT    SUM(total_elapsed_time)
                                                  FROM      sys.dm_exec_query_stats
                                                 ),2) AS MONEY) AS PercentDuration ,
        total_logical_reads / execution_count AS AvgReads ,
        total_logical_reads AS TotalReads ,
        CAST(ROUND(100.00 * total_logical_reads / (SELECT   SUM(total_logical_reads)
                                                   FROM     sys.dm_exec_query_stats
                                                  ),2) AS MONEY) AS PercentReads ,
        execution_count ,
        CAST(ROUND(100.00 * execution_count / (SELECT   SUM(execution_count)
                                               FROM     sys.dm_exec_query_stats
                                              ),2) AS MONEY) AS PercentExecutions ,
        executions_per_minute = CASE DATEDIFF(mi,creation_time,qs.last_execution_time)
                                  WHEN 0 THEN 0
                                  ELSE CAST((1.00 * execution_count / DATEDIFF(mi,creation_time,qs.last_execution_time)) AS MONEY)
                                END ,
        qs.creation_time AS plan_creation_time ,
        qs.last_execution_time ,
        SUBSTRING(st.text,(qs.statement_start_offset / 2) + 1,((CASE qs.statement_end_offset
                                                                  WHEN -1 THEN DATALENGTH(st.text)
                                                                  ELSE qs.statement_end_offset
                                                                END - qs.statement_start_offset) / 2) + 1) AS QueryText ,
        query_plan
FROM    sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
--WHERE   st.text NOT LIKE '%PerformanceDashboard%'
        --AND st.text NOT LIKE '%@QS%'
        --AND st.text NOT LIKE '%@cmdCommand%'
        --AND st.text NOT LIKE '%@QS%'
        --AND st.text NOT LIKE '%#QS%'
        --AND st.text NOT LIKE '%FETCH%'
		
--ORDER BY TotalCPU DESC;
--ORDER BY TotalDuration DESC; 
ORDER BY TotalReads DESC;
--ORDER BY execution_count DESC; 
--ORDER BY total_elapsed_time / execution_count DESC; 



SELECT TOP 50
        qs.total_worker_time / ( qs.execution_count ) AS [Avg CPU Time in mins] ,
        qs.total_elapsed_time / qs.execution_count AS AvgDuration,
        qs.execution_count ,
        qs.min_worker_time / 60000000 AS [Min CPU Time in mins] ,
        --qs.total_worker_time/qs.execution_count,
        SUBSTRING(qt.text, qs.statement_start_offset / 2,
                  ( CASE WHEN qs.statement_end_offset = -1
                         THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
                         ELSE qs.statement_end_offset
                    END - qs.statement_start_offset ) / 2) AS query_text ,
        dbname = DB_NAME(qt.dbid) ,
        OBJECT_NAME(qt.objectid) AS [Object name],
		qp.query_plan
FROM    sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
		CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE  qt.dbid = 6
AND qs.execution_count>100
AND qs.total_elapsed_time / qs.execution_count > 50
ORDER BY qs.execution_count desc,
[Avg CPU Time in mins] DESC