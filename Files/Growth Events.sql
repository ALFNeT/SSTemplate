DECLARE @path nvarchar(260) = (
    SELECT REVERSE(SUBSTRING(REVERSE(path), CHARINDEX('\', REVERSE(path)), 260)) +'log.trc'
    FROM    sys.traces
    WHERE   is_default = 1)

SELECT gt.DatabaseID,
       gt.FileName,
       COUNT(*) AS NumberOfEvents,
       CASE WHEN te.name LIKE'%Grow' THEN 1 ELSE 0 END AS is_growth_event
FROM  sys.fn_trace_gettable(@path, DEFAULT) gt
JOIN sys.trace_events te ON gt.EventClass = te.trace_event_id
WHERE   te.name in ('Data File Auto Grow','Log File Auto Grow','Data File Auto Shrink','Log File Auto Shrink')
GROUP BY gt.DatabaseID,
       gt.FileName,
       te.name



--AutoGrow events from the default trace
DECLARE @path NVARCHAR(260);

SELECT 
   @path = REVERSE(SUBSTRING(REVERSE([path]), 
   CHARINDEX('\', REVERSE([path])), 260)) + N'log.trc'
FROM    sys.traces
WHERE   is_default = 1;

SELECT 
   DatabaseName,
   [FileName],
   SPID,
   Duration,
   StartTime,
   EndTime,
   FileType = CASE EventClass 
       WHEN 92 THEN 'Data'
       WHEN 93 THEN 'Log'
   END
FROM sys.fn_trace_gettable(@path, DEFAULT)
WHERE
   EventClass IN (92,93)
ORDER BY
   StartTime DESC;