import json
import yaml
from typing import Dict, Any
import os

class STIGJsonParser:
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

    def save_to_yaml(self, data: Dict[str, Any], output_file: str):
        """
        Save the STIG data to YAML format
        
        Args:
            data (Dict[str, Any]): The STIG data to save
            output_file (str): Path to save the YAML file
        """
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False)

def main():
    parser = STIGJsonParser()
    
    # Example usage
    input_file = "path/to/your/stig.cklb"
    output_file = "path/to/output/stig.yaml"
    
    try:
        data = parser.parse_json_cklb(input_file)
        parser.save_to_yaml(data, output_file)
        print(f"Successfully converted STIG JSON to YAML: {output_file}")
        
        # Print some basic statistics
        if "stigs" in data:
            for stig in data["stigs"]:
                print(f"\nSTIG: {stig.get('display_name', 'Unknown')}")
                print(f"Rules count: {len(stig.get('rules', []))}")
                
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON file: {str(e)}")
    except Exception as e:
        print(f"Error processing file: {str(e)}")

if __name__ == "__main__":
    main()