$storageResourceGroup = "CAZ-W0CUAA-DSE-P-RGP-DATA"
$storageAccountName = "sqlva7roxmb5axhga2"
$containerName = "sql-stig-scripts"
$blobName = "servertodb.ps1"
$localFilePath = "test.ps1"
Set-AzCurrentStorageAccount -ResourceGroupName $storageResourceGroup -Name $storageAccountName

$blob = Get-AzStorageBlobContent -Container $containerName -Blob $blobName 

$scriptContent = $blob.ICloudBlob.DownloadText()
