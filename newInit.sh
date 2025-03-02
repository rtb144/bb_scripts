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

# Look up the full subscription name and keyvault
SUBSCRIPTION_LINE=
$(grep -i "^${SHORTNAME}:" "$SUBSCRIPTION_FILE")
if [ -z "$
SUBSCRIPTION_LINE" ]; then
    echo "Error: Subscription shortname '
$SHORTNAME' not found in dictionary"
    exit 1
fi

# Parse the line into variables
IFS=':' read -r shortname SUBSCRIPTION_ID keyVaultNameG <<< "$
SUBSCRIPTION_LINE"

if [ -z "
$SUBSCRIPTION_ID" ] || [ -z "$
keyVaultNameG" ]; then
    echo "Error: Invalid dictionary entry format for '
$SHORTNAME'"
    exit 1
fi

echo "working..."

# Set Azure Government cloud
echo "Setting Azure Government cloud..."
az cloud set --name azureusgovernment

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
        echo "Using KeyVault: $
keyVaultNameG"

        # Handle PostgreSQL server selection if -p flag is used
        if [ "
$SELECT_POSTGRES" = true ]; then
            echo -e "\nFetching PostgreSQL Flexible Servers..."
            
            # Get list of PostgreSQL servers and store in array
            readarray -t POSTGRES_SERVERS < <(az postgres flexible-server list --query "[].{Name:name, ResourceGroup:resourceGroup}" --output tsv)
            
            if [ $
{#POSTGRES_SERVERS[@]} -eq 0 ]; then
                echo "No PostgreSQL Flexible Servers found in this subscription"
                exit 1
            fi
            
            echo -e "\nAvailable PostgreSQL Servers:"
            for i in "
${!POSTGRES_SERVERS[@]}"; do
                echo "$((i+1)))${POSTGRES_SERVERS[$
i]}"
            done
            
            # Get user selection
            while true; do
                echo -e "\nSelect a server (1-
${#POSTGRES_SERVERS[@]}):"
                read -r selection
                
                if [[ "$selection" =~ ^[0-9]+$ ]] && \
                   [ "$
selection" -ge 1 ] && \
                   [ "
$selection" -le "$
{#POSTGRES_SERVERS[@]}" ]; then
                    break
                fi
                echo "Invalid selection. Please try again."
            done
            
            # Extract server name and resource group
            selected_server=(
${POSTGRES_SERVERS[$
((selection-1))]})
            serverName=
${selected_server[0]}
            resourceGroup=$
{selected_server[1]}

            echo "Exporting PostgreSQL environment variables..."
            
            # Export PostgreSQL-related variables
            export KeyVaultName=
$keyVaultNameG
            export SecretName=$
serverName-pw
            export serverID=
$(az postgres flexible-server show -n $serverName -g$resourceGroup --query "{Id:id}" -o tsv)
            export PGHOST=$
serverName.postgres.database.usgovcloudapi.net
            export PGUSER=
$(az postgres flexible-server show -g $resourceGroup --name$serverName --query administratorLogin -o tsv | tr -d '"' | tr -d "\r")
            export PGPORT=5432
            export PGDATABASE=postgres
            export PGPASSWORD=$(az keyvault secret show --name$SecretName --vault-name $
KeyVaultName --query value -o json | tr -d '"' | tr -d "\r")

            echo -e "\nEnvironment variables set:"
            echo "KeyVaultName=
$KeyVaultName"
            echo "serverName=$
serverName"
            echo "PGHOST=
$PGHOST"
            echo "PGUSER=$
PGUSER"
            echo "PGPORT=
$PGPORT"
            echo "PGDATABASE=$
PGDATABASE"
            echo "Resource Group=
$resourceGroup"
        fi
        
    else
        echo "Error: Failed to set subscription"
        exit 1
    fi
else
    echo "Error: Azure login failed"
    exit 1
fi
