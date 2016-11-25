DECLARE @t TABLE
    (OBJECT_ID INT
    ,INDEX_id INT
    ,ID INT)
INSERT  INTO @t
        SELECT  i.object_id
               ,i.index_id
               ,CAST(REVERSE(SUBSTRING(REVERSE(OBJECT_NAME([object_id])), 1, IIF(CHARINDEX('_', REVERSE(OBJECT_NAME(i.[object_id])), 1) - 1 < 0, 0, CHARINDEX('_', REVERSE(OBJECT_NAME(i.[object_id])), 1) - 1))) AS INT) AS ID
        FROM    sys.indexes i
        WHERE   ISNUMERIC(REVERSE(SUBSTRING(REVERSE(OBJECT_NAME(i.[object_id])), 1, IIF(CHARINDEX('_', REVERSE(OBJECT_NAME(i.[object_id])), 1) - 1 < 0, 0, CHARINDEX('_', REVERSE(OBJECT_NAME(i.[object_id])), 1) - 1)))) = 1

SELECT  ic.NAME
       ,(8 * SUM(a.used_pages)) / 1024 AS [Indexsize(Mb)]
FROM    @t AS i
JOIN    sys.partitions AS p ON p.object_id = i.OBJECT_ID
                               AND p.index_id = i.INDEX_id
JOIN    sys.allocation_units AS a ON a.container_id = p.partition_id
JOIN    sys.dm_db_index_usage_stats AS s ON i.[OBJECT_ID] = s.[object_id]
                                            AND i.INDEX_id = s.index_id
JOIN    ignite.COND ic ON i.ID = ic.ID
WHERE   i.ID < 100
GROUP BY ic.NAME;