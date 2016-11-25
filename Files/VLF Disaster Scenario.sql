--CONNECT to the test server instance
USE master
GO

IF EXISTS ( SELECT  name
            FROM    sys.databases
            WHERE   name = 'vlf' )
    BEGIN
        DROP DATABASE vlf --(if you need to)
    END

--create a database on the root of C with a small starting log size
--which then grows in small increments
CREATE DATABASE vlf ON (
	NAME = vlf
	,FILENAME = '<path>\vlf.mdf'
	) LOG ON (
	NAME = vlf_log
	,FILENAME = '<path>\vlf_log.ldf'
	,SIZE = 1 MB
	,MAXSIZE = 5 GB
	,FILEGROWTH = 1 MB
	)
GO

USE vlf
GO

--create a dummy table to fill up
CREATE TABLE vlf_test
    (
      a INT IDENTITY(1, 1)
            NOT NULL ,
      b CHAR(8000) NOT NULL ,
      c INT NOT NULL
    )
GO

INSERT  vlf_test
VALUES  ( 'vlftest', 0 )
GO

--create a starting point of backups
BACKUP DATABASE vlf TO DISK = '<path>\vlf.bak'
WITH STATS = 1
GO

BACKUP LOG vlf TO DISK = '<path>\vlf1.bak'
GO

--open a 2nd new connection and open an explicit uncommitted transaction
--to ensure that the transaction log cannot truncate
USE vlf
GO

BEGIN TRAN

CREATE TABLE OPENTRAN ( OPENTRAN INT )
GO

--switch back to the first connection
--now run the following to grow the log to create lots of VLFs
--run until the log runs out of space - a convenient stopping point
USE vlf
GO

SET NOCOUNT ON
GO

DECLARE @x INT
DECLARE @a CHAR(8000)
DECLARE @b CHAR(8000)

SET @a = REPLICATE('a', 8000)
SET @b = REPLICATE('b', 8000)
SET @x = 1

WHILE 1 = 1
    BEGIN
        UPDATE  vlf_test
        SET     b = @b ,
                c = @x
        WHERE   a = 1

        UPDATE  vlf_test
        SET     b = @a
        WHERE   a = 1

        SET @x = @x + 2
    END
GO

--let this run until the log runs out of space
--on the 2nd connection, use dbcc loginfo to check how many VLFs you have
DBCC LOGINFO(vlf)

--when you have reached 5GB of log file with several thousands VLFs
--simulate a server disaster by cutting the power to the principal server
--alternatively you could just power off your server ungracefully
/*
SHUTDOWN WITH NOWAIT
*/
	--now restart the SQL service or power on the server