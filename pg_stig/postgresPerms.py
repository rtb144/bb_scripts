import subprocess
import json
import csv
from datetime import datetime
import psycopg2
from typing import List, Dict, Any

def run_az_command(command: str) -> List[Dict[Any, Any]]:
    """Execute Azure CLI command and return JSON response."""
    try:
        result = subprocess.run(
            command.split(),
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {command}")
        print(f"Error message: {e.stderr}")
        return []

def get_database_permissions(connection, database: str) -> List[Dict[str, str]]:
    """Get database-level permissions."""
    permissions = []
    query = """
    SELECT 
        r.rolname as grantee,
        d.datname as database,
        ARRAY_AGG(DISTINCT dp.privilege_type) as privileges
    FROM 
        pg_database d
        CROSS JOIN pg_roles r
        LEFT JOIN pg_default_acl da ON da.defaclrole = r.oid
        LEFT JOIN aclexplode(d.datacl) dp ON dp.grantee = r.oid
    WHERE 
        d.datname = %s
    GROUP BY 
        r.rolname, d.datname;
    """
    
    with connection.cursor() as cursor:
        cursor.execute(query, (database,))
        rows = cursor.fetchall()
        
        for row in rows:
            permissions.append({
                'level': 'database',
                'grantee': row[0],
                'database': row[1],
                'permissions': row[2] if row[2] else []
            })
    
    return permissions

def get_table_permissions(connection, database: str) -> List[Dict[str, str]]:
    """Get table-level permissions."""
    permissions = []
    query = """
    SELECT 
        r.rolname as grantee,
        schemaname,
        tablename,
        ARRAY_AGG(DISTINCT privilege_type) as privileges
    FROM 
        pg_tables t
        CROSS JOIN pg_roles r
        LEFT JOIN information_schema.role_table_grants g 
            ON g.grantee = r.rolname 
            AND g.table_schema = t.schemaname 
            AND g.table_name = t.tablename
    WHERE 
        t.schemaname NOT IN ('pg_catalog', 'information_schema')
    GROUP BY 
        r.rolname, schemaname, tablename;
    """
    
    with connection.cursor() as cursor:
        cursor.execute(query)
        rows = cursor.fetchall()
        
        for row in rows:
            permissions.append({
                'level': 'table',
                'grantee': row[0],
                'schema': row[1],
                'table': row[2],
                'database': database,
                'permissions': row[3] if row[3] else []
            })
    
    return permissions

def main():
    # Get all PostgreSQL Flex servers
    servers = run_az_command('az postgres flexible-server list')
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = f'postgres_permissions_audit_{timestamp}.csv'
    
    with open(output_file, 'w', newline='') as csvfile:
        fieldnames = ['server_name', 'level', 'database', 'schema', 'table', 
                     'grantee', 'permissions', 'audit_timestamp']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for server in servers:
            server_name = server['name']
            print(f"\nProcessing server: {server_name}")
            
            # Get admin credentials
            admin_creds = run_az_command(
                f'az postgres flexible-server show-connection-string --server-name {server_name}'
            )
            
            if not admin_creds:
                print(f"Skipping server {server_name} - couldn't get credentials")
                continue
            
            try:
                # Parse connection string and connect
                conn_info = admin_creds['connectionStrings']['psql']
                # Note: You'll need to modify this based on your authentication method
                connection = psycopg2.connect(conn_info)
                
                # Get list of databases
                with connection.cursor() as cursor:
                    cursor.execute("""
                        SELECT datname FROM pg_database 
                        WHERE datistemplate = false;
                    """)
                    databases = [row[0] for row in cursor.fetchall()]
                
                # For each database, get permissions
                for database in databases:
                    print(f"Processing database: {database}")
                    
                    # Reconnect to specific database
                    connection.close()
                    conn_info_db = conn_info.replace('dbname=postgres', f'dbname={database}')
                    connection = psycopg2.connect(conn_info_db)
                    
                    # Get database permissions
                    db_permissions = get_database_permissions(connection, database)
                    for perm in db_permissions:
                        writer.writerow({
                            'server_name': server_name,
                            'level': perm['level'],
                            'database': perm['database'],
                            'schema': '',
                            'table': '',
                            'grantee': perm['grantee'],
                            'permissions': ','.join(perm['permissions']),
                            'audit_timestamp': timestamp
                        })
                    
                    # Get table permissions
                    table_permissions = get_table_permissions(connection, database)
                    for perm in table_permissions:
                        writer.writerow({
                            'server_name': server_name,
                            'level': perm['level'],
                            'database': perm['database'],
                            'schema': perm['schema'],
                            'table': perm['table'],
                            'grantee': perm['grantee'],
                            'permissions': ','.join(perm['permissions']),
                            'audit_timestamp': timestamp
                        })
                
                connection.close()
                
            except Exception as e:
                print(f"Error processing server {server_name}: {str(e)}")
                continue
    
    print(f"\nAudit complete! Results written to {output_file}")

if __name__ == "__main__":
    main()