EXEC sp_MSForEachDB 'SELECT ''?'' AS [Database Name], su1.name AS [Database User Name], su2.name AS [Database Role]
                  FROM [?].sys.database_role_members r
                     INNER JOIN [?]..sysusers su1 ON su1.[uid] = r.member_principal_id
                     INNER JOIN [?]..sysusers su2 ON su2.[uid] = r.role_principal_id
                  WHERE su2.name IN(''db_owner'') AND su1.name NOT IN(''dbo'')'