SELECT  OBJECT_NAME(ps.object_id, ps.database_id) AS ProcName
       ,ps.execution_count
       ,qs.plan_generation_num AS VersionOfPlan
       ,qs.execution_count AS ExecutionsOfCurrentPlan
       ,SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1, ((CASE qs.statement_end_offset
                                                                    WHEN -1 THEN DATALENGTH(st.text)
                                                                    ELSE qs.statement_end_offset
                                                                  END - qs.statement_start_offset) / 2) + 1) AS StatementText
       ,qp.query_plan
       ,qs.query_hash
       ,qs.query_plan_hash
       ,ps.cached_time
       ,ps.last_execution_time
       ,ps.execution_count
       ,ps.total_worker_time
       ,ps.last_worker_time
       ,ps.min_worker_time
       ,ps.max_worker_time
       ,ps.total_physical_reads
       ,ps.last_physical_reads
       ,ps.min_physical_reads
       ,ps.max_physical_reads
       ,ps.total_logical_writes
       ,ps.last_logical_writes
       ,ps.min_logical_writes
       ,ps.max_logical_writes
       ,ps.total_logical_reads
       ,ps.last_logical_reads
       ,ps.min_logical_reads
       ,ps.max_logical_reads
       ,ps.total_elapsed_time
       ,ps.last_elapsed_time
       ,ps.min_elapsed_time
       ,ps.max_elapsed_time
       ,qs.creation_time
       ,qs.last_execution_time
       ,qs.execution_count
       ,qs.total_worker_time
       ,qs.last_worker_time
       ,qs.min_worker_time
       ,qs.max_worker_time
       ,qs.total_physical_reads
       ,qs.last_physical_reads
       ,qs.min_physical_reads
       ,qs.max_physical_reads
       ,qs.total_logical_writes
       ,qs.last_logical_writes
       ,qs.min_logical_writes
       ,qs.max_logical_writes
       ,qs.total_logical_reads
       ,qs.last_logical_reads
       ,qs.min_logical_reads
       ,qs.max_logical_reads
       ,qs.total_clr_time
       ,qs.last_clr_time
       ,qs.min_clr_time
       ,qs.max_clr_time
       ,qs.total_elapsed_time
       ,qs.last_elapsed_time
       ,qs.min_elapsed_time
       ,qs.max_elapsed_time
       ,qs.total_rows
       ,qs.last_rows
       ,qs.min_rows
       ,qs.max_rows
FROM    sys.dm_exec_procedure_stats ps
JOIN    sys.dm_exec_query_stats qs ON qs.plan_handle = ps.plan_handle
CROSS APPLY sys.dm_exec_query_plan(ps.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(ps.plan_handle) st
WHERE   ps.database_id = 7
        AND OBJECT_NAME(ps.object_id, ps.database_id) LIKE '<proc_name>%'
--ORDER BY ps.execution_count DESC;
ORDER BY ProcName
       ,qs.statement_start_offset;



SELECT  OBJECT_NAME(ps.object_id, ps.database_id) AS ProcName
       ,ps.execution_count
       ,ps.total_worker_time
       ,ps.last_worker_time
       ,ps.min_worker_time
       ,ps.max_worker_time
       ,ps.total_physical_reads
       ,ps.last_physical_reads
       ,ps.min_physical_reads
       ,ps.max_physical_reads
       ,ps.total_logical_writes
       ,ps.last_logical_writes
       ,ps.min_logical_writes
       ,ps.max_logical_writes
       ,ps.total_logical_reads
       ,ps.last_logical_reads
       ,ps.min_logical_reads
       ,ps.max_logical_reads
       ,ps.total_elapsed_time
       ,ps.last_elapsed_time
       ,ps.min_elapsed_time
       ,ps.max_elapsed_time
FROM    sys.dm_exec_procedure_stats ps
WHERE   ps.database_id = 7
        AND OBJECT_NAME(ps.object_id, ps.database_id) LIKE '<proc_name>%';
