 DECLARE @LogPath SQL_VARIANT;
 SET @LogPath = (SELECT TOP 1 value FROM sys.fn_trace_getinfo (NULL) WHERE property = 2);
   
 SELECT tg.TextData
       ,tg.DatabaseName
       ,tg.Error
       ,tg.ObjectName
       ,tg.DatabaseName
       ,te.name
       ,tg.EventSubClass
       ,tg.NTUserName
       ,tg.NTDomainName
       ,tg.HostName
       ,tg.ApplicationName
       ,tg.SPID
       ,tg.Duration
       ,tg.StartTime
       ,tg.EndTime
       ,tg.Reads
       ,tg.Writes
       ,tg.CPU
 FROM   fn_trace_gettable(CAST(@LogPath AS VARCHAR(250)), DEFAULT) AS tg
 INNER JOIN sys.trace_events AS te ON tg.EventClass = te.trace_event_id;