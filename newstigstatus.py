import json
import uuid

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
                
                # Update finding details if provided
                if 'finding_details' in update:
                    rule['finding_details'] = (
                        f"{original_details}\n{update['finding_details']}'.strip() 
                        if original_details 
                        else update['finding_details']
                    )
                
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

# Example usage
def main():
    # Define severity-based updates
    severity_updates = [
        {
            'severity': 'high',  # Update all high severity rules
            'status': 'open',
            'finding_details': 'Requires immediate attention during next security review'
        },
        {
            'severity': 'low',  # Update all low severity rules
            'status': 'not_applicable',
            'finding_details': 'Reviewed and deemed not applicable to current environment'
        }
    ]
    
    # Path to your STIG checklist JSON file
    checklist_path = 'path/to/your/checklist.json'
    
    # Update the checklist based on severity
    updated_checklist = update_findings_by_severity(checklist_path, severity_updates)

if __name__ == '__main__':
    main()