SET NOCOUNT ON;
GO
 
DECLARE @tableURI NVARCHAR(128);
DECLARE @tablesWithNodependencies TABLE
    (
      name NVARCHAR(128) ,
      dependency_count INT
    );
DECLARE c CURSOR LOCAL FAST_FORWARD
FOR
    SELECT  SCHEMA_NAME(schema_id) + '.' + name
    FROM    sys.tables;

OPEN c;

FETCH NEXT FROM c INTO @tableURI;
 
WHILE ( @@FETCH_STATUS = 0 )
    BEGIN

        INSERT  INTO @tablesWithNodependencies
                ( name ,
                  dependency_count
                )
                SELECT  @tableURI ,
                        COUNT(*)
                FROM    sys.dm_sql_referencing_entities(@tableURI, 'OBJECT'); 

        FETCH NEXT FROM c INTO @tableURI;
    END;

CLOSE c;
DEALLOCATE c;

SELECT  name ,
        dependency_count
FROM    @tablesWithNodependencies
ORDER BY dependency_count;