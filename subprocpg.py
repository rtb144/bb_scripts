import subprocess
import json
import os
import csv
import logging
from datetime import datetime
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('postgres_audit.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class PostgreSQLPermissionAuditor:
    def __init__(self, subscription_id=None):
        """
        Initialize the auditor with optional subscription ID
        If not provided, uses currently active subscription
        """
        self.subscription_id = subscription_id or self._get_current_subscription()

    def _run_command(self, command, capture_output=True, text=True):
        """
        Helper method to run shell commands safely
        """
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=capture_output, 
                text=text, 
                check=True
            )
            return result
        except subprocess.CalledProcessError as e:
            logger.error(f"Command failed: {command}")
            logger.error(f"Error output: {e.stderr}")
            raise

    def _get_current_subscription(self):
        """
        Get currently active Azure subscription
        """
        try:
            result = self._run_command('az account show')
            account = json.loads(result.stdout)
            return account['id']
        except Exception as e:
            logger.error("Could not retrieve subscription ID")
            raise ValueError("Unable to determine subscription ID") from e

    def list_postgresql_servers(self):
        """
        List all PostgreSQL Flexible Servers in the subscription
        """
        try:
            list_cmd = f'az postgres flexible-server list --subscription {self.subscription_id}'
            result = self._run_command(list_cmd)
            return json.loads(result.stdout)
        except Exception as e:
            logger.error(f"Error listing PostgreSQL servers: {e}")
            return []

    def get_server_databases(self, server_name, resource_group):
        """
        Get list of databases for a server using psql
        """
        try:
            # Retrieve connection info
            conn_info = self._get_server_connection_info(server_name, resource_group)
            
            # Query to list databases
            query = "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres', 'azure_maintenance');"
            
            psql_cmd = (
                f'PGPASSWORD="{conn_info["password"]}" psql '
                f'-h {conn_info["host"]} '
                f'-U {conn_info["username"]} '
                f'-d postgres '
                f'-t -A -c "{query}"'
            )
            
            result = self._run_command(psql_cmd)
            return result.stdout.strip().split('\n')
        except Exception as e:
            logger.error(f"Error getting databases for {server_name}: {e}")
            return []

    def _get_server_connection_info(self, server_name, resource_group):
        """
        Retrieve server connection information
        Uses az postgres flexible-server show and requires admin credentials
        """
        try:
            show_cmd = (
                f'az postgres flexible-server show '
                f'--name {server_name} '
                f'--resource-group {resource_group}'
            )
            result = self._run_command(show_cmd)
            server_details = json.loads(result.stdout)
            
            # Retrieve admin credentials 
            # Note: In practice, use secure credential management
            admin_user = server_details.get('administratorLogin')
            
            # Password should be retrieved securely, 
            # e.g., from Azure Key Vault or environment variable
            admin_password = os.environ.get('POSTGRES_ADMIN_PASSWORD')
            
            if not admin_password:
                raise ValueError("Admin password not set in environment")
            
            return {
                'host': server_details['fullyQualifiedDomainName'],
                'username': admin_user,
                'password': admin_password
            }
        except Exception as e:
            logger.error(f"Error getting connection info for {server_name}: {e}")
            raise

    def get_database_permissions(self, server_name, resource_group, database):
        """
        Retrieve comprehensive database and table permissions
        """
        try:
            conn_info = self._get_server_connection_info(server_name, resource_group)
            
            # Comprehensive permission query
            permissions_query = """
            WITH 
            db_permissions AS (
                SELECT 
                    r.rolname AS grantee,
                    'DATABASE' AS permission_level,
                    d.datname AS database_name,
                    ARRAY_AGG(DISTINCT COALESCE(dp.privilege_type, 'NONE')) AS privileges
                FROM 
                    pg_database d
                    CROSS JOIN pg_roles r
                    LEFT JOIN aclexplode(d.datacl) dp ON dp.grantee = r.oid
                WHERE 
                    d.datname = current_database()
                GROUP BY r.rolname, d.datname
            ),
            table_permissions AS (
                SELECT 
                    r.rolname AS grantee,
                    'TABLE' AS permission_level,
                    schemaname,
                    tablename,
                    ARRAY_AGG(DISTINCT COALESCE(privilege_type, 'NONE')) AS privileges
                FROM 
                    information_schema.role_table_grants, 
                    pg_roles r
                WHERE 
                    grantee = r.rolname
                    AND schemaname NOT IN ('pg_catalog', 'information_schema')
                GROUP BY r.rolname, schemaname, tablename
            )
            SELECT 
                COALESCE(dp.permission_level, tp.permission_level) AS permission_level,
                COALESCE(dp.grantee, tp.grantee) AS grantee,
                dp.database_name,
                tp.schemaname,
                tp.tablename,
                COALESCE(dp.privileges, tp.privileges) AS privileges
            FROM 
                db_permissions dp
            FULL OUTER JOIN 
                table_permissions tp 
            ON dp.grantee = tp.grantee;
            """
            
            psql_cmd = (
                f'PGPASSWORD="{conn_info["password"]}" psql '
                f'-h {conn_info["host"]} '
                f'-U {conn_info["username"]} '
                f'-d {database} '
                f'-t -A -c "{permissions_query}"'
            )
            
            result = self._run_command(psql_cmd)
            return result.stdout.strip().split('\n')
        except Exception as e:
            logger.error(f"Error getting permissions for {database}: {e}")
            return []

    def audit_servers(self, output_file=None):
        """
        Comprehensive audit of all PostgreSQL servers
        """
        # Create default output filename if not provided
        if not output_file:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            output_file = f'postgres_permissions_audit_{timestamp}.csv'
        
        # Open CSV for writing
        with open(output_file, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            csv_writer.writerow([
                'Server Name', 'Resource Group', 'Database', 
                'Permission Level', 'Grantee', 'Schema', 'Table', 'Privileges'
            ])
            
            # Iterate through servers
            servers = self.list_postgresql_servers()
            for server in servers:
                server_name = server['name']
                resource_group = server['resourceGroup']
                
                logger.info(f"Auditing server: {server_name}")
                
                # Get databases for this server
                databases = self.get_server_databases(server_name, resource_group)
                
                # Audit each database
                for database in databases:
                    try:
                        permissions = self.get_database_permissions(
                            server_name, resource_group, database
                        )
                        
                        # Write permissions to CSV
                        for perm in permissions:
                            if perm.strip():  # Ensure not empty
                                parts = perm.split('|')
                                csv_writer.writerow([
                                    server_name, resource_group, database, *parts
                                ])
                    except Exception as e:
                        logger.error(f"Error processing {server_name} - {database}: {e}")
        
        logger.info(f"Audit complete. Results in {output_file}")
        return output_file

def main():
    # Prerequisite check
    try:
        # Verify Azure CLI and psql are installed
        subprocess.run(['az', '--version'], capture_output=True, check=True)
        subprocess.run(['psql', '--version'], capture_output=True, check=True)
    except FileNotFoundError:
        logger.error("Please install Azure CLI and PostgreSQL client (psql)")
        sys.exit(1)
    
    # Ensure password is set
    if not os.environ.get('POSTGRES_ADMIN_PASSWORD'):
        logger.error("Set POSTGRES_ADMIN_PASSWORD environment variable")
        sys.exit(1)
    
    # Run audit
    auditor = PostgreSQLPermissionAuditor()
    auditor.audit_servers()

if __name__ == '__main__':
    main()