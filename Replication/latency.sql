select TOP 1000 * from dbo.latency_history (NOLOCK)
WHERE subscriber='<subscriber_name>'
ORDER BY date_added DESC 


SELECT  h.agent_id
       ,undelivcmdsindistdb
FROM    distribution.dbo.MSdistribution_agents a WITH (NOLOCK)
JOIN    distribution.dbo.MSdistribution_history h WITH (NOLOCK) ON a.id = h.agent_id
JOIN    (SELECT s.agent_id
               ,maxagentvalue.[time]
               ,COUNT(1) AS undelivcmdsindistdb
         FROM   distribution.dbo.MSrepl_commands t (NOLOCK)
         JOIN   distribution.dbo.MSsubscriptions AS s (NOLOCK) ON (t.article_id = s.article_id
                                                                   AND t.publisher_database_id = s.publisher_database_id)
         JOIN   (SELECT hist.agent_id
                       ,MAX(hist.[time]) AS [time]
                       ,h.maxseq
                 FROM   distribution.dbo.MSdistribution_history hist (NOLOCK)
                 JOIN   (SELECT agent_id
                               ,ISNULL(MAX(xact_seqno), 0x0) AS maxseq
                         FROM   distribution.dbo.MSdistribution_history (NOLOCK)
                         GROUP BY agent_id) AS h ON (hist.agent_id = h.agent_id
                                                     AND h.maxseq = hist.xact_seqno)
                  --WHERE hist.agent_id = 10
                 GROUP BY hist.agent_id
                       ,h.maxseq) AS maxagentvalue ON maxagentvalue.agent_id = s.agent_id
         WHERE  xact_seqno > maxagentvalue.maxseq
         GROUP BY s.agent_id
               ,maxagentvalue.[time]) und ON a.id = und.agent_id
                                             AND und.[time] = h.[time]
ORDER BY und.undelivcmdsindistdb DESC;