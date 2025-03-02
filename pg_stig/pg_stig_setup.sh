#!/bin/bash

# Create project directory structure
mkdir -p postgres_stig_audit/{src,config,templates,results}
cd postgres_stig_audit

# Create requirements.txt
cat > requirements.txt << 'EOL'
psycopg2-binary
azure-identity
azure-keyvault-secrets
python-dotenv
EOL

# Create src/__init__.py
touch src/__init__.py

# Create src/db_checks.py
cat > src/db_checks.py << 'EOL'
from dataclasses import dataclass
from typing import List, Dict, Any
import logging

logger = logging.getLogger(__name__)

@dataclass
class CheckResult:
    finding_details: str
    status: str

class PostgresStigChecker:
    def __init__(self):
        self.log_line_prefix_standard = "%m [%p] %q%u:%r@%d/%a-"

    def version_check(self, server_version: str) -> CheckResult:
        curr_versions = ["13", "14", "15", "16"]
        maj_version = server_version.split('.')[0]
        
        if maj_version in curr_versions:
            return CheckResult(
                f'NOT A FINDING \nPostgres Server version: {server_version}. Version is current.',
                'not_a_finding'
            )
        elif maj_version == "12":
            return CheckResult(
                f'NOT A FINDING \nPostgres Server version: {server_version}. Major version 12 upgrading to Version 13+ by 14 DEC 2024',
                'not_a_finding'
            )
        return CheckResult(
            f'OPEN FINDING \nPostgres Server version: {server_version}. Version is out of date',
            'open'
        )

    def fips_140_check(self) -> CheckResult:
        return CheckResult(
            'NOT A FINDING \nData at rest: Azure Database for PostgreSQL uses FIPS 140-2 validated cryptographic module. '
            'Data is encrypted on disk, including backups and temporary files.',
            'not_a_finding'
        )

    def priv_func_check(self, du_res: str, ext_res: str) -> CheckResult:
        return CheckResult(
            f'NOT A FINDING \nReviewed system documentation\n psql \\d: {du_res} \n '
            f'select * from pg_extension: {ext_res}',
            'not_a_finding'
        )

    def pki_check(self, pki_certs: str) -> CheckResult:
        return CheckResult(
            f'NOT A FINDING \nAccess to all PKI private keys stored/utilized by PostgreSQL '
            f'are managed by Azure PaaS service.\n PKI FILE LOCATIONS:\n{pki_certs}',
            'not_a_finding'
        )

    # Add all other check methods here...
EOL

# Create src/azure_client.py
cat > src/azure_client.py << 'EOL'
from azure.identity import InteractiveBrowserCredential
from azure.keyvault.secrets import SecretClient
import subprocess
import json
import logging
from typing import Dict, Any, List

logger = logging.getLogger(__name__)

class AzureClient:
    def __init__(self, subscription_id: str, key_vault_name: str):
        self.subscription_id = subscription_id
        self.key_vault_name = key_vault_name
        self.credential = InteractiveBrowserCredential()

    def run_az_command(self, command: str) -> Dict[str, Any]:
        try:
            result = subprocess.run(
                command.split(),
                capture_output=True,
                text=True,
                check=True
            )
            return json.loads(result.stdout)
        except subprocess.CalledProcessError as e:
            logger.error(f"Error executing command: {command}")
            logger.error(f"Error message: {e.stderr}")
            raise

    def get_servers(self) -> List[Dict[str, Any]]:
        return self.run_az_command('az postgres flexible-server list')

    def get_server_parameters(self, resource_group: str, server_name: str) -> List[Dict[str, Any]]:
        return self.run_az_command(
            f'az postgres flexible-server parameter list '
            f'--resource-group {resource_group} --server-name {server_name}'
        )

    def get_admin_credentials(self, resource_group: str, server_name: str) -> Dict[str, str]:
        admin_login = self.run_az_command(
            f'az postgres flexible-server show -g {resource_group} '
            f'--name {server_name} --query "administratorLogin"'
        )
        
        secret_name = f"{server_name}-pw"
        admin_pw = self.run_az_command(
            f'az keyvault secret show --name {secret_name} '
            f'--vault-name {self.key_vault_name} --query value'
        )
        
        return {
            'username': admin_login,
            'password': admin_pw
        }
EOL

# Create src/db_client.py
cat > src/db_client.py << 'EOL'
import psycopg2
from contextlib import contextmanager
import logging
from typing import Generator, Any, List
import subprocess
import sys

logger = logging.getLogger(__name__)

class PostgresClient:
    def __init__(self, connection_string: str):
        self.connection_string = connection_string

    @contextmanager
    def connect(self) -> Generator[Any, None, None]:
        conn = None
        try:
            conn = psycopg2.connect(self.connection_string)
            yield conn
        except Exception as e:
            logger.error(f"Database connection error: {str(e)}")
            raise
        finally:
            if conn:
                conn.close()

    def get_databases(self) -> List[str]:
        with self.connect() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT datname FROM pg_database 
                    WHERE datistemplate = false;
                """)
                return [row[0] for row in cursor.fetchall()]

    def execute_command(self, command: str) -> str:
        result = subprocess.run(
            ["psql", self.connection_string, "-c", command],
            capture_output=True
        )
        return result.stdout.decode(sys.stdout.encoding)
EOL

# Create src/stig_updater.py
cat > src/stig_updater.py << 'EOL'
import json
from typing import List, Dict, Any
import logging

logger = logging.getLogger(__name__)

def update_stig_findings(checklist_path: str, updates: List[Dict[str, Any]]) -> None:
    with open(checklist_path, 'r') as file:
        checklist = json.load(file)
    
    changes_made = False
    
    for stig in checklist.get('stigs', []):
        for rule in stig.get('rules', []):
            matching_updates = [
                update for update in updates 
                if update['rule_id'] == rule['rule_id']
            ]
            
            for update in matching_updates:
                if 'finding_details' in update:
                    rule['finding_details'] = update['finding_details']
                if 'status' in update:
                    rule['status'] = update['status']
                changes_made = True
    
    if changes_made:
        with open(checklist_path, 'w') as file:
            json.dump(checklist, file, indent=2)
EOL

# Create main.py
cat > main.py << 'EOL'
import logging
import os
from datetime import datetime
from src.azure_client import AzureClient
from src.db_client import PostgresClient
from src.db_checks import PostgresStigChecker
from src.stig_updater import update_stig_findings
import shutil

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def process_database(db_client: PostgresClient, stig_checker: PostgresStigChecker, 
                    parameters: Dict[str, Any], output_file: str):
    # Extract parameters
    server_version = parameters.get('server_version')
    shared_preload_libraries = parameters.get('shared_preload_libraries')
    log_disconnections = parameters.get('log_disconnections')
    log_connections = parameters.get('log_connections')
    ssl_enabled = parameters.get('ssl')

    # Get database info
    du_res = db_client.execute_command("\\du")
    dp_res = db_client.execute_command("\\dp")
    ext_res = db_client.execute_command("SELECT * from pg_extension;")
    
    # Perform checks
    checks = [
        ('version_check', stig_checker.version_check(server_version)),
        ('fips_140_check', stig_checker.fips_140_check()),
        ('priv_func_check', stig_checker.priv_func_check(du_res, ext_res)),
        ('pgaudit_check', stig_checker.pgaudit_check(
            shared_preload_libraries, log_disconnections, log_connections
        )),
        ('ssl_check', stig_checker.ssl_check(ssl_enabled))
    ]

    # Update STIG checklist with results
    for check_name, result in checks:
        logger.info(f"Processing check: {check_name}")
        update_stig_findings(output_file, [{
            'rule_id': get_rule_id(check_name),
            'finding_details': result.finding_details,
            'status': result.status
        }])

def main():
    subscription_id = os.getenv('SUBSCRIPTION')
    key_vault_name = "CAZDSEPKEYAKS"
    
    if not subscription_id:
        raise ValueError("SUBSCRIPTION environment variable not set")

    azure_client = AzureClient(subscription_id, key_vault_name)
    stig_checker = PostgresStigChecker()
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

    try:
        servers = azure_client.get_servers()
        
        for server in servers:
            server_name = server['name']
            resource_group = server['resourceGroup']
            
            logger.info(f"Processing server: {server_name}")
            
            try:
                parameters = azure_client.get_server_parameters(
                    resource_group, server_name
                )
                
                credentials = azure_client.get_admin_credentials(
                    resource_group, server_name
                )
                
                conn_string = (
                    f"postgresql://{credentials['username']}:{credentials['password']}"
                    f"@{server_name}.postgres.database.usgovcloudapi.net/postgres"
                    "?sslmode=require"
                )
                
                db_client = PostgresClient(conn_string)
                
                for database in db_client.get_databases():
                    logger.info(f"Processing database: {database}")
                    
                    output_file = f'./results/{server_name}_{database}_{timestamp}.cklb'
                    shutil.copy('./templates/template_pg9_empty.cklb', output_file)
                    
                    process_database(db_client, stig_checker, parameters, output_file)
                    
            except Exception as e:
                logger.error(f"Error processing server {server_name}: {str(e)}")
                continue
                
    except Exception as e:
        logger.error(f"Script execution error: {str(e)}")
        raise

if __name__ == "__main__":
    main()
EOL

# Create README.md
cat > README.md << 'EOL'
# PostgreSQL STIG Audit Tool

This tool automates the STIG compliance checking process for PostgreSQL databases in Azure Government cloud.

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
