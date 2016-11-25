--Tables without clustered indexes defined
WITH    CTE_1
          AS (SELECT    DB_NAME() AS dbname
                       ,o.name AS tablename
                       ,(SELECT SUM(p.rows)
                         FROM   sys.partitions p
                         WHERE  p.index_id = i.index_id
                                AND i.object_id = p.object_id) AS number_of_rows
              FROM      sys.indexes i
              INNER JOIN sys.objects o ON i.object_id = o.object_id
              WHERE     OBJECTPROPERTY(o.object_id, 'IsUserTable') = 1
                        AND OBJECTPROPERTY(o.object_id, 'TableHasClustIndex') = 0)
    SELECT  *
    FROM    CTE_1
    WHERE   number_of_rows > 1000;