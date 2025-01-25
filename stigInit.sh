### USE source stigInit.sh

echo "working..."

export SUBSCRIPTION=AFC-HQAFC-AFCDSE-P

az cloud set --name azureusgovernment 
az login
az account set --subscription $SUBSCRIPTION
pwsh -c Connect-AzAccount -Environment AzureUSGovernment -UseDeviceAuthentication -subscription $SUBSCRIPTION


echo "exporting ENV VARs"

export SecretName=posit-pg-pass
export KeyVaultName=CAZDSEPKEYAKS
export resourceGroup=CAZ-W0CUAA-DSE-P-RGP-DATA
export serverName=caz-w0cuaa-dse-p-psql-flex-rsp
export serverID=`az postgres flexible-server show -n $serverName -g $resourceGroup --query "{Id:id}" -o tsv`
export PGHOST=$serverName.postgres.database.usgovcloudapi.net
export PGUSER=afcmade
export PGPORT=5432
export PGDATABASE=postgres
export PGPASSWORD=`az keyvault secret show --name $SecretName --vault-name $KeyVaultName --query value -o json | tr -d '"' | tr -d "\r"`


