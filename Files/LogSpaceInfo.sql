DBCC SQLPERF(logspace)

DBCC LOGINFO

DBCC OPENTRAN

SELECT  file_id ,
        name ,
        type_desc ,
        physical_name ,
        size ,
        max_size
FROM    sys.database_files;  
GO  

SELECT  ( size * 8.0 ) / 1024.0 AS size_in_mb ,
        CASE WHEN max_size = -1 THEN 9999999                  -- Unlimited growth, so handle this how you want
             ELSE ( max_size * 8.0 ) / 1024.0
        END AS max_size_in_mb
FROM    sys.database_files
WHERE   data_space_id = 0;   

SELECT  RTRIM(instance_name) + ' (used in kb)' ,
        cntr_value
FROM    sys.dm_os_performance_counters
WHERE   counter_name = 'Log File(s) Used Size (KB)'
        AND instance_name != '_Total';

SELECT  DB_NAME() AS DbName ,
        name AS FileName ,
        size / 128.0 AS CurrentSizeMB ,
        size / 128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0 AS FreeSpaceMB
FROM    sys.database_files; 

sp_helpdb archive

sp_spaceused 