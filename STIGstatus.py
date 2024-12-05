import json
import uuid

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
    else:
        print("No matching rules found. No updates made.")
    
    return checklist

# Example usage
def main():
    # Define the rules to update
    updates = [
        {
            'rule_id': 'SV-254321',  # Example rule ID
            'stig_id': 'RHEL_9_STIG',  # Optional: specify STIG if needed
            'finding_details': 'Scanned on 2024-01-15 using OpenSCAP. No findings detected.',
            'status': 'not_a_finding'  # Change status to not a finding
        },
        {
            'rule_id': 'SV-254322',
            'finding_details': 'Manual review completed.',
            'status': 'open'  # Set status to open
        }
    ]
    
    # Path to your STIG checklist JSON file
    checklist_path = 'path/to/your/checklist.json'
    
    # Update the checklist
    updated_checklist = update_stig_findings(checklist_path, updates)

if __name__ == '__main__':
    main()