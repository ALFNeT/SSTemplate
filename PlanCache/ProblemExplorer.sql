SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID('tempdb..#dm_exec_query_stats') IS NOT NULL
    DROP TABLE #dm_exec_query_stats;
CREATE TABLE #dm_exec_query_stats
    (
      [id] [INT] NOT NULL
                 IDENTITY(1, 1) ,
      [sql_handle] [VARBINARY](64) NOT NULL ,
      [statement_start_offset] [INT] NOT NULL ,
      [statement_end_offset] [INT] NOT NULL ,
      [plan_generation_num] [BIGINT] NOT NULL ,
      [plan_handle] [VARBINARY](64) NOT NULL ,
      [creation_time] [DATETIME] NOT NULL ,
      [last_execution_time] [DATETIME] NOT NULL ,
      [execution_count] [BIGINT] NOT NULL ,
      [total_worker_time] [BIGINT] NOT NULL ,
      [last_worker_time] [BIGINT] NOT NULL ,
      [min_worker_time] [BIGINT] NOT NULL ,
      [max_worker_time] [BIGINT] NOT NULL ,
      [total_physical_reads] [BIGINT] NOT NULL ,
      [last_physical_reads] [BIGINT] NOT NULL ,
      [min_physical_reads] [BIGINT] NOT NULL ,
      [max_physical_reads] [BIGINT] NOT NULL ,
      [total_logical_writes] [BIGINT] NOT NULL ,
      [last_logical_writes] [BIGINT] NOT NULL ,
      [min_logical_writes] [BIGINT] NOT NULL ,
      [max_logical_writes] [BIGINT] NOT NULL ,
      [total_logical_reads] [BIGINT] NOT NULL ,
      [last_logical_reads] [BIGINT] NOT NULL ,
      [min_logical_reads] [BIGINT] NOT NULL ,
      [max_logical_reads] [BIGINT] NOT NULL ,
      [total_clr_time] [BIGINT] NOT NULL ,
      [last_clr_time] [BIGINT] NOT NULL ,
      [min_clr_time] [BIGINT] NOT NULL ,
      [max_clr_time] [BIGINT] NOT NULL ,
      [total_elapsed_time] [BIGINT] NOT NULL ,
      [last_elapsed_time] [BIGINT] NOT NULL ,
      [min_elapsed_time] [BIGINT] NOT NULL ,
      [max_elapsed_time] [BIGINT] NOT NULL ,
      [query_hash] [BINARY](8) NULL ,
      [query_plan_hash] [BINARY](8) NULL ,
      [query_plan] [XML] NULL ,
      [query_plan_filtered] [NVARCHAR](MAX) NULL ,
      [text] [NVARCHAR](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS
                             NULL ,
      [text_filtered] [NVARCHAR](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS
                                      NULL
    );


WITH    queries ( [sql_handle], [statement_start_offset], [statement_end_offset], [plan_generation_num], [plan_handle], [creation_time], [last_execution_time], [execution_count], [total_worker_time], [last_worker_time], [min_worker_time], [max_worker_time], [total_physical_reads], [last_physical_reads], [min_physical_reads], [max_physical_reads], [total_logical_writes], [last_logical_writes], [min_logical_writes], [max_logical_writes], [total_logical_reads], [last_logical_reads], [min_logical_reads], [max_logical_reads], [total_clr_time], [last_clr_time], [min_clr_time], [max_clr_time], [total_elapsed_time], [last_elapsed_time], [min_elapsed_time], [max_elapsed_time], [query_hash], [query_plan_hash] )
          AS ( SELECT TOP 100
                        qs.[sql_handle] ,
                        qs.[statement_start_offset] ,
                        qs.[statement_end_offset] ,
                        qs.[plan_generation_num] ,
                        qs.[plan_handle] ,
                        qs.[creation_time] ,
                        qs.[last_execution_time] ,
                        qs.[execution_count] ,
                        qs.[total_worker_time] ,
                        qs.[last_worker_time] ,
                        qs.[min_worker_time] ,
                        qs.[max_worker_time] ,
                        qs.[total_physical_reads] ,
                        qs.[last_physical_reads] ,
                        qs.[min_physical_reads] ,
                        qs.[max_physical_reads] ,
                        qs.[total_logical_writes] ,
                        qs.[last_logical_writes] ,
                        qs.[min_logical_writes] ,
                        qs.[max_logical_writes] ,
                        qs.[total_logical_reads] ,
                        qs.[last_logical_reads] ,
                        qs.[min_logical_reads] ,
                        qs.[max_logical_reads] ,
                        qs.[total_clr_time] ,
                        qs.[last_clr_time] ,
                        qs.[min_clr_time] ,
                        qs.[max_clr_time] ,
                        qs.[total_elapsed_time] ,
                        qs.[last_elapsed_time] ,
                        qs.[min_elapsed_time] ,
                        qs.[max_elapsed_time] ,
                        qs.[query_hash] ,
                        qs.[query_plan_hash]
               FROM     sys.dm_exec_query_stats qs
			   /*
				CRITERIA
			   */

               --ORDER BY qs.total_worker_time DESC
			   --ORDER BY qs.total_elapsed_time DESC
               --ORDER BY qs.execution_count DESC
			   ORDER BY qs.total_logical_reads DESC
             )
    INSERT  INTO #dm_exec_query_stats
            ( [sql_handle] ,
              [statement_start_offset] ,
              [statement_end_offset] ,
              [plan_generation_num] ,
              [plan_handle] ,
              [creation_time] ,
              [last_execution_time] ,
              [execution_count] ,
              [total_worker_time] ,
              [last_worker_time] ,
              [min_worker_time] ,
              [max_worker_time] ,
              [total_physical_reads] ,
              [last_physical_reads] ,
              [min_physical_reads] ,
              [max_physical_reads] ,
              [total_logical_writes] ,
              [last_logical_writes] ,
              [min_logical_writes] ,
              [max_logical_writes] ,
              [total_logical_reads] ,
              [last_logical_reads] ,
              [min_logical_reads] ,
              [max_logical_reads] ,
              [total_clr_time] ,
              [last_clr_time] ,
              [min_clr_time] ,
              [max_clr_time] ,
              [total_elapsed_time] ,
              [last_elapsed_time] ,
              [min_elapsed_time] ,
              [max_elapsed_time] ,
              [query_hash] ,
              [query_plan_hash]
            )
            SELECT  qs.[sql_handle] ,
                    qs.[statement_start_offset] ,
                    qs.[statement_end_offset] ,
                    qs.[plan_generation_num] ,
                    qs.[plan_handle] ,
                    qs.[creation_time] ,
                    qs.[last_execution_time] ,
                    qs.[execution_count] ,
                    qs.[total_worker_time] ,
                    qs.[last_worker_time] ,
                    qs.[min_worker_time] ,
                    qs.[max_worker_time] ,
                    qs.[total_physical_reads] ,
                    qs.[last_physical_reads] ,
                    qs.[min_physical_reads] ,
                    qs.[max_physical_reads] ,
                    qs.[total_logical_writes] ,
                    qs.[last_logical_writes] ,
                    qs.[min_logical_writes] ,
                    qs.[max_logical_writes] ,
                    qs.[total_logical_reads] ,
                    qs.[last_logical_reads] ,
                    qs.[min_logical_reads] ,
                    qs.[max_logical_reads] ,
                    qs.[total_clr_time] ,
                    qs.[last_clr_time] ,
                    qs.[min_clr_time] ,
                    qs.[max_clr_time] ,
                    qs.[total_elapsed_time] ,
                    qs.[last_elapsed_time] ,
                    qs.[min_elapsed_time] ,
                    qs.[max_elapsed_time] ,
                    qs.[query_hash] ,
                    qs.[query_plan_hash]
            FROM    queries qs --left joining in case im adding more stuff
                    LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle
                                                              AND qs.plan_handle = qsCaught.plan_handle
                                                              AND qs.statement_start_offset = qsCaught.statement_start_offset
            WHERE   qsCaught.sql_handle IS NULL;


/* Populate the additional query_plan, text, and text_filtered fields */
UPDATE  #dm_exec_query_stats
SET     query_plan = qp.query_plan ,
        [text] = st.[text] ,
        text_filtered = SUBSTRING(st.text,
                                  ( qs.statement_start_offset / 2 ) + 1,
                                  ( ( CASE qs.statement_end_offset
                                        WHEN -1 THEN DATALENGTH(st.text)
                                        ELSE qs.statement_end_offset
                                      END - qs.statement_start_offset ) / 2 )
                                  + 1)
FROM    #dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp


--implicit conversions
SELECT  'implicit conversions' ,
        qs.query_plan ,
        qs.query_plan_filtered ,
        qs.execution_count ,
        qs.text
FROM    #dm_exec_query_stats qs
WHERE   COALESCE(qs.query_plan_filtered, CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%CONVERT_IMPLICIT%'
        AND COALESCE(qs.query_plan_filtered,
                     CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%PhysicalOp="Index Scan"%'
--implicit conversions affecting cardinality
UNION ALL
SELECT  'implicit conversions affecting cardinality' AS Finding ,
        qs.query_plan ,
        qs.query_plan_filtered ,
        qs.execution_count ,
        qs.text
FROM    #dm_exec_query_stats qs
WHERE   COALESCE(qs.query_plan_filtered, CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<PlanAffectingConvert ConvertIssue="Cardinality Estimate" Expression="CONVERT_IMPLICIT%'

--RIDs
UNION ALL
SELECT  'RID or Key Lookups' AS Finding ,
        qs.query_plan ,
        qs.query_plan_filtered ,
        qs.execution_count ,
        qs.text
FROM    #dm_exec_query_stats qs
WHERE   COALESCE(qs.query_plan_filtered, CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%Lookup="1"%'


DROP TABLE #dm_exec_query_stats;