#!/bin/bash

# Create project directory and subdirectories
mkdir -p postgresql_auditor
cd postgresql_auditor

# Create requirements.txt
cat > requirements.txt << 'EOL'
azure-identity
azure-mgmt-postgresqlflexibleservers
azure-mgmt-resource
psycopg2-binary
python-dotenv
EOL

# Create __init__.py
touch __init__.py

# Create config.py
cat > config.py << 'EOL'
from dataclasses import dataclass
from enum import Enum
from typing import Optional
from azure.identity import AzureAuthorityHosts

class Subscription(Enum):
    PROD = "AFC-HQAFC-AFCDSE-P"
    TEST = "AFC-HQAFC-AFCDSE-T"
    DEV = "AFC-HQAFC-AFCDSE-D"

@dataclass
class AzureConfig:
    subscription: Subscription
    server_name: str = "caz-w0cuaa-dse-p-psql-flex-xray1"
    authority: str = AzureAuthorityHosts.AZURE_GOVERNMENT
    
    @property
    def key_vault_name(self) -> str:
        vault_mapping = {
            Subscription.PROD: "CAZDSEPKEYAKS",
            Subscription.TEST: "KEYAFCDSEAKS",
            Subscription.DEV: "KEYAFCDSEDECOREAKS"
        }
        return vault_mapping[self.subscription]
EOL

# Create models.py
cat > models.py << 'EOL'
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class DatabasePermission:
    level: str
    database: str
    schema: Optional[str]
    table: Optional[str]
    grantee: str
    permissions: List[str]
EOL

# Create database.py
cat > database.py << 'EOL'
import psycopg2
from typing import List, Dict
from models import DatabasePermission
import logging

logger = logging.getLogger(__name__)

class PostgreSQLConnection:
    def __init__(self, connection_info: Dict[str, str]):
        self.connection_info = connection_info
        self.conn = None

    async def __aenter__(self):
        self.conn = psycopg2.connect(**self.connection_info)
        return self.conn

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.conn:
            self.conn.close()

class DatabasePermissionQueries:
    @staticmethod
    async def get_database_list(connection) -> List[str]:
        query = """
        SELECT datname FROM pg_database 
        WHERE datistemplate = false 
        AND datname NOT IN ('postgres', 'azure_maintenance');
        """
        with connection.cursor() as cursor:
            cursor.execute(query)
            return [row[0] for row in cursor.fetchall()]

    @staticmethod
    async def get_database_permissions(connection, database: str) -> List[DatabasePermission]:
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

    @staticmethod
    async def get_table_permissions(connection, database: str) -> List[DatabasePermission]:
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
EOL

# Create azure_client.py
cat > azure_client.py << 'EOL'
from azure.identity import InteractiveBrowserCredential
from azure.mgmt.postgresqlflexibleservers import PostgreSQLManagementClient
from azure.mgmt.resource.subscriptions import SubscriptionClient
from config import AzureConfig
import logging

logger = logging.getLogger(__name__)

class AzureClient:
    def __init__(self, config: AzureConfig):
        self.config = config
        self.credential = InteractiveBrowserCredential(authority=config.authority)
        self.postgresql_client = PostgreSQLManagementClient(
            credential=self.credential,
            subscription_id=config.subscription.value
        )

    async def initialize(self):
        """Verify subscription access and initialize clients"""
        client = SubscriptionClient(self.credential)
        subscriptions = [sub.subscription_id for sub in client.subscriptions.list()]
        if self.config.subscription.value not in subscriptions:
            raise ValueError(f"Subscription {self.config.subscription.value} not found")

    async def get_all_servers(self):
        """Get all PostgreSQL Flex servers in the subscription."""
        try:
            return list(self.postgresql_client.servers.list())
        except Exception as e:
            logger.error(f"Error listing servers: {str(e)}")
            raise
EOL

# Create auditor.py
cat > auditor.py << 'EOL'
from typing import List
from azure_client import AzureClient
from database import PostgreSQLConnection, DatabasePermissionQueries
from models import DatabasePermission
import logging

logger = logging.getLogger(__name__)

class PostgreSQLPermissionAuditor:
    def __init__(self, azure_client: AzureClient):
        self.azure_client = azure_client

    async def get_server_connection_info(self, server):
        try:
            admin_username = server.administrator_login
            admin_password = os.environ.get('PGPASSWORD')
            
            if not admin_password:
                raise ValueError("Admin password not found in environment variables")

            return {
                'host': server.fully_qualified_domain_name,
                'user': admin_username,
                'password': admin_password,
                'port': '5432',
                'sslmode': 'require'
            }
        except Exception as e:
            logger.error(f"Error getting connection info for server {server.name}: {str(e)}")
            raise

    async def audit_server_permissions(self, server) -> List[DatabasePermission]:
        all_permissions = []
        try:
            conn_info = await self.get_server_connection_info(server)
            
            async with PostgreSQLConnection(conn_info) as connection:
                databases = await DatabasePermissionQueries.get_database_list(connection)
                
                for database in databases:
                    logger.info(f"Auditing database: {database}")
                    conn_info['database'] = database
                    
                    async with PostgreSQLConnection(conn_info) as db_connection:
                        db_permissions = await DatabasePermissionQueries.get_database_permissions(
                            db_connection, database)
                        table_permissions = await DatabasePermissionQueries.get_table_permissions(
                            db_connection, database)
                        
                        all_permissions.extend(db_permissions)
                        all_permissions.extend(table_permissions)
            
            return all_permissions
            
        except Exception as e:
            logger.error(f"Error auditing server {server.name}: {str(e)}")
            raise
EOL

# Create main.py
cat > main.py << 'EOL'
import asyncio
import csv
from datetime import datetime
from config import AzureConfig, Subscription
from azure_client import AzureClient
from auditor import PostgreSQLPermissionAuditor
import logging

logging.basicConfig(level=logging.INFO, 
                   format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

async def main():
    config = AzureConfig(subscription=Subscription.PROD)
    azure_client = AzureClient(config)
    
    try:
        await azure_client.initialize()
        auditor = PostgreSQLPermissionAuditor(azure_client)
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_file = f'postgres_permissions_audit_{timestamp}.csv'
        
        servers = await azure_client.get_all_servers()
        
        with open(output_file, 'w', newline='') as csvfile:
            fieldnames = ['server_name', 'level', 'database', 'schema', 'table', 
                         'grantee', 'permissions', 'audit_timestamp']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            
            for server in servers:
                logger.info(f"Processing server: {server.name}")
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
        
        logger.info(f"Audit complete! Results written to {output_file}")
        
    except Exception as e:
        logger.error(f"Error during audit: {str(e)}")
        raise

if __name__ == "__main__":
    asyncio.run(main())
EOL

# Create README.md
cat > README.md << 'EOL'
# PostgreSQL Permission Auditor

This tool audits permissions across PostgreSQL Flexible Servers in Azure Government cloud.

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
