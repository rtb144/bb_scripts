

sql script storage: sqlva7roxmb5axhga2

$LogicalServerName = "caz-w0cuaa-dse-p-sql"
$RGname = "CAZ-W0CUAA-DSE-P-RGP-DATA" 
$DBName = "ModCop" 

Get-AzSqlDatabaseTransparentDataEncryption -ServerName $LogicalServerName -ResourceGroupName $RGname -DatabaseName $DBname

Set-AzContext AFC-HQAFC-AFCDSE-P
cmdlet to change the current context. You can use the Get-AzSubscription cmdlet to retrieve a list of your Azure subscriptions.Oct 8, 2024

$ResourceGroup = "myResourceGroup"
$ServerName = "myServerName"
$FormatEnumerationLimit=-1
Get-AzSqlServerAudit -ResourceGroupName $ResourceGroup -ServerName $ServerName


*** need documentation: see above

NOT A FINDING

az sql server ad-only-auth get --resource-group CAZ-W0CUAA-DSE-P-RGP-TRAC  --name caz-w0cuaa-dse-p-trac-sql


$ServerName = "caz-w0cuaa-dse-p-sql"
$RGname = "CAZ-W0CUAA-DSE-P-RGP-DATA" 
$DBName = "ModCop" 

$token = (Get-AzAccessToken -ResourceUrl https://database.usgovcloudapi.net).Token

$token = (Get-AzAccessToken)

Invoke-Sqlcmd -ServerInstance 'caz-w0cuaa-dse-p-sql.database.usgovcloudapi.net' -Database "ModCop" -AccessToken $token -Query "EXEC sp_who2"

Get-AzSqlServerActiveDirectoryOnlyAuthentication  -ServerName $ServerName -ResourceGroupName $RGname

C:\Users\1153903189121002.CIV\AppData\Roaming\Python\Python311\Scripts

$resourceGroupName = (Get-AzureRmResourceGroup | Get-AzureRmSqlServer | where {$_.ServerName -eq 'caz-w0cuaa-dse-p-sql'}).ResourceGroupName

$ServerName = "caz-w0cuaa-dse-p-ai2c-sql"
$DBName = "caz-w0cuaa-dse-p-ai2c-sql-ippsa"
Import-Module SQLServer
Import-Module Az.Accounts -MinimumVersion 2.2.0
