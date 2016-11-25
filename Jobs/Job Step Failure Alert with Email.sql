DECLARE @YourRecipients AS VARCHAR(1000) = '<email>'
   ,@YourMailProfileName AS VARCHAR(255) = 'Database Mail'
   ,@Msg AS VARCHAR(1000)
   ,@NumofFails AS SMALLINT
   ,@JobName AS VARCHAR(1000)
   ,@Subj AS VARCHAR(1000)
   ,@i AS SMALLINT = 1

---------------Fetch List of Step Errors------------
SELECT  *
INTO    #Errs
FROM    (SELECT RANK() OVER (PARTITION BY step_id ORDER BY step_id) rn
               ,ROW_NUMBER() OVER (PARTITION BY step_id ORDER BY run_date DESC, run_time DESC) ReverseTryOrder
               ,j.name job_name
               ,run_status
               ,step_id
               ,step_name
               ,[message]
         FROM   msdb.dbo.sysjobhistory h
         JOIN   msdb.dbo.sysjobs j ON j.job_id = h.job_id
         WHERE  instance_id > COALESCE((SELECT  MAX(instance_id)
                                        FROM    msdb.dbo.sysjobhistory
                                        WHERE   job_id = '<job_id>'
                                                AND step_id = 0), 0)
                AND h.job_id = '<job_id>') AS agg
WHERE   ReverseTryOrder = 1 ---Pick the last retry attempt of each step
        AND run_status <> 1
 -- show only those that didn't succeed 

SELECT  *
FROM    #Errs
SET @NumofFails = ISNULL(@@ROWCOUNT, 0)
---Stored here because we'll still need the rowcount after it's reset.


-------------------------If there are any failures assemble email and send ------------------------------------------------
IF @NumofFails <> 0
BEGIN

    DECLARE @PluralS AS CHAR(1) = CASE WHEN @NumofFails > 1 THEN 's'
                                       ELSE ''
                                  END ---To make it look like a computer knows English
    SELECT TOP 1
            @Subj = 'Job: ' + job_name + ' had ' + CAST(@NumofFails AS VARCHAR(3)) + ' step' + @PluralS + ' that failed'
           ,@Msg = 'The trouble is... ' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
    FROM    dbo.#Errs

    WHILE @i <= @NumofFails
    BEGIN
        SELECT  @Msg = @Msg + 'Step:' + CAST(step_id AS VARCHAR(3)) + ': ' + step_name + CHAR(13) + CHAR(10) + [message] + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
        FROM    dbo.#Errs
        WHERE   rn = @i

        SET @i = @i + 1
    END

    EXEC msdb.dbo.sp_send_dbmail
        @recipients = @YourRecipients
       ,@subject = @Subj
       ,@profile_name = @YourMailProfileName
       ,@body = @Msg

END