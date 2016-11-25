SELECT  IOS.index_id
       ,OBJECT_NAME(I.object_id) AS OBJECT_NAME
       ,I.name AS INDEX_NAME
       ,IOS.leaf_allocation_count AS PAGE_SPLIT_FOR_INDEX
       ,IOS.nonleaf_allocation_count PAGE_ALLOCATION_CAUSED_BY_PAGESPLIT
FROM    sys.dm_db_index_operational_stats(DB_ID(N'<db_name>'), NULL, NULL, NULL) IOS
JOIN    sys.indexes I ON IOS.index_id = I.index_id
JOIN    sys.objects O ON IOS.object_id = O.object_id
WHERE   O.type_desc = 'USER_TABLE'
ORDER BY PAGE_ALLOCATION_CAUSED_BY_PAGESPLIT DESC