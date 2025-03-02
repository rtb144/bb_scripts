#!/bin/bash

# Initialize variables
SHORTNAME=""
SELECT_POSTGRES=false
SUBSCRIPTION_FILE="subscriptions.txt"

# Parse command line arguments
while getopts "p" opt; do
    case $
opt in
        p)
            SELECT_POSTGRES=true
            ;;
        \?)
            echo "Invalid option: -
$OPTARG"
            exit 1
            ;;
    esac
done

# Shift the options so $
1 becomes the first non-option argument
shift
$((OPTIND-1))

# Check if a parameter was provided
if [ $
# -eq 0 ]; then
    echo "Error: Please provide a subscription shortname as parameter"
    echo "Usage:
$0 [-p] <subscription-shortname>"
    exit 1
fi

SHORTNAME=$
1

# Check if the subscription file exists
if [ ! -f "
$SUBSCRIPTION_FILE" ]; then
    echo "Error: Subscription dictionary file '$
SUBSCRIPTION_FILE' not found"
    exit 1
fi

# Look up the full subscription name
SUBSCRIPTION_ID=
$(grep -i "^${SHORTNAME}:" "$SUBSCRIPTION_FILE" | cut -d':' -f2)

if [ -z "$
SUBSCRIPTION_ID" ]; then
    echo "Error: Subscription shortname '
$SHORTNAME' not found in dictionary"
    exit 1
fi

# Login to Azure and set subscription
echo "Logging into Azure..."
az login

if [ $
? -eq 0 ]; then
    echo "Setting subscription to:
$SUBSCRIPTION_ID"
    az account set --subscription "$
SUBSCRIPTION_ID"
    
    if [
$? -eq 0 ]; then
        echo "Successfully set subscription"
        az account show
        
        # Handle PostgreSQL server selection if -p flag is used
        if [ "$
SELECT_POSTGRES" = true ]; then
            echo -e "\nFetching PostgreSQL Flexible Servers..."
            
            # Get list of PostgreSQL servers and store in array
            readarray -t POSTGRES_SERVERS < <(az postgres flexible-server list --query "[].{Name:name, ResourceGroup:resourceGroup}" --output tsv)
            
            if [
${#POSTGRES_SERVERS[@]} -eq 0 ]; then
                echo "No PostgreSQL Flexible Servers found in this subscription"
                exit 1
            fi
            
            echo -e "\nAvailable PostgreSQL Servers:"
            for i in "$
{!POSTGRES_SERVERS[@]}"; do
                echo "
$((i+1))) ${POSTGRES_SERVERS[$i]}"
            done
            
            # Get user selection
            while true; do
                echo -e "\nSelect a server (1-$
{#POSTGRES_SERVERS[@]}):"
                read -r selection
                
                if [[ "
$selection" =~ ^[0-9]+$
]] && \
                   [ "
$selection" -ge 1 ] && \
                   [ "$selection" -le "${#POSTGRES_SERVERS[@]}" ]; then
                    break
                fi
                echo "Invalid selection. Please try again."
            done
            
            # Extract server name and resource group
            selected_server=(${POSTGRES_SERVERS[$((selection-1))]})
            POSTGRES_SERVER_NAME=$
{selected_server[0]}
            POSTGRES_RESOURCE_GROUP=
${selected_server[1]}
            
            echo -e "\nSelected server: $
POSTGRES_SERVER_NAME"
            echo "Resource group:
$POSTGRES_RESOURCE_GROUP"
            
            # Get admin username
            POSTGRES_ADMIN=$
(az postgres flexible-server show \
                           --name "
$POSTGRES_SERVER_NAME" \
                           --resource-group "$
POSTGRES_RESOURCE_GROUP" \
                           --query "administratorLogin" \
                           --output tsv)
            
            # Export variables for use in psql
            export PGSERVER="
$POSTGRES_SERVER_NAME"
            export PGUSER="$
POSTGRES_ADMIN"
            export PGRESOURCEGROUP="
$POSTGRES_RESOURCE_GROUP"
            
            echo -e "\nEnvironment variables set:"
            echo "PGSERVER=$
PGSERVER"
            echo "PGUSER=
$PGUSER"
            echo "PGRESOURCEGROUP=$
PGRESOURCEGROUP"
            
            echo -e "\nYou can now use these variables for psql connection"
            echo "Example: psql -h \
$PGSERVER.postgres.database.azure.com -U \$
PGUSER"
        fi
    else
        echo "Error: Failed to set subscription"
        exit 1
    fi
else
    echo "Error: Azure login failed"
    exit 1
fi
