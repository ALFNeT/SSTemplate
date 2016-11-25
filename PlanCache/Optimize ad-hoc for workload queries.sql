--- for 2008 and up .. Optimize ad-hoc for workload
IF EXISTS (
        -- this is for 2008 and up
    SELECT  1
    FROM    sys.configurations
    WHERE   name = 'optimize for ad hoc workloads' )
    BEGIN
        DECLARE @AdHocSizeInMB DECIMAL(14, 2) ,
            @TotalSizeInMB DECIMAL(14, 2) ,
            @ObjType NVARCHAR(34)
 
        SELECT  @AdHocSizeInMB = SUM(CAST(( CASE WHEN usecounts = 1
                                                      AND LOWER(objtype) = 'adhoc'
                                                 THEN size_in_bytes
                                                 ELSE 0
                                            END ) AS DECIMAL(14, 2)))
                / 1048576 ,
                @TotalSizeInMB = SUM(CAST(size_in_bytes AS DECIMAL(14, 2)))
                / 1048576
        FROM    sys.dm_exec_cached_plans
 
        SELECT  'SQL Server Configuration' AS GROUP_TYPE ,
                ' Total cache plan size (MB): '
                + CAST(@TotalSizeInMB AS VARCHAR(MAX))
                + '. Current memory occupied by adhoc plans only used once (MB):'
                + CAST(@AdHocSizeInMB AS VARCHAR(MAX))
                + '.  Percentage of total cache plan occupied by adhoc plans only used once :'
                + CAST(CAST(( @AdHocSizeInMB / @TotalSizeInMB ) * 100 AS DECIMAL(14,
                                                              2)) AS VARCHAR(MAX))
                + '%' + ' ' AS COMMENTS ,
                ' '
                + CASE WHEN @AdHocSizeInMB > 200
                            OR ( ( @AdHocSizeInMB / @TotalSizeInMB ) * 100 ) > 25 -- 200MB or > 25%
                            THEN 'Switch on Optimize for ad hoc workloads as it will make a significant difference. Ref: http://sqlserverperformance.idera.com/memory/optimize-ad-hoc-workloads-option-sql-server-2008/. http://www.sqlskills.com/blogs/kimberly/post/procedure-cache-and-optimizing-for-adhoc-workloads.aspx'
                       ELSE 'Setting Optimize for ad hoc workloads will make little difference !!'
                  END + ' ' AS RECOMMENDATIONS
    END
 
 
SELECT  cp.* ,
        st.*
FROM    sys.dm_exec_cached_plans AS cp --CROSS JOIN sys.dm_exec_text_query_plan(cp.plan_handle) qp
        OUTER APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE   cp.usecounts = 1
        AND cp.objtype = 'Adhoc' ---AND cacheobjtype='Compiled Plan'
ORDER BY st.dbid ,
        st.text
 
SELECT  cp.objtype ,
        cp.cacheobjtype ,
        cp.usecounts ,
        st.text ,
        qp.query_plan ,
        *
FROM    sys.dm_exec_cached_plans cp
        OUTER APPLY sys.dm_exec_sql_text(cp.plan_handle) st
        OUTER APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
WHERE   st.text NOT LIKE '%dm_exec_cached_plans%'
        AND st.dbid = 6
        AND cp.objtype = 'Adhoc'
ORDER BY cp.usecounts DESC

SELECT TOP 100
        objtype ,
        p.size_in_bytes ,
        usecounts ,
        LEFT([sql].[text], 100) AS [text]
FROM    sys.dm_exec_cached_plans p
        OUTER APPLY sys.dm_exec_sql_text(p.plan_handle) sql
ORDER BY usecounts DESC


SELECT  objtype AS [CacheType] ,
        COUNT_BIG(*) AS [Total Plans] ,
        SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs] ,
        AVG(CAST(usecounts AS BIGINT)) AS [Avg Use Count] ,
        SUM(CAST(( CASE WHEN usecounts = 1 THEN size_in_bytes
                        ELSE 0
                   END ) AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs - USE Count 1] ,
        SUM(CASE WHEN usecounts = 1 THEN 1
                 ELSE 0
            END) AS [Total Plans - USE Count 1]
FROM    sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs - USE Count 1] DESC
GO 


DECLARE @MB DECIMAL(19, 3) ,
    @Count BIGINT ,
    @StrMB NVARCHAR(20)

SELECT  @MB = SUM(CAST(( CASE WHEN usecounts = 1
                                   AND objtype IN ( 'Adhoc', 'Prepared' )
                              THEN size_in_bytes
                              ELSE 0
                         END ) AS DECIMAL(12, 2))) / 1024 / 1024 ,
        @Count = SUM(CASE WHEN usecounts = 1
                               AND objtype IN ( 'Adhoc', 'Prepared' ) THEN 1
                          ELSE 0
                     END) ,
        @StrMB = CONVERT(NVARCHAR(20), @MB)
FROM    sys.dm_exec_cached_plans

IF @MB > 10
    BEGIN
        --DBCC FREESYSTEMCACHE('SQL Plans') 
        RAISERROR ('%s MB was allocated to single-use plan cache. Single-use plans have been cleared.', 10, 1, @StrMB)
    END
ELSE
    BEGIN
        RAISERROR ('Only %s MB is allocated to single-use plan cache – no need to clear cache now.', 10, 1, @StrMB)
                -- Note: this is only a warning message and not an actual error.
    END
GO 