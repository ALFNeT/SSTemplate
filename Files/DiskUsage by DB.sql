SET NOCOUNT ON

--Check to see the temp table exists
IF EXISTS ( SELECT  NAME
            FROM    tempdb..sysobjects
            WHERE   NAME LIKE '#HoldforEachDB%' )
	--If So Drop it
    DROP TABLE #HoldforEachDB_size

--Recreate it
CREATE TABLE #HoldforEachDB_size
    (
      [DatabaseName] [NVARCHAR](75) COLLATE SQL_Latin1_General_CP1_CI_AS
                                    NOT NULL ,
      [Size] [DECIMAL] NOT NULL ,
      [Name] [NVARCHAR](75) COLLATE SQL_Latin1_General_CP1_CI_AS
                            NOT NULL ,
      [Filename] [NVARCHAR](255) COLLATE SQL_Latin1_General_CP1_CI_AS
                                 NOT NULL
	,
	)
ON  [PRIMARY]

IF EXISTS ( SELECT  NAME
            FROM    tempdb..sysobjects
            WHERE   NAME LIKE '#fixed_drives%' )
	--If So Drop it
    DROP TABLE #fixed_drives

--Recreate it
CREATE TABLE #fixed_drives
    (
      [Drive] [CHAR](1) COLLATE SQL_Latin1_General_CP1_CI_AS
                        NOT NULL ,
      [MBFree] [DECIMAL] NOT NULL
    )
ON  [PRIMARY]

--Insert rows from sp_MSForEachDB into temp table
INSERT  INTO #HoldforEachDB_size
        EXEC sp_MSforeachdb 'Select ''?'' as DatabaseName, 
                            Case When [?]..sysfiles.size * 8 / 1024 = 0 Then 1 Else [?]..sysfiles.size * 8 / 1024 End
                            AS size,[?]..sysfiles.name,
                            [?]..sysfiles.filename 
                            From [?]..sysfiles'

--Select all rows from temp table (the temp table will auto delete when the connection is gone.
INSERT  INTO #fixed_drives
        EXEC xp_fixeddrives

SELECT  @@Servername

PRINT '';

SELECT  RTRIM(CAST(DatabaseName AS VARCHAR(75))) AS DatabaseName ,
        Drive ,
        Filename ,
        CAST(Size AS INT) AS Size ,
        CAST(MBFree AS VARCHAR(10)) AS MB_Free
FROM    #HoldforEachDB_size
        INNER JOIN #fixed_drives ON LEFT(#HoldforEachDB_size.Filename, 1) = #fixed_drives.Drive
GROUP BY DatabaseName ,
        Drive ,
        MBFree ,
        Filename ,
        CAST(Size AS INT)
ORDER BY Drive ,
        Size DESC

PRINT '';

SELECT  Drive AS [Total Data Space Used |] ,
        CAST(SUM(Size) AS VARCHAR(10)) AS [Total Size] ,
        CAST(MBFree AS VARCHAR(10)) AS MB_Free
FROM    #HoldforEachDB_size
        INNER JOIN #fixed_drives ON LEFT(#HoldforEachDB_size.Filename, 1) = #fixed_drives.Drive
GROUP BY Drive ,
        MBFree

PRINT '';

SELECT  COUNT(DISTINCT RTRIM(CAST(DatabaseName AS VARCHAR(75)))) AS Database_Count
FROM    #HoldforEachDB_size

--Clean up
IF EXISTS ( SELECT  NAME
            FROM    tempdb..sysobjects
            WHERE   NAME LIKE '#HoldforEachDB%' )
	--If So Drop it
    DROP TABLE #HoldforEachDB_size