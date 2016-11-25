SELECT  j.name,
        CONVERT(DATE, CAST(js.next_run_date AS VARCHAR(32)), 112) AS date,
        --dbo.msdb_time_readable(js.next_run_time) AS time,
        js.next_run_time,
        js.job_id
FROM    msdb..sysjobschedules js
INNER JOIN msdb..sysjobs j ON j.job_id = js.job_id
JOIN    msdb.dbo.sysschedules ss ON ss.schedule_id = js.schedule_id
WHERE   j.enabled = 1
        AND ss.enabled = 1
        AND js.next_run_time BETWEEN '20000' AND '50000'
        AND CONVERT(DATE, CAST(js.next_run_date AS VARCHAR(32)), 112) = '2016-11-12'
ORDER BY js.next_run_time;
--
SELECT  j.name,
        CONVERT(DATE, CAST(js.next_run_date AS VARCHAR(32)), 112) AS date,
        --dbo.msdb_time_readable(js.next_run_time) AS time,
        js.next_run_time,
        js.job_id
FROM    msdb..sysjobschedules js
INNER JOIN msdb..sysjobs j ON j.job_id = js.job_id
JOIN    msdb.dbo.sysschedules ss ON ss.schedule_id = js.schedule_id
WHERE   j.enabled = 1
        AND ss.enabled = 1
        AND js.next_run_time BETWEEN '10000' AND '20000'
        AND CONVERT(DATE, CAST(js.next_run_date AS VARCHAR(32)), 112) = '2016-11-12'
ORDER BY js.next_run_time;
