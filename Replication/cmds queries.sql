SELECT  *
FROM    dbo.MSarticles
WHERE   article_id IN (SELECT   article_id
                       FROM     MSrepl_commands
                       WHERE    xact_seqno = <xact_seqno>); 

exec sp_browsereplcmds
@xact_seqno_start = '<xact_seqno>',
@xact_seqno_end = '<xact_seqno>' 
