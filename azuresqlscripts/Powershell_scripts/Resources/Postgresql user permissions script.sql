Postgresql user permissions script

WITH server_permissions AS (
        SELECT 
            r.rolname, 
            'Server_Permissions' AS "Level", 
            r.rolsuper, 
            r.rolinherit,
            r.rolcreaterole, 
            r.rolcreatedb, 
            r.rolcanlogin,
            ARRAY(
                SELECT b.rolname
                FROM pg_catalog.pg_auth_members m
                JOIN pg_catalog.pg_roles b ON m.roleid = b.oid
                WHERE m.member = r.oid
            ) AS memberof,
            r.rolbypassrls
        FROM pg_catalog.pg_roles r
        WHERE r.rolname !~ '^pg_'
    ),
    
    db_ownership AS (
        SELECT 
            r.rolname, 
            'DB_Ownership' AS "Level", 
            d.datname
        FROM pg_catalog.pg_database d, pg_catalog.pg_roles r
        WHERE d.datdba = r.oid
    ),
    
    schema_permissions AS (
        SELECT
            'Schema Permissions' AS "Level",                
            r.rolname AS role_name,
            nspname AS schema_name,
            pg_catalog.has_schema_privilege(r.rolname, nspname, 'CREATE') AS create_grant,
            pg_catalog.has_schema_privilege(r.rolname, nspname, 'USAGE') AS usage_grant
        FROM pg_namespace pn, pg_catalog.pg_roles r
        WHERE array_to_string(nspacl, ',') LIKE '%' || r.rolname || '%' 
              AND nspowner > 1
    ),
    
    table_ownership AS (
        SELECT 
            'Table Ownership' AS "Level",
            tableowner, 
            schemaname, 
            tablename
        FROM pg_tables
        GROUP BY tableowner, schemaname, tablename
    ),
    
    object_permissions AS (
        SELECT  
            'Object Permissions' AS "Level",
            COALESCE(NULLIF(s[1], ''), 'public') AS rolname,
            n.nspname,
            relname, 
            CASE 
                WHEN relkind = 'm' THEN 'Materialized View'
                WHEN relkind = 'p' THEN 'Partitioned Table'
                WHEN relkind = 'S' THEN 'Sequence'
                WHEN relkind = 'I' THEN 'Partitioned Index'
                WHEN relkind = 'v' THEN 'View'
                WHEN relkind = 'i' THEN 'Index'
                WHEN relkind = 'c' THEN 'Composite Type'
                WHEN relkind = 't' THEN 'TOAST table'
                WHEN relkind = 'r' THEN 'Table'
                WHEN relkind = 'f' THEN 'Foreign Table'
            END AS "Object Type",
            s[2] AS privileges
        FROM 
            pg_class c
            JOIN pg_namespace n ON n.oid = relnamespace
            JOIN pg_roles r ON r.oid = relowner,
            UNNEST(COALESCE(relacl::text[], FORMAT('{%s=arwdDxt/%s}', rolname, rolname)::text[])) acl, 
            REGEXP_SPLIT_TO_ARRAY(acl, '=|/') s 
        WHERE relkind <> 'i' AND relkind <> 't'
    )   
    
    SELECT 
        "Level", 
        rolname AS "Role", 
        'N/A' AS "Object Name", 
        'N/A' AS "Schema Name", 
        'N/A' AS "DB Name", 
        'N/A' AS "Object Type", 
        'N/A' AS "Privileges", 
        rolsuper::text AS "Is SuperUser", 
        rolinherit::text,
        rolcreaterole::text, 
        rolcreatedb::text, 
        rolcanlogin::text,
        memberof::text,
        rolbypassrls::text 
    FROM server_permissions
    
    UNION
    
    SELECT 
        dow."Level", 
        dow.rolname,
        'N/A',  
        'N/A', 
        datname,
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A'
    FROM db_ownership AS dow 
    
    UNION
    
    SELECT
        "Level", 
        role_name, 
        'N/A', 
        schema_name, 
        'N/A', 
        'N/A',
        CASE 
            WHEN create_grant IS TRUE AND usage_grant IS TRUE THEN 'Usage+Create' 
            WHEN create_grant IS TRUE AND usage_grant IS FALSE THEN 'Create' 
            WHEN create_grant IS FALSE AND usage_grant IS TRUE THEN 'Usage' 
            ELSE 'None' 
        END, 
        'N/A', 
        'N/A', 
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A'
    FROM schema_permissions
    
    UNION
    
    SELECT 
        "Level", 
        tableowner, 
        tablename, 
        schemaname,
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A'
    FROM table_ownership
    
    UNION
    
    SELECT 
        "Level", 
        rolname, 
        relname,  
        nspname, 
        'N/A', 
        "Object Type", 
        privileges,
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A',
        'N/A'
    FROM object_permissions
    ORDER BY "Role";