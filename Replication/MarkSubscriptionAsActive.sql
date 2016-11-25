--STATUS OF THE SUBSCRIPTION: 0 = INACTIVE; 1 = SUBSCRIBED; 2 = ACTIVE

SELECT  *
FROM    distribution..MSsubscriptions;

--- based on the above values, run below statement
--- this can be run using SQLAgent job

IF EXISTS ( SELECT  1
            FROM    distribution..MSsubscriptions
            WHERE   status = 0 )
BEGIN
    UPDATE  distribution..MSsubscriptions
    SET     STATUS = 2
    WHERE   publisher_id = '--publisher_id -- will be integer --'
            AND publisher_db = '--publisher db name ---'
            AND publication_id = '--publication_id -- will be integer --'
            AND subscriber_id = '--subscriber_id -- will be integer ---'
            AND subscriber_db = '-- subscriber_db ---';
END;
ELSE
BEGIN
    PRINT 'The subscription is not INACTIVE ... you are good for now .... !!';
END;