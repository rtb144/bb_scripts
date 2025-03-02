import asyncio
from azure.identity import DefaultAzureCredential
from azure.mgmt.rdbms.postgresql_flexibleserver import PostgreSQLManagementClient
from azure.mgmt.rdbms.postgresql_flexibleserver.models import Server
from azure.core.exceptions import ResourceNotFoundError
import psycopg2
from datetime import datetime
import csv
from typing import List, Dict, Any, Optional
import os
from dataclasses import dataclass
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class DatabasePermission:
    level: str
    database: str
    schema: Optional[str]
    table: Optional[str]
    grantee: str
    permissions: List[str]

class PostgreSQLPermissionAuditor:
    def __init__(self, subscription_id: str):
        self.credential = DefaultAzureCredential()
        self.subscription_id = subscription_id
        self.postgresql_client = PostgreSQLManagementClient(
            credential=self.credential,
            subscription_id=subscription_id
        )

    async def get_all_servers(self) -> List[Server]:
        """Get all PostgreSQL Flex servers in the subscription."""
        servers = []
        try:
            async for server in self.postgresql_client.servers.list():
                servers.append(server)
            return servers
        except Exception as e:
            logger.error(f"Error listing servers: {str(e)}")
            raise

    async def get_server_connection_info(self, server: Server) -> Dict[str, str]:
        """Get connection information for a server."""
        try:
            admin_username = server.administrator_login
            # Note: You'll need to provide the admin password securely
            # This could be from Key Vault or environment variables
            admin_password = os.environ.get('POSTGRES_ADMIN_PASSWORD')
            
            if not admin_password:
                raise ValueError("Admin password not found in environment variables")

            return {
                'host': server.fully_qualified_domain_name,
                'user': admin_username,
                'password': admin_password,
                'port': '5432',  # Default PostgreSQL port
                'sslmode': 'require'  # Azure requires SSL
            }
        except Exception as e:
            logger.error(f"Error getting connection info for server {server.name}: {str(e)}")
            raise

    def get_database_permissions(self, connection, database: str) -> List[DatabasePermission]:
        """Get database-level permissions."""
        permissions = []
        query = """
        SELECT 
            r.rolname as grantee,
            d.datname as database,
            ARRAY_AGG(DISTINCT COALESCE(dp.privilege_type, 'NONE')) as privileges
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
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(query, (database,))
                rows = cursor.fetchall()
                
                for row in rows:
                    permissions.append(DatabasePermission(
                        level='database',
                        database=row[1],
                        schema=None,
                        table=None,
                        grantee=row[0],
                        permissions=[p for p in row[2] if p != 'NONE']
                    ))
                
                return permissions
        except Exception as e:
            logger.error(f"Error getting database permissions for {database}: {str(e)}")
            raise

    def get_table_permissions(self, connection, database: str) -> List[DatabasePermission]:
        """Get table-level permissions."""
        permissions = []
        query = """
        WITH RECURSIVE
        schemas AS (
            SELECT n.nspname AS schema_name
            FROM pg_namespace n
            WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
        ),
        tables AS (
            SELECT 
                schemaname,
                tablename
            FROM 
                pg_tables
            WHERE 
                schemaname IN (SELECT schema_name FROM schemas)
        ),
        roles AS (
            SELECT rolname
            FROM pg_roles
            WHERE rolname NOT IN ('pg_signal_backend', 'rds_superuser', 'rdsadmin', 'rdsrepladmin')
        ),
        permissions AS (
            SELECT 
                r.rolname as grantee,
                t.schemaname,
                t.tablename,
                ARRAY_AGG(DISTINCT COALESCE(g.privilege_type, 'NONE')) as privileges
            FROM 
                tables t
                CROSS JOIN roles r
                LEFT JOIN information_schema.role_table_grants g 
                    ON g.grantee = r.rolname 
                    AND g.table_schema = t.schemaname 
                    AND g.table_name = t.tablename
            GROUP BY 
                r.rolname, t.schemaname, t.tablename
        )
        SELECT * FROM permissions;
        """
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(query)
                rows = cursor.fetchall()
                
                for row in rows:
                    permissions.append(DatabasePermission(
                        level='table',
                        database=database,
                        schema=row[1],
                        table=row[2],
                        grantee=row[0],
                        permissions=[p for p in row[3] if p != 'NONE']
                    ))
                
                return permissions
        except Exception as e:
            logger.error(f"Error getting table permissions for {database}: {str(e)}")
            raise

    async def audit_server_permissions(self, server: Server) -> List[DatabasePermission]:
        """Audit permissions for a single server."""
        all_permissions = []
        try:
            conn_info = await self.get_server_connection_info(server)
            
            # Connect to default database first to get list of databases
            connection = psycopg2.connect(
                host=conn_info['host'],
                user=conn_info['user'],
                password=conn_info['password'],
                port=conn_info['port'],
                database='postgres',
                sslmode=conn_info['sslmode']
            )
            
            # Get list of databases
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT datname FROM pg_database 
                    WHERE datistemplate = false 
                    AND datname NOT IN ('postgres', 'azure_maintenance');
                """)
                databases = [row[0] for row in cursor.fetchall()]
            
            connection.close()
            
            # Audit each database
            for database in databases:
                logger.info(f"Auditing database: {database}")
                connection = psycopg2.connect(
                    host=conn_info['host'],
                    user=conn_info['user'],
                    password=conn_info['password'],
                    port=conn_info['port'],
                    database=database,
                    sslmode=conn_info['sslmode']
                )
                
                # Get database permissions
                db_permissions = self.get_database_permissions(connection, database)
                all_permissions.extend(db_permissions)
                
                # Get table permissions
                table_permissions = self.get_table_permissions(connection, database)
                all_permissions.extend(table_permissions)
                
                connection.close()
            
            return all_permissions
            
        except Exception as e:
            logger.error(f"Error auditing server {server.name}: {str(e)}")
            raise

async def main():
    # Get subscription ID from environment variable
    subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
    if not subscription_id:
        raise ValueError("AZURE_SUBSCRIPTION_ID environment variable not set")
    
    auditor = PostgreSQLPermissionAuditor(subscription_id)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = f'postgres_permissions_audit_{timestamp}.csv'
    
    try:
        servers = await auditor.get_all_servers()
        
        with open(output_file, 'w', newline='') as csvfile:
            fieldnames = ['server_name', 'level', 'database', 'schema', 'table', 
                         'grantee', 'permissions', 'audit_timestamp']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            
            for server in servers:
                logger.info(f"Processing server: {server.name}")
                try:
                    permissions = await auditor.audit_server_permissions(server)
                    
                    for perm in permissions:
                        writer.writerow({
                            'server_name': server.name,
                            'level': perm.level,
                            'database': perm.database,
                            'schema': perm.schema or '',
                            'table': perm.table or '',
                            'grantee': perm.grantee,
                            'permissions': ','.join(perm.permissions),
                            'audit_timestamp': timestamp
                        })
                        
                except Exception as e:
                    logger.error(f"Error processing server {server.name}: {str(e)}")
                    continue
        
        logger.info(f"Audit complete! Results written to {output_file}")
        
    except Exception as e:
        logger.error(f"Error during audit: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main())