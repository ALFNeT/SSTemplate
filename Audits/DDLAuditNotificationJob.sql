SET NOCOUNT ON;

DECLARE @sendMail BIT= 1 ,
    @job_id UNIQUEIDENTIFIER ,
    @job_run_datetime DATETIME ,
    @audit_file NVARCHAR(256);

/*
JOBID GLOBAL VARIABLE
	Get last run info for job, to get changes from last time the job run. if no info default to 5'
*/
SELECT @Job_ID = $(ESCAPE_NONE(JOBID)); --Parser hates this, only works under Agent's scope

SELECT  @job_run_datetime = CONVERT(DATETIME, RTRIM(run_date)) + ( ( run_time / 10000 * 3600 )
                                                               + ( ( run_time % 10000 ) / 100 * 60 )
                                                               + (   run_time % 10000 ) % 100 ) / ( 86399.9964 ) --some black magic to get when the job actually finished
FROM    msdb.dbo.sysjobs sj
        JOIN msdb.dbo.sysjobhistory sjh ON sjh.job_id = sj.job_id
WHERE   sj.job_id = @job_id;

IF @job_run_datetime IS NULL
    BEGIN	
		--Default if no job history
        --history can be affected by the Agent's history retention settings!!!
        SET @job_run_datetime = DATEADD(YY, -1, GETDATE()); --1 year
    END	

/*
    NEEDS audit_id if more than 1 audit enabled
*/
SELECT TOP 1 @audit_file = log_file_path + name + '_'+CONVERT(NVARCHAR(255),audit_guid)+'_*.sqlaudit'
FROM sys.server_file_audits
--WHERE audit_id = 



--	Send an email if there are any new rows since last time the job run
IF EXISTS ( SELECT  1
            FROM    fn_get_audit_file(@audit_file, DEFAULT, DEFAULT)
            WHERE   event_time > @job_run_datetime 
            --OTHER CRITERIAS CAN BE ADDED FOR MORE GRANULAR CONTROL
            --like: action_id,succeeded, OBJECT_ID, class_type,etc
            )
    AND @sendMail = 1
    BEGIN
		--	Send email -- FILLME
        EXEC msdb.dbo.sp_send_dbmail 
            @recipients = '', 
            @subject = '',
            @body = ''

    END
