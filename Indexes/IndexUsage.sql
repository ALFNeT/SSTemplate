--Index usage
SELECT  OBJECT_NAME(S.[object_id]) AS [OBJECT NAME] ,
        I.[name] AS [INDEX NAME] ,
        user_seeks ,
        user_scans ,
        user_lookups ,
        user_updates ,
        A.leaf_insert_count ,
        A.leaf_update_count ,
        A.leaf_delete_count
FROM    sys.dm_db_index_usage_stats AS S
        INNER JOIN sys.indexes AS I ON I.[object_id] = S.[object_id]
                                       AND I.index_id = S.index_id
        JOIN sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL) A ON A.index_id = I.index_id
                                                              AND A.object_id = I.object_id
WHERE   OBJECTPROPERTY(S.[object_id], 'IsUserTable') = 1 
ORDER BY S.user_scans


---


SELECT  DS.name AS DataSpaceName
       ,AU.total_pages / 128 AS TotalSizeMB
       ,AU.used_pages / 128 AS UsedSizeMB
       ,AU.data_pages / 128 AS DataSizeMB
       ,OBJ.type_desc AS ObjectType
       ,OBJ.name AS ObjectName
       ,IDX.type_desc AS IndexType
       ,IDX.name AS IndexName
       ,s.user_seeks
       ,user_scans
       ,user_lookups
       ,pa.rows
FROM    sys.data_spaces AS DS
INNER JOIN sys.allocation_units AS AU ON DS.data_space_id = AU.data_space_id
INNER JOIN sys.partitions AS PA ON (AU.type IN (1, 3)
                                    AND AU.container_id = PA.hobt_id)
                                   OR (AU.type = 2
                                       AND AU.container_id = PA.partition_id)
INNER JOIN sys.objects AS OBJ ON PA.object_id = OBJ.object_id
INNER JOIN sys.schemas AS SCH ON OBJ.schema_id = SCH.schema_id
LEFT JOIN sys.indexes AS IDX ON PA.object_id = IDX.object_id
                                AND PA.index_id = IDX.index_id
JOIN    sys.dm_db_index_usage_stats s ON s.index_id = PA.index_id
                                         AND s.object_id = PA.object_id
WHERE   IDX.type_desc = 'NONCLUSTERED'
        --AND s.user_seeks < 100
        --AND s.user_scans < 100
        --AND s.user_lookups < 100