--DBCC SQLPERF(LOGSPACE);

--DBCC LOGINFO

--DBCC OPENTRAN

;
WITH    task_space_usage
          AS (
    -- SUM alloc/delloc pages
              SELECT    session_id
                       ,request_id
                       ,SUM(internal_objects_alloc_page_count) AS alloc_pages
                       ,SUM(internal_objects_dealloc_page_count) AS dealloc_pages
              FROM      sys.dm_db_task_space_usage WITH (NOLOCK)
              WHERE     session_id <> @@SPID
              AND internal_objects_alloc_page_count > 0
              GROUP BY  session_id
                       ,request_id)
    SELECT  TSU.session_id
           ,TSU.alloc_pages * 1.0 / 128 AS [internal object MB space]
           ,TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space]
           ,EST.text
           ,
       -- Extract statement from sql text
            ISNULL(NULLIF(SUBSTRING(EST.text, ERQ.statement_start_offset / 2, CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset THEN 0
                                                                                   ELSE (ERQ.statement_end_offset - ERQ.statement_start_offset) / 2
                                                                              END), ''), EST.text) AS [statement text]
           ,EQP.query_plan
    FROM    task_space_usage AS TSU
    INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK) ON TSU.session_id = ERQ.session_id
                                                         AND TSU.request_id = ERQ.request_id
    OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
    OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
    WHERE   EST.text IS NOT NULL
            OR EQP.query_plan IS NOT NULL
    ORDER BY 3 DESC;


SELECT  database_transaction_log_bytes_reserved
       ,session_id
FROM    sys.dm_tran_database_transactions AS tdt
INNER JOIN sys.dm_tran_session_transactions AS tst ON tdt.transaction_id = tst.transaction_id
WHERE   database_id = 2;



SELECT  tdt.database_transaction_log_bytes_reserved / 1024.00 / 1024
       ,tst.session_id
       ,t.[text]
       ,[statement] = COALESCE(NULLIF(SUBSTRING(t.[text], r.statement_start_offset / 2, CASE WHEN r.statement_end_offset < r.statement_start_offset THEN 0
                                                                                             ELSE (r.statement_end_offset - r.statement_start_offset) / 2
                                                                                        END), ''), t.[text])
FROM    sys.dm_tran_database_transactions AS tdt
INNER JOIN sys.dm_tran_session_transactions AS tst ON tdt.transaction_id = tst.transaction_id
LEFT OUTER JOIN sys.dm_exec_requests AS r ON tst.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
WHERE   tdt.database_id = 2
AND tdt.database_transaction_log_bytes_reserved > 0
ORDER BY 1 DESC;


;
WITH    s AS (SELECT    s.session_id
                       ,[pages] = SUM(s.user_objects_alloc_page_count + s.internal_objects_alloc_page_count)
              FROM      sys.dm_db_session_space_usage AS s
              GROUP BY  s.session_id
              HAVING    SUM(s.user_objects_alloc_page_count + s.internal_objects_alloc_page_count) > 0)
    SELECT  s.session_id
           ,s.[pages]
           ,t.[text]
           ,[statement] = COALESCE(NULLIF(SUBSTRING(t.[text], r.statement_start_offset / 2, CASE WHEN r.statement_end_offset < r.statement_start_offset THEN 0
                                                                                                 ELSE (r.statement_end_offset - r.statement_start_offset) / 2
                                                                                            END), ''), t.[text])
    FROM    s
    LEFT OUTER JOIN sys.dm_exec_requests AS r ON s.session_id = r.session_id
    OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
    ORDER BY s.[pages] DESC;