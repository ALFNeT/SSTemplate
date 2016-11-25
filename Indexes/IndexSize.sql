--Stats valid from
SELECT  sqlserver_start_time
FROM    sys.dm_os_sys_info;

--Index usage
SELECT  OBJECT_NAME(s.[object_id]) AS [OBJECT NAME]
       ,i.[name] AS [INDEX NAME]
       ,user_seeks
       ,user_scans
       ,user_lookups
       ,user_updates
       ,A.leaf_insert_count
       ,A.leaf_update_count
       ,A.leaf_delete_count
       ,o.create_date
FROM    sys.dm_db_index_usage_stats AS s
INNER JOIN sys.indexes AS i ON i.[object_id] = s.[object_id]
                               AND i.index_id = s.index_id
JOIN    sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL) A ON A.index_id = i.index_id
JOIN    sys.objects o ON o.object_id = i.object_id
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
ORDER BY s.user_scans
       ,s.user_seeks;


--Index Size
SELECT  SUM(x.IndexSizeKB / 1024) AS sizeMb
FROM    sys.dm_db_index_usage_stats AS s
INNER JOIN sys.indexes AS i ON i.[object_id] = s.[object_id]
                               AND i.index_id = s.index_id
JOIN    sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL) A ON A.index_id = i.index_id
                                                                       AND A.object_id = i.object_id
JOIN    (SELECT i.index_id
               ,SUM(s.[used_page_count]) * 8 AS IndexSizeKB
         FROM   sys.dm_db_partition_stats AS s
         INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
                                        AND s.[index_id] = i.[index_id]
         GROUP BY i.index_id) x ON x.index_id = i.index_id
JOIN    sys.objects o ON o.object_id = i.object_id
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
        AND s.user_scans < 100
        AND s.user_seeks < 100
        AND s.user_lookups < 100;

--Index Size more trustworthy option
SELECT  OBJECT_NAME(s.[object_id])
       ,i.name
       ,(8 * SUM(a.used_pages)) / 1024 AS [Indexsize(Mb)]
	   ,(8 * SUM(a.used_pages)) / 1024 / 1024 AS [Indexsize(Gb)]
FROM    sys.indexes AS i
JOIN    sys.partitions AS p ON p.object_id = i.object_id
                               AND p.index_id = i.index_id
JOIN    sys.allocation_units AS a ON a.container_id = p.partition_id
JOIN    sys.dm_db_index_usage_stats AS s ON i.[object_id] = s.[object_id]
                                            AND i.index_id = s.index_id
--WHERE   s.user_scans = 0
--        AND s.user_seeks = 0
--        AND s.user_lookups = 0
GROUP BY OBJECT_NAME(s.[object_id])
       ,i.name;


SELECT  name
       ,CAST((size / 128.0) AS INT) AS TotalSpaceInMB
       ,CAST((CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0) AS INT) AS UsedSpaceInMB
       ,CAST((size / 128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0) AS INT) AS FreeSpaceInMB
FROM    sys.database_files