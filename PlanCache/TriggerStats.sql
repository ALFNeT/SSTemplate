SELECT OBJECT_ID('<>','TR')

SELECT TOP 10
        *
FROM    sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE   qp.objectid = <>
        AND cp.objtype = 'Trigger';