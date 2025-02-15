
Set-AzContext AFC-HQAFC-AFCDSE-P

[Collections.ArrayList]$serverArrayList = 
@(
    'caz-w0cuaa-dse-p-ai2c-sql',  
    'caz-w0cuaa-dse-p-cmad-sql',
    'caz-w0cuaa-dse-p-fcc-sql',
    'caz-w0cuaa-dse-p-jmc-sql',
    'caz-w0cuaa-dse-p-mxcmd-sql',
    'caz-w0cuaa-dse-p-sql',
    'caz-w0cuaa-dse-p-sql-dsit',
    'caz-w0cuaa-dse-p-trac-sql',
    'caz-w0cuaa-dse-p-usmc-sql'

)




foreach ($server in $serverArrayList)
{
    $resourceGroupName = (Get-AzureRmResourceGroup | Get-AzureRmSqlServer | where {$_.ServerName -eq $server}).ResourceGroupName
    Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $server 
}

foreach ($server in $serverArrayList)
{
    $resourceGroupName = (Get-AzureRmResourceGroup | Get-AzureRmSqlServer | where {$_.ServerName -eq $server}).ResourceGroupName
    $FormatEnumerationLimit=-1
    Get-AzSqlServerAudit -ResourceGroupName $resourceGroupName -ServerName $server | Select-Object ServerName, PredicateExpression 
}

