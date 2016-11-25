CREATE TABLE dbo.table_copy
(
  ... cols ...
)
ON [heap tables filegroup];

 -- script out indexes, constraints etc.

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; -- going full SQL-92 with this

BEGIN TRANSACTION;

INSERT dbo.table_copy(cols) WITH (TABLOCK) -- Shared locks are held until the end of the transaction under serializable
  SELECT cols FROM dbo.table;

 -- remove constraints etc.

EXEC sp_rename N'dbo.table', N'table_old_date', N'OBJECT';

EXEC sp_rename N'dbo.table_copy', N'table', N'OBJECT';

 -- add constraints etc.

COMMIT TRANSACTION;



--if everything looks good
--DROP TABLE dbo.table_old_date;




/*
Another option
*/

EXEC sp_rename N'dbo.table', N'table_old_date', N'OBJECT';

CREATE TABLE dbo.table
(
  ... cols ...
)
ON [heap tables filegroup];

 -- script out indexes, constraints etc.

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; -- going full SQL-92 with this

BEGIN TRANSACTION;

INSERT dbo.table(cols) WITH (TABLOCK)
  SELECT cols FROM dbo.table_old_date;

 -- add constraints etc from table_old_date.

COMMIT TRANSACTION;



--if everything looks good
--DROP TABLE dbo.table_old_date;