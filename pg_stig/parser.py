import xml.etree.ElementTree as ET
import yaml
import os
from datetime import datetime

def parse_stig_cklb(cklb_file):
    """
    Parse a STIG checklist file and convert each rule to YAML format.
    
    Args:
        cklb_file (str): Path to the STIG CKLB XML file
        
    Returns:
        list: List of dictionaries containing rule information
    """
    # Parse XML file
    tree = ET.parse(cklb_file)
    root = tree.getroot()
    
    # Define XML namespaces commonly used in STIG files
    namespaces = {
        'cdf': 'http://checklists.nist.gov/xccdf/1.2',
        'xccdf': 'http://checklists.nist.gov/xccdf/1.1'
    }
    
    # Extract basic information
    benchmark_info = {
        'title': root.find('.//cdf:title', namespaces).text if root.find('.//cdf:title', namespaces) is not None else '',
        'description': root.find('.//cdf:description', namespaces).text if root.find('.//cdf:description', namespaces) is not None else '',
        'version': root.find('.//cdf:version', namespaces).text if root.find('.//cdf:version', namespaces) is not None else '',
    }
    
    rules = []
    
    # Find all rule elements
    for rule in root.findall('.//cdf:Rule', namespaces):
        rule_data = {
            'id': rule.get('id', ''),
            'severity': rule.get('severity', ''),
            'title': '',
            'description': '',
            'check': '',
            'fix': '',
            'cci_refs': [],
            'status': '',
            'finding_details': '',
            'comments': ''
        }
        
        # Extract rule information
        title_elem = rule.find('cdf:title', namespaces)
        if title_elem is not None:
            rule_data['title'] = title_elem.text
            
        desc_elem = rule.find('cdf:description', namespaces)
        if desc_elem is not None:
            rule_data['description'] = desc_elem.text
            
        check_elem = rule.find('.//cdf:check-content', namespaces)
        if check_elem is not None:
            rule_data['check'] = check_elem.text
            
        fix_elem = rule.find('cdf:fixtext', namespaces)
        if fix_elem is not None:
            rule_data['fix'] = fix_elem.text
            
        # Extract CCI references
        for ident in rule.findall('.//cdf:ident', namespaces):
            if ident.text and ident.text.startswith('CCI-'):
                rule_data['cci_refs'].append(ident.text)
        
        # Extract status and finding details from test results
        result_elem = rule.find('.//cdf:result', namespaces)
        if result_elem is not None:
            rule_data['status'] = result_elem.text
            
        details_elem = rule.find('.//cdf:finding-details', namespaces)
        if details_elem is not None:
            rule_data['finding_details'] = details_elem.text
            
        comments_elem = rule.find('.//cdf:comments', namespaces)
        if comments_elem is not None:
            rule_data['comments'] = comments_elem.text
        
        rules.append(rule_data)
    
    return benchmark_info, rules

def save_rules_to_yaml(benchmark_info, rules, output_dir):
    """
    Save each rule as a separate YAML file.
    
    Args:
        benchmark_info (dict): Basic information about the STIG benchmark
        rules (list): List of rule dictionaries
        output_dir (str): Directory to save the YAML files
    """
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Save benchmark info
    benchmark_file = os.path.join(output_dir, 'benchmark_info.yaml')
    with open(benchmark_file, 'w') as f:
        yaml.dump(benchmark_info, f, default_flow_style=False, sort_keys=False)
    
    # Save each rule as a separate file
    for rule in rules:
        rule_id = rule['id'].replace(':', '_').replace('.', '_')
        filename = f"rule_{rule_id}.yaml"
        filepath = os.path.join(output_dir, filename)
        
        with open(filepath, 'w') as f:
            yaml.dump(rule, f, default_flow_style=False, sort_keys=False)

def main():
    """
    Main function to process STIG CKLB file.
    """
    # Example usage
    cklb_file = "path/to/your/stig.cklb"
    output_dir = "stig_rules_yaml"
    
    try:
        benchmark_info, rules = parse_stig_cklb(cklb_file)
        save_rules_to_yaml(benchmark_info, rules, output_dir)
        print(f"Successfully processed {len(rules)} rules")
        print(f"YAML files saved to: {output_dir}")
    except Exception as e:
        print(f"Error processing STIG file: {str(e)}")

if __name__ == "__main__":
    main()