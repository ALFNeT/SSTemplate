SELECT  obj = QUOTENAME(OBJECT_SCHEMA_NAME(p.object_id)) + '.' + QUOTENAME(OBJECT_NAME(p.object_id))
       ,referenced_by = QUOTENAME(r.referencing_schema_name) + '.' + QUOTENAME(r.referencing_entity_name)
       ,vs.aggregated_record_length_in_bytes AS size
FROM    sys.dm_tran_top_version_generators AS vs
INNER JOIN sys.partitions AS p ON vs.rowset_id = p.hobt_id
CROSS APPLY sys.dm_sql_referencing_entities(QUOTENAME(OBJECT_SCHEMA_NAME(p.object_id)) + '.' + QUOTENAME(OBJECT_NAME(p.object_id)), 'OBJECT') AS r
WHERE   vs.database_id = DB_ID()
        AND p.index_id IN (0, 1)
ORDER BY size DESC
       ,referenced_by;