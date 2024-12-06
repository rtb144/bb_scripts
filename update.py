import json
import re

def update_checklist_with_database_info(checklist_path, database_info):
    """
    Update STIG checklist with database-specific information.
    
    :param checklist_path: Path to the STIG Viewer checklist JSON file
    :param database_info: Dictionary containing database update information
        Required keys:
        - 'database_name': Name of the database
        - 'server_name': Server name for FQDN
    
    :return: Updated checklist data
    """
    # Load the checklist
    with open(checklist_path, 'r') as file:
        checklist = json.load(file)
    
    # Ensure target_data exists
    if 'target_data' not in checklist:
        checklist['target_data'] = {}
    
    # Track changes
    changes_made = False
    updated_stigs = []
    
    # Update hostname with database name
    checklist['target_data']['host_name'] = database_info['database_name']
    changes_made = True
    
    # Update FQDN with server name
    checklist['target_data']['fqdn'] = f"{database_info['server_name']}.localdomain"
    changes_made = True
    
    # Iterate through STIGs to find web or database-related STIGs
    for stig in checklist.get('stigs', []):
        # Check if STIG is related to web or database
        is_web_db_stig = any(
            keyword in stig.get('stig_name', '').lower() 
            for keyword in ['database', 'web', 'db', 'sql', 'mysql', 'oracle', 'postgresql']
        )
        
        if is_web_db_stig:
            # Mark as web database
            checklist['target_data']['is_web_database'] = True
            
            # Update web database site with server name
            checklist['target_data']['web_db_site'] = database_info['server_name']
            
            # Update web database instance with database name
            checklist['target_data']['web_db_instance'] = database_info['database_name']
            
            # Track updated STIGs
            updated_stigs.append({
                'stig_name': stig.get('stig_name'),
                'stig_id': stig.get('stig_id')
            })
            
            changes_made = True
    
    # If changes were made, save the updated file
    if changes_made:
        output_path = checklist_path.replace('.json', '_database_updated.json')
        with open(output_path, 'w') as file:
            json.dump(checklist, file, indent=2)
        
        # Print detailed update summary
        print(f"Updated checklist saved to {output_path}")
        print("\nDatabase Information Updates:")
        print(f"  Hostname: {checklist['target_data']['host_name']}")
        print(f"  FQDN: {checklist['target_data']['fqdn']}")
        print(f"  Web DB Site: {checklist['target_data'].get('web_db_site', 'N/A')}")
        print(f"  Web DB Instance: {checklist['target_data'].get('web_db_instance', 'N/A')}")
        
        # Print updated STIGs
        if updated_stigs:
            print("\nUpdated Web/Database STIGs:")
            for stig in updated_stigs:
                print(f"  - {stig['stig_name']} (ID: {stig['stig_id']})")
    else:
        print("No updates made to the checklist.")
    
    return checklist

# Utility function to parse database connection information
def parse_database_connection(connection_string):
    """
    Parse database connection string to extract key information.
    
    :param connection_string: Database connection string
    :return: Dictionary with parsed database information
    """
    # Default parsing patterns
    patterns = [
        # Server patterns
        r'server=([^;]+)',
        r'host=([^;]+)',
        r'datasource=([^;]+)',
        
        # Database name patterns
        r'database=([^;]+)',
        r'initial\s*catalog=([^;]+)',
        r'db=([^;]+)'
    ]
    
    # Initialize result dictionary
    result = {
        'server_name': 'localhost',
        'database_name': 'unknown_database'
    }
    
    # Try each pattern for server
    for pattern in patterns[:3]:
        match = re.search(pattern, connection_string, re.IGNORECASE)
        if match:
            result['server_name'] = match.group(1).strip()
            break
    
    # Try each pattern for database name
    for pattern in patterns[3:]:
        match = re.search(pattern, connection_string, re.IGNORECASE)
        if match:
            result['database_name'] = match.group(1).strip()
            break
    
    return result

# Example usage
def main():
    # Example database connection strings
    connection_strings = [
        # Microsoft SQL Server
        'server=sqlserver.company.com;database=CustomerDB;user=admin;password=pass123',
        
        # MySQL/PostgreSQL
        'host=dbserver.local;database=product_db;port=5432;user=dbadmin',
        
        # Oracle
        'datasource=oracledb.company.net;initial catalog=ORCL;user id=system'
    ]
    
    # Path to your STIG checklist JSON file
    checklist_path = 'path/to/your/checklist.json'
    
    # Process each connection string
    for conn_string in connection_strings:
        # Parse connection string
        db_info = parse_database_connection(conn_string)
        
        print(f"\nProcessing connection string: {conn_string}")
        print(f"Extracted Info: {db_info}")
        
        # Update the checklist with parsed database information
        update_checklist_with_database_info(checklist_path, db_info)

if __name__ == '__main__':
    main()