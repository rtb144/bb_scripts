import json
import uuid

def update_finding_details(checklist_path, update_rules):
    """
    Update finding details for specific rules in a STIG Viewer 3 checklist.
    
    :param checklist_path: Path to the STIG Viewer checklist JSON file
    :param update_rules: List of dictionaries with rule update information
        Each dictionary should contain:
        - 'rule_id': The rule_id to update
        - 'stig_id': The STIG identifier 
        - 'finding_details': New finding details text
    
    :return: Updated checklist data
    """
    # Load the checklist
    with open(checklist_path, 'r') as file:
        checklist = json.load(file)
    
    # Track if any changes were made
    changes_made = False
    
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
                # Update finding details
                original_details = rule.get('finding_details', '')
                new_details = update['finding_details']
                
                # Optional: Append new details instead of completely replacing
                rule['finding_details'] = (
                    f"{original_details}\n{new_details}".strip() 
                    if original_details 
                    else new_details
                )
                
                changes_made = True
    
    # If changes were made, save the updated file
    if changes_made:
        output_path = checklist_path.replace('.json', '_updated.json')
        with open(output_path, 'w') as file:
            json.dump(checklist, file, indent=2)
        print(f"Updated checklist saved to {output_path}")
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
            'finding_details': 'Scanned on 2024-01-15 using OpenSCAP. No findings detected.'
        },
        {
            'rule_id': 'SV-254322',
            'finding_details': 'Manual review completed. Compliant as of audit date.'
        }
    ]
    
    # Path to your STIG checklist JSON file
    checklist_path = 'path/to/your/checklist.json'
    
    # Update the checklist
    updated_checklist = update_finding_details(checklist_path, updates)

if __name__ == '__main__':
    main()