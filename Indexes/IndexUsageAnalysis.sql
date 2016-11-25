-- Missing Index Script
SELECT TOP 25
        dm_mid.database_id AS DatabaseID
       ,dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) Avg_Estimated_Impact
       ,dm_migs.last_user_seek AS Last_User_Seek
       ,OBJECT_NAME(dm_mid.object_id, dm_mid.database_id) AS [TableName]
       ,'CREATE INDEX [IX_' + OBJECT_NAME(dm_mid.object_id, dm_mid.database_id) + '_' + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns, ''), ', ', '_'), '[', ''), ']', '') + CASE WHEN dm_mid.equality_columns IS NOT NULL
                                                                                                                                                                                                AND dm_mid.inequality_columns IS NOT NULL THEN '_'
                                                                                                                                                                                           ELSE ''
                                                                                                                                                                                      END + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns, ''), ', ', '_'), '[', ''), ']', '') + ']' + ' ON ' + dm_mid.statement + ' (' + ISNULL(dm_mid.equality_columns, '') + CASE WHEN dm_mid.equality_columns IS NOT NULL
                                                                                                                                                                                                                                                                                                                                                                                     AND dm_mid.inequality_columns IS NOT NULL THEN ','
                                                                                                                                                                                                                                                                                                                                                                                ELSE ''
                                                                                                                                                                                                                                                                                                                                                                           END + ISNULL(dm_mid.inequality_columns, '') + ')' + ISNULL(' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement
FROM    sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs ON dm_migs.group_handle = dm_mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid ON dm_mig.index_handle = dm_mid.index_handle
WHERE   dm_mid.database_id = DB_ID()
ORDER BY Avg_Estimated_Impact DESC;
GO
--Index usage
SELECT  OBJECT_NAME(S.[object_id]) AS [OBJECT NAME]
       ,I.[name] AS [INDEX NAME]
       ,user_seeks
       ,user_scans
       ,user_lookups
       ,user_updates
       ,A.leaf_insert_count
       ,A.leaf_update_count
       ,A.leaf_delete_count
FROM    sys.dm_db_index_usage_stats AS S
INNER JOIN sys.indexes AS I ON I.[object_id] = S.[object_id]
                               AND I.index_id = S.index_id
JOIN    sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL) A ON A.index_id = I.index_id
                                                                       AND A.object_id = I.object_id
WHERE   OBJECTPROPERTY(S.[object_id], 'IsUserTable') = 1
        AND OBJECT_NAME(S.[object_id]) = '<index_name>'
ORDER BY S.user_scans;


SELECT  *
FROM    sys.indexes AS S
WHERE   S.name = '<index_name>';


SELECT  *
FROM    sys.dm_db_index_operational_stats(6, 559757497, 16, NULL);

SELECT  *
FROM    sys.tables
WHERE   name = '<index_name>';


------------------------------------------------
SELECT  d.[object_id]
       ,s = OBJECT_SCHEMA_NAME(d.[object_id])
       ,o = OBJECT_NAME(d.[object_id])
       ,d.equality_columns
       ,d.inequality_columns
       ,d.included_columns
       ,s.unique_compiles
       ,s.user_seeks
       ,s.last_user_seek
       ,s.user_scans
       ,s.last_user_scan
INTO    #candidates
FROM    sys.dm_db_missing_index_details AS d
INNER JOIN sys.dm_db_missing_index_groups AS g ON d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats AS s ON g.index_group_handle = s.group_handle
WHERE   d.database_id = DB_ID()
        AND OBJECTPROPERTY(d.[object_id], 'IsMsShipped') = 0;

CREATE TABLE #planops
    (o INT
    ,i INT
    ,h VARBINARY(64)
    ,uc INT
    ,Scan_Ops INT
    ,Seek_Ops INT
    ,Update_Ops INT);
WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
INSERT #planops
SELECT o = COALESCE(T1.o, T2.o),
   i = COALESCE(T1.i, T2.i),
   h = COALESCE(T1.h, T2.h),
   uc = COALESCE(T1.uc, T2.uc),
   Scan_Ops = ISNULL(T1.Scan_Ops, 0),
   Seek_Ops = ISNULL(T1.Seek_Ops, 0),
   Update_Ops = ISNULL(T2.Update_Ops, 0)
FROM
  (
  SELECT o = i.object_id,
     i = i.index_id,
     h = t.plan_handle,
     uc = t.usecounts,
     Scan_Ops = SUM(CASE WHEN t.LogicalOp IN ('Index Scan', 'Clustered Index Scan') THEN 1 ELSE 0 END),
     Seek_Ops = SUM(CASE WHEN t.LogicalOp IN ('Index Seek', 'Clustered Index Seek') THEN 1 ELSE 0 END)
  FROM (
     SELECT 
       r.n.value('@LogicalOp', 'varchar(100)') AS LogicalOp,
       o.n.value('@Index', 'sysname') AS IndexName,
       pl.plan_handle,
       pl.usecounts
     FROM sys.dm_exec_cached_plans AS pl
       CROSS APPLY sys.dm_exec_query_plan(pl.plan_handle) AS p
       CROSS APPLY p.query_plan.nodes('//RelOp') AS r(n)
       CROSS APPLY r.n.nodes('*/Object') AS o(n)
     WHERE p.dbid = DB_ID()
     AND p.query_plan IS NOT NULL
   ) AS t
  INNER JOIN sys.indexes AS i
    ON t.IndexName = QUOTENAME(i.name)
  WHERE t.LogicalOp IN ('Index Scan', 'Clustered Index Scan', 'Index Seek', 'Clustered Index Seek') 
  AND EXISTS (SELECT 1 FROM #candidates AS c WHERE c.object_id = i.object_id)
  GROUP BY i.object_id,
       i.index_id,
       t.plan_handle,
       t.usecounts
  ) AS T1
FULL OUTER JOIN
  (
  SELECT o = i.object_id,
      i = i.index_id,
      h = t.plan_handle,
      uc = t.usecounts,
      Update_Ops = COUNT(*)
  FROM (
      SELECT 
    o.n.value('@Index', 'sysname') AS IndexName,
    pl.plan_handle,
    pl.usecounts
      FROM sys.dm_exec_cached_plans AS pl
    CROSS APPLY sys.dm_exec_query_plan(pl.plan_handle) AS p
    CROSS APPLY p.query_plan.nodes('//Update') AS r(n)
    CROSS APPLY r.n.nodes('Object') AS o(n)
      WHERE p.dbid = DB_ID()
      AND p.query_plan IS NOT NULL
    ) AS t
  INNER JOIN sys.indexes AS i
    ON t.IndexName = QUOTENAME(i.name)
  WHERE EXISTS 
  (
    SELECT 1 FROM #candidates AS c WHERE c.[object_id] = i.[object_id]
  )
  AND i.index_id > 0
  GROUP BY i.object_id,
    i.index_id,
    t.plan_handle,
    t.usecounts
  ) AS T2
ON T1.o = T2.o AND
   T1.i = T2.i AND
   T1.h = T2.h AND
   T1.uc = T2.uc;
;


SELECT [object_id], index_id, user_seeks, user_scans, user_lookups, user_updates 
INTO #indexusage
FROM sys.dm_db_index_usage_stats AS s
WHERE database_id = DB_ID()
AND EXISTS (SELECT 1 FROM #candidates WHERE [object_id] = s.[object_id]);

WITH    x AS (SELECT    c.[object_id]
                       ,potential_read_ops = SUM(c.user_seeks + c.user_scans)
                       ,[write_ops] = SUM(iu.user_updates)
                       ,[read_ops] = SUM(iu.user_scans + iu.user_seeks + iu.user_lookups)
                       ,[write:read ratio] = CONVERT(DECIMAL(18, 2), SUM(iu.user_updates) * 1.0 / SUM(iu.user_scans + iu.user_seeks + iu.user_lookups))
                       ,current_plan_count = po.h
                       ,current_plan_use_count = po.uc
              FROM      #candidates AS c
              LEFT OUTER JOIN #indexusage AS iu ON c.[object_id] = iu.[object_id]
              LEFT OUTER JOIN (SELECT   o
                                       ,h = COUNT(h)
                                       ,uc = SUM(uc)
                               FROM     #planops
                               GROUP BY o) AS po ON c.[object_id] = po.o
              GROUP BY  c.[object_id]
                       ,po.h
                       ,po.uc)
    SELECT  [object] = QUOTENAME(c.s) + '.' + QUOTENAME(c.o)
           ,c.equality_columns
           ,c.inequality_columns
           ,c.included_columns
           ,x.potential_read_ops
           ,x.write_ops
           ,x.read_ops
           ,x.[write:read ratio]
           ,x.current_plan_count
           ,x.current_plan_use_count
    FROM    #candidates AS c
    INNER JOIN x ON c.[object_id] = x.[object_id]
    ORDER BY x.[write:read ratio];