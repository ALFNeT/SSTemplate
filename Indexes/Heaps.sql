/*
 * HEAP TABLES
-can not be defragmented to reduce space on disk. This matters because used data
    pages will be scattered throughout the MDF for example, because data has no 
    "order" from the clustered index
-non-clustered index now point to the row, not the clustered index entry. This 
    affects performance: Need for reaching data through clustered index with a 
    non-clustered index
*/

SELECT  o.name ,
        i.type_desc ,
        o.type_desc ,
        o.create_date
FROM    sys.indexes i
        INNER JOIN sys.objects o ON i.object_id = o.object_id
WHERE   o.type_desc = 'USER_TABLE'
        AND i.type_desc = 'HEAP'
ORDER BY o.name
GO




--Space used by heap tables
SELECT  t.name AS TableName ,
        p.rows AS RowCounts ,
        SUM(a.total_pages) * 8 AS TotalSpaceKB ,
        SUM(a.used_pages) * 8 AS UsedSpaceKB ,
        ( SUM(a.total_pages) - SUM(a.used_pages) ) * 8 AS UnusedSpaceKB
FROM    sys.tables t
        INNER JOIN sys.indexes i ON t.object_id = i.object_id
        INNER JOIN sys.objects o ON i.object_id = o.object_id
        INNER JOIN sys.partitions p ON i.object_id = p.object_id
                                       AND i.index_id = p.index_id
        INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
        LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE   t.name NOT LIKE 'dt%'
        AND t.is_ms_shipped = 0
        AND i.object_id > 255
        AND o.type_desc = 'USER_TABLE'
        AND i.type_desc = 'HEAP'
GROUP BY t.name ,
        s.name ,
        p.rows
ORDER BY [TotalSpaceKB] DESC


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT  QUOTENAME(SCHEMA_NAME([t].[schema_id])) + '.' + QUOTENAME([t].[name]) AS [Table]
       ,QUOTENAME(OBJECT_NAME([kc].[object_id])) AS [IndexName]
       ,CAST((SUM([a].[total_pages]) * 8 / 1024.0) AS DECIMAL(18, 2)) AS [IndexSizeMB]
FROM    [sys].[tables] [t]
INNER JOIN [sys].[indexes] [i] ON [t].[object_id] = [i].[object_id]
INNER JOIN [sys].[partitions] [p] ON [i].[object_id] = [p].[object_id]
                                     AND [i].[index_id] = [p].[index_id]
INNER JOIN [sys].[allocation_units] [a] ON [a].[container_id] = CASE WHEN [a].[type] IN (1, 3) THEN [p].[hobt_id]
                                                                     WHEN [a].[type] = 2 THEN [p].[partition_id]
                                                                END
INNER JOIN [sys].[key_constraints] AS [kc] ON [t].[object_id] = [kc].[parent_object_id]
WHERE   ([i].[name] IS NOT NULL
         AND OBJECTPROPERTY([kc].[object_id], 'CnstIsNonclustKey') = 1 --Unique Constraint or Primary Key can qualify
         AND OBJECTPROPERTY([t].[object_id], 'TableHasClustIndex') = 0 --Make sure there's no Clustered Index, this is a valid design choice
         AND OBJECTPROPERTY([t].[object_id], 'TableHasPrimaryKey') = 1 --Make sure it has a Primary Key and it's not just a Unique Constraint
         AND OBJECTPROPERTY([t].[object_id], 'IsUserTable') = 1 --Make sure it's a user table because whatever, why not? We've come this far
         )
GROUP BY [t].[schema_id]
       ,[t].[name]
       ,OBJECT_NAME([kc].[object_id])
ORDER BY SUM([a].[total_pages]) * 8 / 1024.0 DESC;