/*
SELECT  map_key ,
        map_value , *
FROM    sys.dm_xe_map_values
WHERE   name = N'latch_mode'
        AND map_value IN ( N'UP', N'SH' );


The allocation bitmap pages are the page free space (PFS), global allocation map (GAM), and shared global allocation map (SGAM) pages in the database. The first PFS page occupies PageID 1 of the database, the first GAM page occupies PageID 2, and the first SGAM page occupies PageID 3 in the database. After the first page, the PFS pages repeat every 8088 pages inside of the data file, the GAM pages repeat every 511,232 pages (every 3994MB known as a GAM interval), and the SGAM pages repeat every 511,232 + 1 pages in the database. 

When PAGELATCH contention exists on one of the allocation bitmap pages in the database, it is possible to reduce the contention on the in-memory pages by adding additional data files, with the same initial size and auto-growth configuration. This works because SQL Server uses a round-robin, proportional fill algorithm to stripe the writes across the data files. When multiple data files exist for a database, all of the writes to the files are striped to those files, with the writes to any particular file based on the proportion of free space that the file has to the total free space across all of the files: This means that writes are proportionally distributed to the files according to their free space, to ensure that they fill at the same time, irrespective of their size. Each of the data files has its own set of PFS, GAM, and SGAM pages, so as the writes move from file to file the page allocations to occur from different allocation bitmap pages spreading the work out across the files and reducing the contention on any individual page. 

NULL latch (NL):	Not used
KEEP latch (KP):	Have two purposes: to keep a page in the buffer cache while another latch is pl-
					aced upon it, and the second is to maintain reference counts.
SHARED latch(SH):	Taken out when a request to read the data page is received.
UPDATE latch(UP):	Milder than an EX latch, this allows reads but no writes on the page while being
					updated.
EXCLUSIVE latch(EX):Severe latch that allows no access to the page while being written. Only one 
					per page can be held.
DESTROY latch(DT):  Used to destroy a buffer and evict it from the cache (returning the page to the 
					free list).

Source: Professional SQL Server 2008 Internals and Troubleshooting
*/

IF EXISTS ( SELECT  *
            FROM    sys.server_event_sessions
            WHERE   name = 'MonitorTempdbContention' )
    DROP EVENT SESSION [MonitorTempdbContention] ON SERVER;
GO
CREATE EVENT SESSION MonitorTempdbContention ON SERVER
ADD EVENT sqlserver.latch_suspend_end
(   --there is a strict limit of 3000 characters on the length of the predicate for a single event in Extended Events
    WHERE ( database_id=2 AND duration>0 AND 
           (mode=2 OR mode=3) AND 
           (page_id<4 OR -- Initial allocation bitmap pages
               package0.divides_by_uint64(page_id, 8088) OR    --PFS pages
               package0.divides_by_uint64(page_id, 511232) OR  --GAM Pages
               page_id=511233 OR  --2nd SGAM page 4GB-8GB
               page_id=1022465 OR --3rd SGAM page 8GB-12GB
               page_id=1533697 OR --4th SGAM page 12GB-16GB
               page_id=2044929 OR --5th SGAM page 16GB-20GB
               page_id=2556161 OR --6th SGAM page 20GB-24GB
               page_id=3067393 OR --7th SGAM page 24GB-28GB
               page_id=3578625)   --8th SGAM page 28GB-32GB
           )
)
ADD TARGET package0.histogram --slots are rounded up to the next power of 2
(
   SET filtering_event_name=N'sqlserver.latch_suspend_end',--events filters to bucketize
       source=N'page_id',
       source_type=0 --0 for event, 1 for action (default)
),
ADD TARGET package0.event_file
(
	SET
		filename='<path>.xel',
		max_file_size=100,
		max_rollover_files=10,
		increment=5
)
WITH (STARTUP_STATE=ON);


/*
 * Start Event Session
 */
ALTER EVENT SESSION [MonitorTempdbContention]
ON SERVER
STATE=START


/****
 * Quering
 ****/
-- Querying the histogram target
SELECT  n.value('(value)[1]', 'bigint') AS page_id ,
        n.value('(@count)[1]', 'bigint') AS wait_count ,
        CASE WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) < 4
             THEN 'Initial'
             WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) % 8088 = 0
             THEN 'PFS'
             WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) % 511232 = 0
             THEN 'GAM'
             WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) = 511233
             THEN '2nd SGAM page 4GB-8GB'
             WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) = 1022465
             THEN '3rd SGAM page 8GB-12GB'
             WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) = 1533697
             THEN '4th SGAM page 12GB-16GB'
             WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) = 2044929
             THEN '5th SGAM page 16GB-20GB'
             WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) = 2556161
             THEN '6th SGAM page 20GB-24GB'
             WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) = 3067393
             THEN '7th SGAM page 24GB-28GB'
             WHEN CAST(n.value('(value)[1]', 'bigint') AS BIGINT) = 3578625
             THEN '8th SGAM page 28GB-32GB'
        END AS allocation_bitmap_pages
FROM    ( SELECT    CAST(target_data AS XML) target_data
          FROM      sys.dm_xe_sessions AS s
                    INNER JOIN sys.dm_xe_session_targets AS t ON s.address = t.event_session_address
          WHERE     s.name = N'MonitorTempdbContention'
                    AND t.target_name = N'histogram'
        ) AS tab
        CROSS APPLY target_data.nodes('HistogramTarget/Slot') AS q ( n );

--Querying the event_file target to aggregate wait duration
SELECT  SUM(n.value('(data[@name="duration"]/value)[1]', 'int')) AS duration
FROM    ( SELECT    CAST(event_data AS XML) AS event_data
          FROM      sys.fn_xe_file_target_read_file('<path>*xel',
                                                    NULL, NULL, NULL)
        ) AS tab
        CROSS APPLY event_data.nodes('event') AS q ( n )