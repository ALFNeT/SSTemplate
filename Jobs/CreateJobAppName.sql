SELECT  + 'sqlserver.client_app_name = "'
        + 'SQLAgent – TSQL JobStep (Job 0x'
        + CONVERT(CHAR(32), CAST(j.job_id AS BINARY(16)), 2) + ' : Step '
        + CAST(js.step_id AS VARCHAR(3)) + ')" OR ' ,
        j.job_id ,
        j.name
FROM    msdb.dbo.sysjobs AS j
        INNER JOIN msdb.dbo.sysjobsteps AS js ON j.job_id = js.job_id
WHERE   j.name = @JobName;