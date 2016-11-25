SELECT SUM(pending_disk_io_count) AS [Number of pending I/Os] FROM sys.dm_os_schedulers 


SELECT *  FROM sys.dm_io_pending_io_requests



SELECT  wait_type ,
        waiting_tasks_count ,
        wait_time_ms
FROM    sys.dm_os_wait_stats
WHERE   wait_type LIKE 'PAGEIOLATCH%'
ORDER BY wait_type 


SELECT  database_id ,
        file_id ,
        io_stall ,
        io_pending_ms_ticks ,
        scheduler_address
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) t1 ,
        sys.dm_io_pending_io_requests AS t2
WHERE   t1.file_handle = t2.io_handle




SELECT TOP 50
        ( total_logical_reads / execution_count ) AS avg_logical_reads ,
        ( total_logical_writes / execution_count ) AS avg_logical_writes ,
        ( total_physical_reads / execution_count ) AS avg_phys_reads ,
        execution_count ,
        statement_start_offset AS stmt_start_offset ,
        sql_handle ,
        plan_handle,
		st.text,
		qp.query_plan
FROM    sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.execution_count DESC,( total_logical_reads + total_logical_writes ) DESC


Select 
    SUM (user_object_reserved_page_count)*8 as user_objects_kb, 
    SUM (internal_object_reserved_page_count)*8 as internal_objects_kb, 
    SUM (version_store_reserved_page_count)*8  as version_store_kb, 
    SUM (unallocated_extent_page_count)*8 as freespace_kb 
From sys.dm_db_file_space_usage 
Where database_id = 2