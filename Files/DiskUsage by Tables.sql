WITH    spaceused
          AS (SELECT    sys.dm_db_partition_stats.object_id
                       ,reservedpages = SUM(reserved_page_count)
                       ,it_reservedpages = SUM(ISNULL(its.it_reserved_page_count, 0))
                       ,usedpages = SUM(used_page_count)
                       ,it_usedpages = SUM(ISNULL(its.it_used_page_count, 0))
                       ,pages = SUM(CASE WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
                                         ELSE lob_used_page_count + row_overflow_used_page_count
                                    END)
                       ,row_Count = SUM(CASE WHEN (index_id < 2) THEN row_count
                                             ELSE 0
                                        END)
              FROM      sys.dm_db_partition_stats
              JOIN      sys.objects ON sys.objects.object_id = sys.dm_db_partition_stats.object_id
              OUTER APPLY (SELECT   reserved_page_count AS it_reserved_page_count
                                   ,used_page_count AS it_used_page_count
                           FROM     sys.internal_tables AS it
                           WHERE    it.parent_id = object_id
                                    AND it.internal_type IN (202, 204, 211, 212, 213, 214, 215, 216)
                                    AND object_id = it.object_id) AS its
              WHERE     sys.objects.type IN ('U', 'V')
              GROUP BY  sys.dm_db_partition_stats.object_id)
    SELECT  name = OBJECT_NAME(object_id)
           ,rows = CONVERT (CHAR(11), row_Count)
           ,reserved = LTRIM(STR(reservedpages * 8, 15, 0) + ' KB')
           ,it_reserved = LTRIM(STR(it_reservedpages * 8, 15, 0) + ' KB')
           ,tot_reserved = LTRIM(STR((reservedpages + it_reservedpages) * 8, 15, 0) + ' KB')
           ,data = LTRIM(STR(pages * 8, 15, 0) + ' KB')
           ,data_MB = LTRIM(STR((pages * 8) / 1000.0, 15, 0) + ' MB')
           ,index_size = LTRIM(STR((CASE WHEN usedpages > pages THEN (usedpages - pages) ELSE 0 END) * 8, 15, 0) + ' KB')
           ,it_index_size = LTRIM(STR((CASE WHEN it_usedpages > pages THEN (it_usedpages - pages) ELSE 0 END) * 8, 15, 0) + ' KB')
           ,tot_index_size = LTRIM(STR((CASE WHEN (usedpages + it_usedpages) > pages THEN ((usedpages + it_usedpages) - pages) ELSE 0 END) * 8, 15, 0) + ' KB')
           ,unused = LTRIM(STR((CASE WHEN reservedpages > usedpages THEN (reservedpages - usedpages) ELSE 0 END) * 8, 15, 0) + ' KB')
    FROM    spaceused
    ORDER BY pages DESC;