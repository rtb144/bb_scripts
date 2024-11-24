import xml.etree.ElementTree as ET
import yaml
import uuid
import os
from datetime import datetime
from typing import Dict, List, Optional, Any

class STIGSchemaParser:
    def __init__(self):
        self.namespaces = {
            'cdf': 'http://checklists.nist.gov/xccdf/1.2',
            'xccdf': 'http://checklists.nist.gov/xccdf/1.1'
        }

    def parse_check_content_ref(self, element: ET.Element) -> Optional[Dict[str, str]]:
        """Parse check content reference if it exists"""
        check_ref = element.find('.//cdf:check-content-ref', self.namespaces)
        if check_ref is not None:
            return {
                "name": check_ref.get('name', ''),
                "href": check_ref.get('href', '')
            }
        return None

    def get_element_text(self, element: ET.Element, xpath: str, default: str = '') -> str:
        """Safely get element text with default value"""
        elem = element.find(xpath, self.namespaces)
        return elem.text if elem is not None and elem.text is not None else default

    def parse_group_tree(self, element: ET.Element) -> List[Dict[str, str]]:
        """Parse the group hierarchy tree"""
        tree = []
        current = element
        while current is not None:
            if 'Group' in current.tag:
                tree.append({
                    "id": current.get('id', ''),
                    "title": self.get_element_text(current, './cdf:title'),
                    "description": self.get_element_text(current, './cdf:description')
                })
            current = current.getparent()
        return list(reversed(tree))

    def parse_rule(self, rule: ET.Element, stig_uuid: str) -> Dict[str, Any]:
        """Parse a single STIG rule according to the schema"""
        rule_data = {
            "uuid": str(uuid.uuid4()),
            "stig_uuid": stig_uuid,
            "group_id": rule.get('id', '').replace('xccdf_mil.disa.stig_group_', ''),
            "group_id_src": rule.get('id', ''),
            "rule_id": rule.get('id', '').replace('xccdf_mil.disa.stig_rule_', '').replace('rule_', ''),
            "rule_id_src": rule.get('id', ''),
            "target_key": None,
            "stig_ref": None,
            "weight": rule.get('weight', ''),
            "classification": self.get_element_text(rule, './cdf:classification'),
            "severity": rule.get('severity', 'unknown').lower(),
            "rule_version": self.get_element_text(rule, './cdf:version'),
            "rule_title": self.get_element_text(rule, './cdf:title'),
            "fix_text": self.get_element_text(rule, './cdf:fixtext'),
            "reference_identifier": None,
            "group_title": self.get_element_text(rule, './cdf:group/cdf:title'),
            "false_positives": self.get_element_text(rule, './cdf:false-positives'),
            "false_negatives": self.get_element_text(rule, './cdf:false-negatives'),
            "discussion": self.get_element_text(rule, './cdf:description'),
            "check_content": self.get_element_text(rule, './/cdf:check-content'),
            "documentable": self.get_element_text(rule, './cdf:documentable'),
            "mitigations": self.get_element_text(rule, './cdf:mitigations'),
            "potential_impacts": self.get_element_text(rule, './cdf:potential-impacts'),
            "third_party_tools": self.get_element_text(rule, './cdf:third-party-tools'),
            "mitigation_control": self.get_element_text(rule, './cdf:mitigation-control'),
            "responsibility": self.get_element_text(rule, './cdf:responsibility'),
            "security_override_guidance": self.get_element_text(rule, './cdf:security-override-guidance'),
            "ia_controls": self.get_element_text(rule, './cdf:ia-controls'),
            "check_content_ref": self.parse_check_content_ref(rule),
            "legacy_ids": [ident.text for ident in rule.findall('.//cdf:ident[@system="http://legacy-id"]', self.namespaces)],
            "ccis": [ident.text for ident in rule.findall('.//cdf:ident[@system="http://cyber.mil/cci"]', self.namespaces)],
            "group_tree": self.parse_group_tree(rule),
            "createdAt": datetime.utcnow().isoformat() + 'Z',
            "updatedAt": datetime.utcnow().isoformat() + 'Z',
            "status": "not_reviewed",
            "overrides": {},
            "comments": "",
            "finding_details": "",
            "STIGUuid": str(uuid.uuid4())  # Deprecated but included as per schema
        }
        
        # Ensure severity is one of the allowed values
        if rule_data["severity"] not in ["unknown", "low", "medium", "high"]:
            rule_data["severity"] = "unknown"
            
        return rule_data

    def parse_stig_cklb(self, cklb_file: str) -> Dict[str, Any]:
        """Parse STIG CKLB file into schema-compliant format"""
        tree = ET.parse(cklb_file)
        root = tree.getroot()
        
        # Generate main document UUID
        doc_uuid = str(uuid.uuid4())
        
        # Create the base structure
        checklist_data = {
            "title": os.path.basename(cklb_file),
            "cklb_version": "1.0",
            "id": doc_uuid,
            "active": True,
            "mode": 0,
            "has_path": True,
            "target_data": {
                "target_type": "",
                "host_name": "",
                "ip_address": "",
                "mac_address": "",
                "fqdn": "",
                "comments": "",
                "role": "",
                "is_web_database": False,
                "technology_area": "",
                "web_db_site": "",
                "web_db_instance": ""
            },
            "stigs": []
        }

        # Parse benchmark information
        benchmark = root.find('.//cdf:Benchmark', self.namespaces)
        if benchmark is not None:
            stig_uuid = str(uuid.uuid4())
            stig_data = {
                "stig_name": self.get_element_text(benchmark, './cdf:title'),
                "display_name": self.get_element_text(benchmark, './cdf:title').replace('Security Technical Implementation Guide', 'STIG'),
                "stig_id": benchmark.get('id', ''),
                "release_info": self.get_element_text(benchmark, './cdf:version'),
                "uuid": stig_uuid,
                "reference_identifier": None,
                "size": len(benchmark.findall('.//cdf:Rule', self.namespaces)),
                "rules": []
            }

            # Parse rules
            for rule in benchmark.findall('.//cdf:Rule', self.namespaces):
                rule_data = self.parse_rule(rule, stig_uuid)
                stig_data["rules"].append(rule_data)

            checklist_data["stigs"].append(stig_data)

        return checklist_data

    def save_to_yaml(self, data: Dict[str, Any], output_file: str):
        """Save the parsed data to a YAML file"""
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, 'w') as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False)

def main():
    """Main function to demonstrate usage"""
    parser = STIGSchemaParser()
    
    # Example usage
    input_file = "path/to/your/stig.cklb"
    output_file = "path/to/output/stig_parsed.yaml"
    
    try:
        parsed_data = parser.parse_stig_cklb(input_file)
        parser.save_to_yaml(parsed_data, output_file)
        print(f"Successfully parsed STIG file and saved to: {output_file}")
    except Exception as e:
        print(f"Error processing STIG file: {str(e)}")

if __name__ == "__main__":
    main()