select * 
from sys.dm_os_memory_cache_hash_tables
where name IN ( 'SystemRowsetStore' )
 
select * 
from sys.dm_os_memory_cache_counters
where name IN ( 'SystemRowsetStore' )


select * from sys.dm_os_spinlock_stats
ORDER BY spins desc

select * from sys.dm_os_spinlock_stats
where name = 'SOS_CACHESTORE'