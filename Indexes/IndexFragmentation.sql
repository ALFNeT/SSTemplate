--Index Fragmentation in current DB
SELECT  dbschemas.[name] AS 'Schema' ,
        dbtables.[name] AS 'Table' ,
        dbindexes.[name] AS 'Index' ,
        indexstats.avg_fragmentation_in_percent ,
        indexstats.page_count
FROM    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
        INNER JOIN sys.tables dbtables ON dbtables.[object_id] = indexstats.[object_id]
        INNER JOIN sys.schemas dbschemas ON dbtables.[schema_id] = dbschemas.[schema_id]
        INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
                                               AND indexstats.index_id = dbindexes.index_id
WHERE   indexstats.database_id = DB_ID()
ORDER BY indexstats.avg_fragmentation_in_percent DESC


--Disk usage of indexes
SELECT  OBJECT_NAME(i.object_id) AS TableName ,
        i.name AS IndexName ,
        i.index_id AS IndexID ,
        8 * SUM(a.used_pages) AS 'Indexsize(KB)'
FROM    sys.indexes AS i
        JOIN sys.partitions AS p ON p.object_id = i.object_id
                                    AND p.index_id = i.index_id
        JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
GROUP BY i.object_id ,
        i.index_id ,
        i.name
ORDER BY OBJECT_NAME(i.object_id) ,
        i.index_id

--Disk usage of DB
sp_spaceused
SELECT * FROM sys.dm_io_virtual_file_stats (NULL, NULL)
WHERE  database_id=6
