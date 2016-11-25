/*
fast way to check the count of messages in a queue is to run this query is to look at the row count 
of the underlying the b-tree that stores the messages:
*/
--check message count
SELECT  p.rows
FROM    sys.objects AS o
JOIN    sys.partitions AS p ON p.object_id = o.object_id
JOIN    sys.objects AS q ON o.parent_object_id = q.object_id
WHERE   q.name = '<queuename>'
        AND p.index_id = 1

--Messages pending in transmission_queue:
SELECT  p.rows
FROM    sys.objects AS o
JOIN    sys.partitions AS p ON p.object_id = o.object_id
WHERE   o.name = 'sysxmitqueue'

--Total number of conversations in the database:
SELECT  p.rows
FROM    sys.objects AS o
JOIN    sys.partitions AS p ON p.object_id = o.object_id
WHERE   o.name = 'sysdesend'

/*
Note that all these will return a raw count, w/o concerning the state of individual messages or conversations. 
E.g if retention is turned on a queue, the retained messages will also be counted.
*/