import subprocess
import json
import csv
from datetime import datetime
import psycopg2
from typing import List, Dict, Any
import sys
import shutil

log_line_prefix_standard = "%m [%p] %q%u:%r@%d/%a-"

#### ---- run azure cli commands using subprocess.run
def run_az_command(command: str) -> List[Dict[Any, Any]]:
    """Execute Azure CLI command and return JSON response."""
    try:
        result = subprocess.run(
            command.split(),
            capture_output=True,
            text=True,
            check=True
        )
        # print(result)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {command}")
        print(f"Error message: {e.stderr}")
        return []
    

### - update details and status for specific rules: MAKE SURE TO use RULE ID and not GROUP ID
def update_stig_findings(checklist_path, update_rules):
    """
    Update finding details and status for specific rules in a STIG Viewer 3 checklist.
    
    :param checklist_path: Path to the STIG Viewer checklist JSON file
    :param update_rules: List of dictionaries with rule update information
        Each dictionary should contain:
        - 'rule_id': The rule_id to update
        - 'stig_id': Optional STIG identifier for precise matching
        - 'finding_details': Optional new finding details text
        - 'status': Optional new status (not_reviewed, not_applicable, open, not_a_finding)
    
    :return: Updated checklist data
    """
    # Valid status options based on the JSON schema
    VALID_STATUSES = ['not_reviewed', 'not_applicable', 'open', 'not_a_finding']
    
    # Load the checklist
    with open(checklist_path, 'r') as file:
        checklist = json.load(file)
    
    # Track if any changes were made
    changes_made = False
    
    # Track update details for logging
    updated_rules = []
    
    # Iterate through STIGs in the checklist
    for stig in checklist.get('stigs', []):
        # Iterate through rules in each STIG
        for rule in stig.get('rules', []):
            # Find rules matching the update criteria
            matching_updates = [
                update for update in update_rules 
                if (update['rule_id'] == rule['rule_id'] and 
                    update.get('stig_id', stig['stig_id']) == stig['stig_id'])
            ]
            
            # Apply updates
            for update in matching_updates:
                # Update finding details if provided
                if 'finding_details' in update:
                    original_details = rule.get('finding_details', '')
                    new_details = update['finding_details']
                    
                    # Append new details instead of completely replacing
                    rule['finding_details'] = (
                        f"{original_details}\n{new_details}".strip() 
                        if original_details 
                        else new_details
                    )
                    changes_made = True
                
                # Update status if provided and valid
                if 'status' in update:
                    if update['status'] not in VALID_STATUSES:
                        raise ValueError(f"Invalid status: {update['status']}. Must be one of {VALID_STATUSES}")
                    
                    original_status = rule.get('status', 'not_reviewed')
                    rule['status'] = update['status']
                    changes_made = True
                    
                # Track which rules were updated
                updated_rules.append({
                    'rule_id': rule['rule_id'],
                    'stig_id': stig['stig_id'],
                    'original_status': original_status,
                    'new_status': rule.get('status'),
                    'original_details': original_details,
                    'new_details': rule.get('finding_details', '')
                })

    # If changes were made, save the updated file
    if changes_made:
        output_path = checklist_path.replace('.json', '_updated.json')
        with open(output_path, 'w') as file:
            json.dump(checklist, file, indent=2)
        
        # Print detailed update log
        print(f"Updated checklist saved to {output_path}")
        print("\nUpdated Rules:")
        for update in updated_rules:
            print(f"Rule ID: {update['rule_id']} (STIG: {update['stig_id']})")
            print(f"  Status: {update['original_status']} → {update['new_status']}")
            print(f"  Details: {update['original_details']} → {update['new_details']}\n")
            print()
    else:
        print("No matching rules found. No updates made.")
    
    return checklist

### -------------- UPDATE FINDING STATUS IN BULK BY SEVERITY
### -------------- CYBER Requested all CAT II findings be open by default
def update_findings_by_severity(checklist_path, severity_updates):
    """
    Update finding status for all rules matching specified severity levels.
    
    :param checklist_path: Path to the STIG Viewer checklist JSON file
    :param severity_updates: List of dictionaries with severity update rules
        Each dictionary should contain:
        - 'severity': Severity level to match (low, medium, high, unknown)
        - 'status': New status to apply to matching rules
        - 'finding_details': Optional finding details to add
    
    :return: Updated checklist data
    """
    # Valid severity and status options based on the JSON schema
    VALID_SEVERITIES = ['low', 'medium', 'high', 'unknown']
    VALID_STATUSES = ['not_reviewed', 'not_applicable', 'open', 'not_a_finding']
    
    # Validate input
    for update in severity_updates:
        if update['severity'] not in VALID_SEVERITIES:
            raise ValueError(f"Invalid severity: {update['severity']}. Must be one of {VALID_SEVERITIES}")
        if update['status'] not in VALID_STATUSES:
            raise ValueError(f"Invalid status: {update['status']}. Must be one of {VALID_STATUSES}")
    
    # Load the checklist
    with open(checklist_path, 'r') as file:
        checklist = json.load(file)
    
    # Track changes
    changes_made = False
    updated_rules = []
    
    # Iterate through STIGs in the checklist
    for stig in checklist.get('stigs', []):
        # Iterate through rules in each STIG
        for rule in stig.get('rules', []):
            # Check for matching severity updates
            matching_updates = [
                update for update in severity_updates 
                if update['severity'] == rule.get('severity')
            ]
            
            # Apply updates
            for update in matching_updates:
                # Store original values
                original_status = rule.get('status', 'not_reviewed')
                original_details = rule.get('finding_details', '')
                
                # Update status
                rule['status'] = update['status']
                changes_made = True
                

                
                # Track updated rule details
                updated_rules.append({
                    'rule_id': rule['rule_id'],
                    'stig_id': stig['stig_id'],
                    'severity': rule.get('severity'),
                    'original_status': original_status,
                    'new_status': rule['status'],
                    'original_details': original_details,
                    'new_details': rule.get('finding_details', '')
                })
    
    # If changes were made, save the updated file
    if changes_made:
        output_path = checklist_path.replace('.json', '_severity_updated.json')
        with open(output_path, 'w') as file:
            json.dump(checklist, file, indent=2)
        
        # Print summary of updates
        print(f"Updated checklist saved to {output_path}")
        print("\nSeverity-based Updates Summary:")
        
        # Group updates by severity
        severity_summary = {}
        for update in updated_rules:
            severity = update['severity']
            if severity not in severity_summary:
                severity_summary[severity] = []
            severity_summary[severity].append(update)
        
        # Print detailed summary
        for severity, updates in severity_summary.items():
            print(f"\n{severity.upper()} Severity Rules:")
            print(f"  Total Updated: {len(updates)}")
            print("  Sample Updates:")
            for update in updates[:5]:  # Show up to 5 sample updates
                print(f"    Rule ID: {update['rule_id']}")
                print(f"    Status: {update['original_status']} → {update['new_status']}")
    else:
        print("No matching rules found. No updates made.")
    
    return checklist


#### TO DO: ADD SCHEMA VALIDATION
def parse_json_cklb(self, input_file: str) -> Dict[str, Any]:
    """
    Parse a JSON CKLB file following the provided schema
    
    Args:
        input_file (str): Path to the JSON CKLB file
        
    Returns:
        Dict[str, Any]: The parsed CKLB data
    """
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data


#### - STIG RULE CHECKS #####

def version_check(server_version, output_file):
    curr_versions = ["13", "14", "15", "16"]
    maj_version = server_version.split('.')[0]
    if maj_version in curr_versions:
        result = [f'NOT A FINDING \n Postgres Server version: {server_version}.  Version is current. Microsoft automatically updates minor versions during scheduled maintenance window.', 'not_a_finding']
    elif maj_version == "12":
        result = [f'NOT A FINDING \n Postgres Server version: {server_version}. Major version 12 upgrading to Version 13+ by 14 DEC 2024 to remain complaint', 'not_a_finding']
    else:
        result = [f'OPEN FINDING \n Postgres Server version: {server_version}. Version is out of date', 'open']
    
    updates = [
        {
            'rule_id': 'SV-265877r999537', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214050r961683',
            'finding_details': result[0],
            'status': result[1]  
        }
    ]

    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def FIPS_140_update(output_file):
    result = [f'NOT A FINDING \n(https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-security).  Data at rest: For storage encryption, Azure Database for PostgreSQL - Flexible Server uses the FIPS 140-2 validated cryptographic module. Data is encrypted on disk, including backups and the temporary files created while queries are running. \nThe service uses Galois/Counter Mode (GCM) mode with AES 256-bit cipher included in Azure storage encryption, and the keys are system managed. This is similar to other at-rest encryption technologies, like transparent data encryption in SQL Server or Oracle databases. Storage encryption is always on and can\'t be disabled.', 'not_a_finding']

    updates = [
        {
            'rule_id': 'SV-214157r961050', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214153r961050',
            'finding_details': result[0],
            'status': result[1]  
        },
        {
            'rule_id': 'SV-214119r961857', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214117r961857',
            'finding_details': result[0],
            'status': result[1]  
        }
    ]

    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def priv_func_check(output_file, du_res, ext_res):
    result = [f'NOT A FINDING \nReviewed system documentation: https://armyeitaas.sharepoint-mil.us/:f:/r/teams/AFC-HQ-DDSD-MADE-PRIVATE/Shared%20Documents/Cybersecurity-ATO/Cyber%20Team/Database%20Security/DB%20Security%20Documents?csf=1&web=1&e=bnsfDc\n psql \\d: {du_res} \n select * from pg_extension: {ext_res} ', 'not_a_finding']

    updates = [
        {
            'rule_id': 'SV-214148r961353', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]

    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist


def pki_check(output_file, pki_keys_res):
    result = [f'NOT A FINDING \nAccess to all PKI private keys stored/utilized by PostgreSQL are managed by Azure PaaS service.\n PKI FIlE LOCATIONS:\n{pki_keys_res}', 'not_a_finding']

    updates = [
        {
            'rule_id': 'SV-214136r961041', 
            'finding_details': result[0],
            'status': result[1] 
        },
                {
            'rule_id': 'SV-214137r961596', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]
  

    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def md5_check(output_file, md5_res):
    result = [f'NOT A FINDING \n psql show password_encryption {md5_res} \nDSE Access Control Plan Documentation states: The password encryption shall be set to MD5 or SCRAM-SHA-256 in the PG Flex Server parameter password_encryption in the Azure Portal or via Azure command line tools. (https://armyeitaas.sharepoint-mil.us/:w:/r/teams/AFC-HQ-DDSD-MADE-PRIVATE/_layouts/15/Doc.aspx?sourcedoc=%7BFACBF059-B3F9-4293-8E86-6951271B999F%7D&file=DRAFT_AFC-DSE_Access_Control_Plan_(AC).docx&action=default&mobileredirect=true)\nMicrosoft has removed all permissions for non-superusers on pg_shadow.Users inside this server are not superusers.(https://learn.microsoft.com/en-us/azure/postgresql/migrate/migration-service/concepts-user-roles-migration-service)', 'not_a_finding']

    updates = [
        {
            'rule_id': 'SV-214130r981949', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]

    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def pg_crypto_check(output_file, pg_crypto_res):
    result = [f'NOT A FINDING \n SELECT * FROM pg_available_extensions where name=\'pgcrypto\' {pg_crypto_res} (https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-security).  Data at rest: For storage encryption, Azure Database for PostgreSQL - Flexible Server uses the FIPS 140-2 validated cryptographic module. Data is encrypted on disk, including backups and the temporary files created while queries are running. \nThe service uses Galois/Counter Mode (GCM) mode with AES 256-bit cipher included in Azure storage encryption, and the keys are system managed. This is similar to other at-rest encryption technologies, like transparent data encryption in SQL Server or Oracle databases. Storage encryption is always on and can\'t be disabled.', 'not_a_finding']

    updates = [
        {
            'rule_id': 'SV-214120r961128', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214139r961602', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]

    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def installation_account_check(output_file):
    result = [f'NOT A FINDING \n The PostgreSQL software installation account is only available to the Microsoft Azure internal processes for installation of the underlying resources.\n\nRoles and permissions are documented in a PG Flex server security report for each server and validated by data owner as legitimate requirements in accordance with principle of least privilege. \nDocumentation: (https://armyeitaas.sharepoint-mil.us/:f:/r/teams/AFC-HQ-DDSD-MADE-PRIVATE/Shared%20Documents/Cybersecurity-ATO/Cyber%20Team/Database%20Security/DB%20Security%20Documents?csf=1&web=1&e=bnsfDc)\n', 'not_a_finding']


    updates = [
        {
            'rule_id': 'SV-214075r960960', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]

    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def access_check(output_file, du_res, dp_res):
    result = [f'NOT A FINDING \n Reviewed server documenation:\n (https://armyeitaas.sharepoint-mil.us/:f:/r/teams/AFC-HQ-DDSD-MADE-PRIVATE/Shared%20Documents/Cybersecurity-ATO/Cyber%20Team/Database%20Security/DB%20Security%20Documents?csf=1&web=1&e=bnsfDc)\n Per the AFC-DSE_Access_Control_Plan_(AC), roles and permissions are documented in PG Flex Server security report\n psql \\du:{du_res} \n psql \\dp: {dp_res}', 'not_a_finding']


    updates = [
        {
            'rule_id': 'SV-214057r960792', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214146r960969', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214061r961053', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]
    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def data_in_transit_check(output_file, md5_res):
    result = [f'NOT A FINDING \nData in transit: Azure Database for PostgreSQL - Flexible Server encrypts in-transit data with Secure Sockets Layer and Transport Layer Security (SSL/TLS). Encryption is enforced by default. For more detailed information on connection security with SSL\\TLS, see this documentation. For better security, you might choose to enable SCRAM authentication in Azure Database for PostgreSQL - Flexible Server. (https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-security) \n psql show password_encryption {md5_res}', 'not_a_finding']


    updates = [
        {
            'rule_id': 'SV-214056r961029', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]
    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def authoriziaton_check(output_file):
    result = [f'NOT A FINDING \nreviewed server documentation: \nRoles and permissions are be documented in a PG Flex server security report for each server and validated by data owner as legitimate requirements in accordance with principle of least privilege.\n(https://armyeitaas.sharepoint-mil.us/:f:/r/teams/AFC-HQ-DDSD-MADE-PRIVATE/Shared%20Documents/Cybersecurity-ATO/Cyber%20Team/Database%20Security/DB%20Security%20Documents?csf=1&web=1&e=bnsfDc)\n', 'not_a_finding']


    updates = [
        {
            'rule_id': 'SV-214052r960768', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]
    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def NSA_crypto_check(output_file):
    result = [f'NA \nPostgreSQL is deployed in an unclassified environment', 'not_applicable']


    updates = [
        {
            'rule_id': 'SV-220321r961857', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]
    updated_checklist = update_stig_findings(output_file, updates)

    return updated_checklist

def cat_II_default(output_file, status_res):
    
    updates = [
        {
            'severity': 'medium', 
            'status': status_res 
        }
    ]
    updated_checklist = update_findings_by_severity(output_file, updates)

    return updated_checklist

def pgaudit_check(output_file, shared_pre_lib_res, log_dis_res, log_conn_res):

    shared_pre_lib_list = shared_pre_lib_res.split(",")
    if 'pgaudit' in shared_pre_lib_list and log_conn_res == 'on' and log_dis_res == 'on':
        result = [f'NOT A FINDING\nShared libraries: {shared_pre_lib_res} \nDisconnect: {log_dis_res} \nConnect: {log_conn_res}', 'not_a_finding']
    else:
        result = [f'\nShared libraries: {shared_pre_lib_res} \nDisconnect: {log_dis_res} \nConnect: {log_conn_res}', 'open']

    updates = [
        {
            'rule_id': 'SV-214156r961839', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214092r961824', 
            'finding_details': result[0],
            'status': result[1] 
        }

    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist

def pgaudit_check2(output_file, shared_pre_lib_res, audit_log_res):

    shared_pre_lib_list = shared_pre_lib_res.lower().split(",")
    audit_log_list = audit_log_res.lower().split(",")

    if 'pgaudit' in shared_pre_lib_list and 'role' in audit_log_list and 'read' in audit_log_list and 'write' in audit_log_list and 'ddl' in audit_log_list:
        result = [f'NOT A FINDING\nShared libraries: {shared_pre_lib_res} \npgaudit.log: {audit_log_res}', 'not_a_finding']
    else:
         result = [f'\nShared libraries: {shared_pre_lib_res} \npgaudit.log: {audit_log_res}', 'open']

    updates = [
        {
            'rule_id': 'SV-214155r961836', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214154r961821', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214105r961800', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214104r961818', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214102r961812', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214101r961791', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214100r961797', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214099r961827', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214097r961809', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {   
            'rule_id': 'SV-214091r961821', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {   
            'rule_id': 'SV-214085r961797', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist

def pgaudit_check3(output_file, shared_pre_lib_res, log_destination_res):

    shared_pre_lib_list = shared_pre_lib_res.lower().split(",")
    
    if 'pgaudit' in shared_pre_lib_list and (log_destination_res.lower() == 'stderr' or log_destination_res.lower() == 'syslog'):
        result = [f'NOT A FINDING\nShared libraries: {shared_pre_lib_res} \nlog_destination: {log_destination_res}', 'not_a_finding']
    else:
         result = [f'Shared libraries: {shared_pre_lib_res} \nlog_destination: {log_destination_res}', 'open']

    updates = [
        {
            'rule_id': 'SV-214123r960888', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist

def pgaudit_check4(output_file, shared_pre_lib_res, audit_log_res, pgaudit_log_catalog_res):

    shared_pre_lib_list = shared_pre_lib_res.lower().split(",")
    audit_log_list = audit_log_res.lower().split(",")

    if 'pgaudit' in shared_pre_lib_list and 'role' in audit_log_list and 'read' in audit_log_list and 'write' in audit_log_list and 'ddl' in audit_log_list and pgaudit_log_catalog_res == 'on':
        result = [f'NOT A FINDING\nShared libraries: {shared_pre_lib_res} \npgaudit.log: {audit_log_res}\npgaudit.log_catalog: {pgaudit_log_catalog_res}', 'not_a_finding']
    else:
         result = [f'\nShared libraries: {shared_pre_lib_res} \npgaudit.log: {audit_log_res}\npgaudit.log_catalog: {pgaudit_log_catalog_res}', 'open']

    updates = [
        {
            'rule_id': 'SV-214107r961803', 
            'finding_details': result[0],
            'status': result[1] 
        }
    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist


def ssl_check(output_file, ssl_enabled_res):

    if ssl_enabled_res == 'on':
        result = [f'NOT A FINDING \nSSL : {ssl_enabled_res}', 'not_a_finding']
    else:
         result = [f'\nSSL : {ssl_enabled_res}', 'open']

    updates = [
        {
            'rule_id': 'SV-214145r961119', 
            'finding_details': result[0],
            'status': result[1] 
        },

    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist

def log_line_prefix_check(output_file, log_line_prefix_res):

    if log_line_prefix_res == log_line_prefix_standard:
        result = [f'NOT A FINDING \nlog_line_prefix : {log_line_prefix_res}. AFC DSE Postgres log_line_prefix standard is <{log_line_prefix_standard}>', 'not_a_finding']
    else:
         result = [f'log_line_prefix : {log_line_prefix_res}. AFC DSE Postgres log_line_prefix standard is <{log_line_prefix_standard}>', 'open']

    updates = [
        {
            'rule_id': 'SV-214145r961119', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214142r960894', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214112r960897', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214116r960906', 
            'finding_details': result[0],
            'status': result[1] 
        },

    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist


def log_line_prefix_check2(output_file, log_line_prefix_res, log_dis_res, log_conn_res):
    if log_line_prefix_res == log_line_prefix_standard and log_conn_res == 'on' and log_dis_res == 'on':
        result = [f'NOT A FINDING \nlog_line_prefix : {log_line_prefix_res}. AFC DSE Postgres log_line_prefix standard is <{log_line_prefix_standard}>\nDisconnect: {log_dis_res} \nConnect: {log_conn_res}', 'not_a_finding']
    else:
         result = [f'log_line_prefix : {log_line_prefix_res}. AFC DSE Postgres log_line_prefix standard is <{log_line_prefix_standard}>\nDisconnect: {log_dis_res} \nConnect: {log_conn_res}', 'open']

    updates = [
        {
            'rule_id': 'SV-214138r960891', 
            'finding_details': result[0],
            'status': result[1] 
        },
        {
            'rule_id': 'SV-214103r961833', 
            'finding_details': result[0],
            'status': result[1] 
        },

    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist


def log_line_prefix_check3(output_file, log_line_prefix_res, shared_pre_lib_res):

    shared_pre_lib_list = shared_pre_lib_res.split(",")

    if log_line_prefix_res == log_line_prefix_standard and 'pgaudit' in shared_pre_lib_list:
        result = [f'NOT A FINDING \nlog_line_prefix : {log_line_prefix_res}. AFC DSE Postgres log_line_prefix standard is <{log_line_prefix_standard}>\n\nShared libraries: {shared_pre_lib_res}', 'not_a_finding']
    else:
         result = [f'log_line_prefix : {log_line_prefix_res}. AFC DSE Postgres log_line_prefix standard is <{log_line_prefix_standard}>\nShared libraries: {shared_pre_lib_res}', 'open']

    updates = [
        {
            'rule_id': 'SV-214132r960864', 
            'finding_details': result[0],
            'status': result[1] 
        },

    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist


def log_timezone_check(output_file, log_timezone_res):

    if log_timezone_res.lower() == 'utc':
        result = [f'NOT A FINDING \nlog_timezone : {log_timezone_res}. AFC DSE Postgres log_timezone standard is <UTC>', 'not_a_finding']
    else:
        result = [f'log_timezone : {log_timezone_res}. AFC DSE Postgres log_timezone standard is <UTC>', 'open']

    updates = [
        {
            'rule_id': 'SV-214069r961443', 
            'finding_details': result[0],
            'status': result[1] 
        },

    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist

def client_min_messages_check(output_file, client_min_messages_res):

    if client_min_messages_res.lower() == 'error':
        result = [f'NOT A FINDING \nclient_min_messages : {client_min_messages_res}. AFC DSE Postgres log_timezone standard is <error>', 'not_a_finding']
    else:
        result = [f'client_min_messages: {client_min_messages_res}. AFC DSE Postgres log_timezone standard is <error>', 'open']

    updates = [
        {
            'rule_id': 'SV-214053r961167', 
            'finding_details': result[0],
            'status': result[1] 
        },

    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist

def port_check(output_file, port_res):

    if port_res == '5432':
        result = [f'NOT A FINDING \nPort : {port_res}. AFC DSE Postgres log_timezone standard is <5432>', 'not_a_finding']
    else:
        result = [f'Port: {port_res}. AFC DSE Postgres log_timezone standard is <5432>', 'open']

    updates = [
        {
            'rule_id': 'SV-214048r960966', 
            'finding_details': result[0],
            'status': result[1] 
        },

    ]
    updated_checklist = update_stig_findings(output_file, updates)
    return updated_checklist




### MAIN 
### ----------------------------------------------------------------
### ----------------------------------------------------------------

def main():
    # Get all PostgreSQL Flex servers
    servers = run_az_command('az postgres flexible-server list')
    
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    
    

    keyVaultName = "CAZDSEPKEYAKS"
    
    for server in servers:
        # set server name and resource group from server variables
        server_name = server['name']
        resource_group = server['resourceGroup']
        ##server_version = server['version']
        pki_certs = ""

        server_parameters = run_az_command(f'az postgres flexible-server parameter list --resource-group {resource_group} --server-name {server_name}')
        count = 0

        ### SET SERVER PARAMETER VALUES TO VARIABLES
        for params in server_parameters:

            if(params['name'] == 'server_version'):
                server_version = params['value']
               
            if(params['name'] == 'ssl_ca_file' or params['name'] == 'ssl_cert_file' or params['name'] == 'ssl_key_file' or params['name'] == 'ssl_crl_file'):
                pki_certs += f"{params['name']} = {params['value']}\n"

            if(params['name'] == 'shared_preload_libraries'):
                shared_preload_libraries = params['value']

            if(params['name'] == 'log_disconnections'):
                log_disconnections = params['value']
            
            if(params['name'] == 'log_connections'):
                log_connections = params['value']

            if(params['name'] == 'pgaudit.log'):
                pgaudit_log = params['value']

            if(params['name'] == 'ssl'):
                ssl_enabled = params['value']

            if(params['name'] == 'log_line_prefix'):
                log_line_prefix = params['value']

            if(params['name'] == 'log_timezone'):
                log_timezone = params['value']

            if(params['name'] == 'client_min_messages'):
                client_min_messages = params['value']

            if(params['name'] == 'port'):
                port = params['value']

            if(params['name'] == 'log_destination'):
                log_destination = params['value']
            
            
        
 

        secretName = server['name'] + "-pw"

        print(f"\nProcessing server: {server_name}")
        
        # Get admin credentials
        adminLogin = run_az_command(
            f'az postgres flexible-server show -g {resource_group} --name {server_name} --query "administratorLogin"'
        )
        showServers = run_az_command(
                f'az postgres flexible-server show -g {resource_group} --name {server_name}'
        )
        adminPW = run_az_command(
            f'az keyvault secret show --name {secretName} --vault-name {keyVaultName} --query value'
        )
        admin_creds = run_az_command(
            f'az postgres flexible-server show-connection-string --server-name {server_name} -u {adminLogin} -p {adminPW}'
        )
    
        admin_login = showServers['administratorLogin']


        #print({admin_login})
        #print({adminLogin})
        #print({adminPW})

        connect_string = f"postgresql://{admin_login}:{adminPW}@{server_name}.postgres.database.usgovcloudapi.net/postgres?sslmode=require"
        

        if not admin_creds:
            print(f"Skipping server {server_name} - couldn't get credentials")
            continue
        
        try:
            # Parse connection string and connect

            ##print({connect_string})
            connection = psycopg2.connect(connect_string)
            
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
                output_file = f'./results/{server_name}_{database}_{timestamp}.cklb'
                
                shutil.copy('./template/template_pg9_empty.cklb', output_file )

                # Reconnect to specific databaseS
                connection.close()
                conn_info_db = connect_string.replace('postgres?', f'{database}?')

                ##print(f"Database connection string: {conn_info_db}")
                
                connection = psycopg2.connect(conn_info_db)

                du_res = subprocess.run(["psql", conn_info_db, "-c", "\\du"], capture_output=True)
                du_res_string = du_res.stdout.decode(sys.stdout.encoding)
                dp_res = subprocess.run(["psql", conn_info_db, "-c", "\\dp"], capture_output=True)
                dp_res_string = dp_res.stdout.decode(sys.stdout.encoding)
                ext_res = subprocess.run(["psql", conn_info_db, "-c", "SELECT * from pg_extension;"], capture_output=True)
                ext_res_string = ext_res.stdout.decode(sys.stdout.encoding)
                md5_res = subprocess.run(["psql", conn_info_db, "-c", "show password_encryption;"], capture_output=True)
                md5_res_string = md5_res.stdout.decode(sys.stdout.encoding)
                pgcrypto_res = subprocess.run(["psql", conn_info_db, "-c", "SELECT * FROM pg_available_extensions where name=\'pgcrypto\';"], capture_output=True)
                pgcrypto_res_string = pgcrypto_res.stdout.decode(sys.stdout.encoding)
               
                ### SET CATII default to open - turn off for testing and tracking
                ## catII_default_status = 'open'
                ## cat_II_default_result = cat_II_default(output_file, catII_default_status)

                ### CAT 1 checks
                version_result = version_check(server_version, output_file)
                fips_140_result = FIPS_140_update(output_file)
                priv_func_check_result = priv_func_check(output_file, du_res_string, ext_res_string)
                pki_check_result = pki_check(output_file, pki_certs)
                md5_check_result = md5_check(output_file, md5_res_string)
                pg_crypto_check_result = pg_crypto_check(output_file, pgcrypto_res_string)
                installation_account_check_result = installation_account_check(output_file)
                access_check_result = access_check(output_file, du_res_string, dp_res_string)
                data_in_transit_check_result = data_in_transit_check(output_file, md5_res_string)
                ssl_check_result = ssl_check(output_file, ssl_enabled)
                authoriziaton_check_result = authoriziaton_check(output_file)
                


                ## CAT II check           
                NSA_crypto_check_result = NSA_crypto_check(output_file)
                pgaudit_check_result = pgaudit_check(output_file, shared_preload_libraries, log_disconnections, log_connections)
                pgaudit_check2_result = pgaudit_check2(output_file, shared_preload_libraries, pgaudit_log)
                pgaudit_check3_result = pgaudit_check3(output_file, shared_preload_libraries, log_destination)
                log_line_prefix_check_result = log_line_prefix_check(output_file, log_line_prefix)
                log_line_prefix_check2_result = log_line_prefix_check2(output_file, log_line_prefix, log_disconnections, log_connections)
                log_line_prefix_check3_result = log_line_prefix_check3(output_file, log_line_prefix, shared_preload_libraries)
                log_timezone_check_result = log_timezone_check(output_file, log_timezone)
                client_min_messages_check_result = client_min_messages_check(output_file, client_min_messages)
                port_check_result = port_check(output_file, port)

                
                
            connection.close()
            
        except Exception as e:
            print(f"Error processing server {server_name}: {str(e)}")
            continue
    
    print(f"\nScript Done")

if __name__ == "__main__":
    main()