SELECT  step_name, message
FROM    msdb.dbo.sysjobhistory
WHERE   instance_id > COALESCE((SELECT MAX(instance_id) FROM msdb.dbo.sysjobhistory
                                WHERE job_id = $(ESCAPE_SQUOTE(JOBID)) AND step_id = 0), 0)
        AND job_id = $(ESCAPE_SQUOTE(JOBID))
        AND run_status <> 1 -- success

IF      @@ROWCOUNT <> 0
        RAISERROR('Ooops', 16, 1)