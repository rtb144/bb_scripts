
-- Get principals with perms
SELECT DISTINCT pr.principal_id, pr.name, pr.type_desc, 
    pr.authentication_type_desc, pe.state_desc, pe.permission_name
FROM sys.database_principals AS pr
JOIN sys.database_permissions AS pe
    ON pe.grantee_principal_id = pr.principal_id;


-- sp_who2: shows who is connected
sp_who2

--map role to usr principal
SELECT r.name role_principal_name, m.name AS member_principal_name
   FROM sys.database_role_members rm
   JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
   JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
   WHERE r.type = 'R' ORDER BY m.name;


-- Kill all connections except my SPID
DECLARE @kill varchar(8000) = '';

SELECT @kill = @kill + 'KILL ' + CONVERT(varchar(5), c.session_id) + ';'

FROM sys.dm_exec_connections AS c
JOIN sys.dm_exec_sessions AS s
    ON c.session_id = s.session_id
WHERE c.session_id <> @@SPID
--WHERE status = 'sleeping'
ORDER BY c.connect_time ASC

EXEC(@kill)

CREATE USER [thomas.c.wheetley.ctr@cloud.army.mil] FROM external provider
EXEC sp_addrolemember 'db_owner', [thomas.c.wheetley.ctr@cloud.army.mil]
GRANT VIEW DEFINITION TO [thomas.c.wheetley.ctr@cloud.army.mil]