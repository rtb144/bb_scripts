# Connect to Azure
Connect-AzAccount 

# Set variables
$resourceGroupName = "yourresourcegroupname"
$storageAccountName = "yourstorageaccountname"
$containerName = "yourcontainername"
$blobName = "results.csv"

# Get storage context
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Generate results
$results = Get-Process 
$resultsString = $results | ConvertTo-Csv -NoTypeInformation

# Upload results to blob storage
Set-AzStorageBlobContent -Container $containerName -Blob $blobName -File ".\results.csv" -Context $storageContext
