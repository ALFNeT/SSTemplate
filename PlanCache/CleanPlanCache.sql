DECLARE @ConfiguredMemory DECIMAL(19, 3)
   ,@PhysicalMemory DECIMAL(19, 3)
   ,@MemoryInUse DECIMAL(19, 3)
   ,@SingleUsePlanCount BIGINT
   ,@Percent DECIMAL(6, 3)
   ,@WastedMB DECIMAL(19, 3); 

CREATE TABLE #ConfigurationOptions
    ([name] NVARCHAR(35)
    ,[minimum] INT
    ,[maximum] INT
    ,[config_value] INT				-- in bytes
    ,[run_value] INT				-- in bytes
     );
INSERT  #ConfigurationOptions
        EXEC ('sp_configure ''max server memory''');

SELECT  @ConfiguredMemory = run_value--/1024.00 
FROM    #ConfigurationOptions
WHERE   name = 'max server memory (MB)';

SELECT  @PhysicalMemory = total_physical_memory_kb / 1024
FROM    sys.dm_os_sys_memory;

SELECT  @MemoryInUse = physical_memory_in_use_kb / 1024
FROM    sys.dm_os_process_memory;

SELECT  @WastedMB = SUM(CAST((CASE WHEN usecounts = 1
                                        AND objtype IN ('Adhoc', 'Prepared') THEN size_in_bytes
                                   ELSE 0
                              END) AS DECIMAL(12, 2))) / 1024 / 1024
       ,@SingleUsePlanCount = SUM(CASE WHEN usecounts = 1
                                            AND objtype IN ('Adhoc', 'Prepared') THEN 1
                                       ELSE 0
                                  END)
       ,@Percent = @WastedMB / @MemoryInUse * 100
FROM    sys.dm_exec_cached_plans;

SELECT  @PhysicalMemory [TotalPhysicalMemory (MB)]
       ,@ConfiguredMemory [TotalConfiguredMemory (MB)]
       ,@ConfiguredMemory / @PhysicalMemory * 100 [MaxMemoryAvailableToSQLServer (%)]
       ,@MemoryInUse [MemoryInUseBySQLServer (MB)]
       ,@WastedMB [TotalSingleUsePlanCache (MB)]
       ,@SingleUsePlanCount TotalNumberOfSingleUsePlans
       ,@Percent [PercentOfConfiguredCacheWastedForSingleUsePlans (%)];


-----------------------------------------------------------------
-- Logic (in a job?) to decide whether or not to clear - using sproc...
-----------------------------------------------------------------

DECLARE @StrMB NVARCHAR(20)
   ,@StrPercent NVARCHAR(20);

SELECT  @StrMB = CONVERT(NVARCHAR(20), @WastedMB)
       ,@StrPercent = CONVERT(NVARCHAR(20), @Percent);

IF @Percent > 10
    OR @WastedMB > 1024
BEGIN
    DBCC FREESYSTEMCACHE('SQL Plans'); 
    RAISERROR ('%s MB (%s percent) was allocated to single-use plan cache. Single-use plans have been cleared.', 10, 1, @StrMB, @StrPercent);
END;
ELSE
BEGIN
    RAISERROR ('Only %s MB (%s percent) is allocated to single-use plan cache - no need to clear cache now.', 10, 1, @StrMB, @StrPercent);
			-- Note: this is only a warning message and not an actual error.
END;
GO
--CLEAN UP
DROP TABLE #ConfigurationOptions;
