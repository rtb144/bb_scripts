import sys
import argparse

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Server management utility'
    )
    parser.add_argument(
        '-a', '--all',
        action='store_true',
        help='Process all servers in subscription'
    )
    parser.add_argument(
        'server_name',
        nargs='?',
        help='Name of specific server to process'
    )
    
    args = parser.parse_args()
    
    # Validation logic
    if not args.all and not args.server_name:
        parser.error("Either --all flag or server name must be provided")
    if args.all and args.server_name:
        parser.error("Cannot specify both --all and server name")
        
    return args

def process_all_servers():
    print("Processing all servers...")
    # Add logic for processing all servers
    
def process_single_server(server_name):
    print(f"Processing server: {server_name}")
    # Add logic for processing single server

def main():
    args = parse_arguments()
    
    if args.all:
        process_all_servers()
    else:
        process_single_server(args.server_name)

if __name__ == "__main__":
    main()
