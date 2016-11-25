SELECT DISTINCT
        [object_name] = SCHEMA_NAME(o.[schema_id]) + '.' + o.name
       ,o.type_desc
FROM    sys.dm_sql_referenced_entities('<object_name>', 'OBJECT') d
JOIN    sys.objects o ON d.referenced_id = o.[object_id]
ORDER BY o.type_desc;
GO