--Create Proc spGetTransSchemaOptions
-- Paul Ibison, 05 March 2007
-- Procedure to list the options selected when publishing an article in a transactional publication on SQL Server 2005. 
-- Needs to be run in the Published database.
-- Based on scripts by Bert Corderman (also on www.replicationanswers.com)
-- Modified 15th March 2007 to cater for articles existing in multiple publications
--@tablename varchar(200),
--@PublicationName varchar(200)
--as 
--declare @pubid int
--select @pubid = pubid from syspublications where [name] = @PublicationName



DECLARE @schema_option varbinary(2000) = 0x000000000803509F
--select @schema_option = schema_option from sysarticles where object_name(objid) = @tablename and pubid = @pubid
declare @t1 TABLE (ID bigint, Description nvarchar(2000))

if (select @schema_option & 0) > 0 insert into @t1(id, description) values (0, 'Disables scripting by the Snapshot Agent and uses creation_script.')
if (select @schema_option & 1) > 0 insert into @t1(id, description) values (1, 'Generates the object creation script (CREATE TABLE, CREATE PROCEDURE, and so on). This value is the default for stored procedure articles.')
if (select @schema_option & 2) > 0 insert into @t1(id, description) values (2, 'Generates the stored procedures that propagate changes for the article, if defined.')
if (select @schema_option & 4) > 0 insert into @t1(id, description) values (4, 'Identity columns are scripted using the IDENTITY property.')
if (select @schema_option & 8) > 0 insert into @t1(id, description) values (8, 'Replicate timestamp columns. If not set, timestamp columns are replicated as binary.')
if (select @schema_option & 16) > 0 insert into @t1(id, description) values (16, 'Generates a corresponding clustered index. Even if this option is not set, indexes related to primary keys and unique constraints are generated if they are already defined on a published table.')
if (select @schema_option & 32) > 0 insert into @t1(id, description) values (32, 'Converts user-defined data types (UDT) to base data types at the Subscriber. This option cannot be used when there is a CHECK or DEFAULT constraint on a UDT column, if a UDT column is part of the primary key, or if a computed column references a UDT column. Not supported for Oracle Publishers.')
if (select @schema_option & 64) > 0 insert into @t1(id, description) values (64, 'Generates corresponding nonclustered indexes. Even if this option is not set, indexes related to primary keys and unique constraints are generated if they are already defined on a published table.')
if (select @schema_option & 128) > 0 insert into @t1(id, description) values (128, 'Replicates primary key constraints. Any indexes related to the constraint are also replicated, even if options 0x10 and 0x40 are not enabled.')
if (select @schema_option & 256) > 0 insert into @t1(id, description) values (256, 'Replicates user triggers on a table article, if defined. Not supported for Oracle Publishers.')
if (select @schema_option & 512) > 0 insert into @t1(id, description) values (512, 'Replicates foreign key constraints. If the referenced table is not part of a publication, all foreign key constraints on a published table are not replicated. Not supported for Oracle Publishers.')
if (select @schema_option & 1024) > 0 insert into @t1(id, description) values (1024, 'Replicates check constraints. Not supported for Oracle Publishers.')
if (select @schema_option & 2048) > 0 insert into @t1(id, description) values (2048, 'Replicates defaults. Not supported for Oracle Publishers.')
if (select @schema_option & 4096) > 0 insert into @t1(id, description) values (4096, 'Replicates column-level collation. ')
if (select @schema_option & 8192) > 0 insert into @t1(id, description) values (8192, 'Replicates extended properties associated with the published article source object. Not supported for Oracle Publishers.')
if (select @schema_option & 16384) > 0 insert into @t1(id, description) values (16384, 'Replicates UNIQUE constraints. Any indexes related to the constraint are also replicated, even if options 0x10 and 0x40 are not enabled.')
if (select @schema_option & 32768) > 0 insert into @t1(id, description) values (32768, 'This option is not valid for SQL Server 2005 Publishers.')
if (select @schema_option & 65536) > 0 insert into @t1(id, description) values (65536, 'Replicates CHECK constraints as NOT FOR REPLICATION so that the constraints are not enforced during synchronization.')
if (select @schema_option & 131072) > 0 insert into @t1(id, description) values (131072, 'Replicates FOREIGN KEY constraints as NOT FOR REPLICATION so that the constraints are not enforced during synchronization.')
if (select @schema_option & 262144) > 0 insert into @t1(id, description) values (262144, 'Replicates filegroups associated with a partitioned table or index.')
if (select @schema_option & 524288) > 0 insert into @t1(id, description) values (524288, 'Replicates the partition scheme for a partitioned table. ')
if (select @schema_option & 1048576) > 0 insert into @t1(id, description) values (1048576, 'Replicates the partition scheme for a partitioned index.')
if (select @schema_option & 2097152) > 0 insert into @t1(id, description) values (2097152, 'Replicates table statistics.')
if (select @schema_option & 4194304) > 0 insert into @t1(id, description) values (4194304, 'Default Bindings')
if (select @schema_option & 8388608) > 0 insert into @t1(id, description) values (8388608, 'Rule Bindings')
if (select @schema_option & 16777216) > 0 insert into @t1(id, description) values (16777216, 'Full-text index')
if (select @schema_option & 33554432) > 0 insert into @t1(id, description) values (33554432, 'XML schema collections bound to xml columns are not replicated.')
if (select @schema_option & 67108864) > 0 insert into @t1(id, description) values (67108864, 'Replicates indexes on xml columns.')
if (select @schema_option & 134217728) > 0 insert into @t1(id, description) values (134217728, 'Create any schemas not already present on the subscriber.')
if (select @schema_option & 268435456) > 0 insert into @t1(id, description) values (268435456, 'Converts xml columns to ntext on the Subscriber.')
if (select @schema_option & 536870912) > 0 insert into @t1(id, description) values (536870912, 'Converts large object data types introduced in SQL Server 2005 to data types supported on earlier versions of Microsoft SQL Server')
if (select @schema_option & 1073741824) > 0 insert into @t1(id, description) values (1073741824, 'Replicate permissions.')
if (select @schema_option & cast(2147483648 as bigint)) > 0 insert into @t1(id, description) values (2147483648, 'Attempt to drop dependencies to any objects that are not part of the publication.')

select * from @t1