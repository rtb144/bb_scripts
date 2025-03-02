### USE source psqlInit.sh

echo "working..."

# make sure we're set for azure gov space
az cloud set --name azureusgovernment

# set subscription we should use
export SUBSCRIPTION=AFC-HQAFC-AFCDSE-P
serverNameG=caz-w0cuaa-dse-p-psql-flex-xray1


### set proper AKS key vault based on subscription
case $SUBSCRIPTION in 
    "AFC-HQAFC-AFCDSE-P") 
        keyVaultNameG="CAZDSEPKEYAKS"
        ;;
    "AFC-HQAFC-AFCDSE-T")
        keyVaultNameG="KEYAFCDSEAKS"
        ;;
    "AFC-HQAFC-AFCDSE-D")
        keyVaultNameG="KEYAFCDSEDECOREAKS"
        ;;
    *)
        echo "key vault not found"
        exit 1
        ;;
esac
## check if already logged in
##account_state=`az account show --query "state" -o tsv | tr -d "\r" | cat -v 2>/dev/null`

 
az login
az account set --subscription $SUBSCRIPTION
echo "exporting ENV VARs"

## uncomment if using powershell
#pwsh -c Connect-AzAccount -Environment AzureUSGovernment -UseDeviceAuthentication -subscription $SUBSCRIPTION

export KeyVaultName=$keyVaultNameG
export serverName=$serverNameG
export SecretName=$serverName-pw
export resourceGroup=`az resource list -n $serverName --query "[].resourceGroup" -o tsv | tr -d '\r'`
export serverID=`az postgres flexible-server show -n $serverName -g $resourceGroup --query "{Id:id}" -o tsv`
export PGHOST=$serverName.postgres.database.usgovcloudapi.net
export PGUSER=`az postgres flexible-server show -g $resourceGroup --name $serverName --query administratorLogin -o tsv | tr -d '"' | tr -d "\r"`
export PGPORT=5432
export PGDATABASE=postgres
export PGPASSWORD=`az keyvault secret show --name $SecretName --vault-name $KeyVaultName --query value -o json | tr -d '"' | tr -d "\r"`


