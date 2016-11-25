--CREATE MESSAGE TYPE
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c03/RequestMessage]
VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c03/ResponseMessage]
VALIDATION = WELL_FORMED_XML;
--CREATE CONTRACT
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c03/HelloWorldContract]
(
[http://ssb.csharp.at/SSB_Book/c03/RequestMessage] SENT BY INITIATOR,
[http://ssb.csharp.at/SSB_Book/c03/ResponseMessage] SENT BY TARGET
);
GO

--CONTRACT INFO
SELECT  sc.name AS 'Contract'
       ,mt.name AS 'Message type'
       ,cm.is_sent_by_initiator
       ,cm.is_sent_by_target
       ,mt.validation
FROM    sys.service_contract_message_usages cm
INNER JOIN sys.service_message_types mt ON cm.message_type_id = mt.message_type_id
INNER JOIN sys.service_contracts sc ON sc.service_contract_id = cm.service_contract_id;
--CREATE QUEUE
CREATE QUEUE InitiatorQueue
WITH STATUS = ON;
CREATE QUEUE TargetQueue
WITH STATUS = ON;

--CREATE SERVICE
CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue
(
[http://ssb.csharp.at/SSB_Book/c03/HelloWorldContract]
);
GO
CREATE SERVICE TargetService
ON QUEUE TargetQueue
(
[http://ssb.csharp.at/SSB_Book/c03/HelloWorldContract]
);
GO
--SEND MESSAGE:

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @ch UNIQUEIDENTIFIER;
    DECLARE @msg NVARCHAR(MAX);
    BEGIN DIALOG CONVERSATION @ch
FROM SERVICE [InitiatorService]
TO SERVICE 'TargetService'
ON CONTRACT [http://ssb.csharp.at/SSB_Book/c03/HelloWorldContract]
WITH ENCRYPTION = OFF;
    SET @msg = '<HelloWorldRequest>
Klaus Aschenbrenner
</HelloWorldRequest>';
    SEND ON CONVERSATION @ch MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c03/RequestMessage]
(
@msg
);
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
END CATCH;
GO


--RECEIVE MESSAGE:
DECLARE @cg UNIQUEIDENTIFIER;
DECLARE @ch UNIQUEIDENTIFIER;
DECLARE @messagetypename NVARCHAR(256);
DECLARE @messagebody XML;
BEGIN TRY
    BEGIN TRANSACTION;
    RECEIVE TOP(1)
@cg = conversation_group_id,
@ch = conversation_handle,
@messagetypename = message_type_name,
@messagebody = CAST(message_body AS XML)
FROM TargetQueue
    PRINT 'Conversation group: ' + CAST(@cg AS NVARCHAR(MAX));
    PRINT 'Conversation handle: ' + CAST(@ch AS NVARCHAR(MAX));
    PRINT 'Message type: ' + @messagetypename;
    PRINT 'Message body: ' + CAST(@messagebody AS NVARCHAR(MAX));
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
END CATCH;
GO


--RECEIVE MESSAGE WAITFOR
DECLARE @cg UNIQUEIDENTIFIER;
DECLARE @ch UNIQUEIDENTIFIER;
DECLARE @messagetypename NVARCHAR(256);
DECLARE @messagebody XML;
BEGIN TRY
    BEGIN TRANSACTION;
    WAITFOR (
RECEIVE TOP (1)
@cg = conversation_group_id,
@ch = conversation_handle,
@messagetypename = message_type_name,
@messagebody = CAST(message_body AS XML)
FROM TargetQueue
), TIMEOUT 60000;
    IF (@@ROWCOUNT > 0)
    BEGIN
        PRINT 'Conversation group: ' + CAST(@cg AS NVARCHAR(MAX));
        PRINT 'Conversation handle: ' + CAST(@ch AS NVARCHAR(MAX));
        PRINT 'Message type: ' + @messagetypename;
        PRINT 'Message body: ' + CAST(@messagebody AS NVARCHAR(MAX));
    END;
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
END CATCH;
GO


--PROCESSING MESSAGES
--1.process the message and create a response message
--2.send the response message on the same conversation back to the initiating service

DECLARE @ch UNIQUEIDENTIFIER;
DECLARE @messagetypename NVARCHAR(256);
DECLARE @messagebody XML;
DECLARE @responsemessage XML;
BEGIN TRY
    BEGIN TRANSACTION;
        WAITFOR (
RECEIVE TOP (1)
@ch = conversation_handle,
@messagetypename = message_type_name,
@messagebody = CAST(message_body AS XML)
FROM TargetQueue
), TIMEOUT 60000;
        IF (@@ROWCOUNT > 0)
        BEGIN
            IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c03/RequestMessage')
            BEGIN
-- Store the received request message in a table
                INSERT  INTO ProcessedMessages
                        (ID
                        ,MessageBody
                        ,ServiceName)
                VALUES  (NEWID()
                        ,@messagebody
                        ,'TargetService');
-- Construct the response message
                SET @responsemessage = '<HelloWorldResponse>' + @messagebody.value('/HelloWorldRequest[1]', 'NVARCHAR(MAX)') + '</HelloWorldResponse>';
-- Send the response message back to the initiating service
                SEND ON CONVERSATION @ch MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c03/ResponseMessage]
(
@responsemessage
);
-- End the conversation on the target's side
                END CONVERSATION @ch;
            END;
        END;
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
    END CATCH;
GO


---------------

DECLARE @ch UNIQUEIDENTIFIER;
DECLARE @messagetypename NVARCHAR(256);
DECLARE @messagebody XML;
BEGIN TRY
    BEGIN TRANSACTION;
        WAITFOR (
RECEIVE TOP (1)
@ch = conversation_handle,
@messagetypename = message_type_name,
@messagebody = CAST(message_body AS XML)
FROM InitiatorQueue
), TIMEOUT 60000;
        IF (@@ROWCOUNT > 0)
        BEGIN
            IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c03/ResponseMessage')
            BEGIN
-- Store the received response message in a table
                INSERT  INTO ProcessedMessages
                        (ID
                        ,MessageBody
                        ,ServiceName)
                VALUES  (NEWID()
                        ,@messagebody
                        ,'InitiatorService');
            END;
            IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
            BEGIN
-- End the conversation on the initiator's side
                END CONVERSATION @ch;
            END;
        END;
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
    END CATCH;
GO
