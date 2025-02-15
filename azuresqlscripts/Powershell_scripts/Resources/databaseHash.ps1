$hashtable = [ordered]@{
    "AD-G357" = "caz-w0cuaa-dse-p-fcc-sql";

    "caz-w0cuaa-dse-p-ai2c-sql-amap-demo" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-amap-prod" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-amtracks-backup" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-bct-prod" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-centaur-dev" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-centaur-prod" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-griffin-dev" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-griffin-prod" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-griffin-sync" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-griffin-test" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-virtus-prod" = 
    ""
    "caz-w0cuaa-dse-p-ai2c-sql-ippsa" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-recruiting-accounts" = "caz-w0cuaa-dse-p-ai2c-sql";
    "caz-w0cuaa-dse-p-ai2c-sql-recruiting-dev" = "caz-w0cuaa-dse-p-ai2c-sql";

    "caz-w0cuaa-dse-p-usmc-sql-db" = "caz-w0cuaa-dse-p-usmc-sql";

    "ssr-editor" = "caz-w0cuaa-dse-p-sql";
    "ModCop" = "caz-w0cuaa-dse-p-sql";
    "ModCop-Patch-Test" = "caz-w0cuaa-dse-p-sql";
    "ModCop-test" = "caz-w0cuaa-dse-p-sql";
    "AFC-DSE-HUB-DB" = "caz-w0cuaa-dse-p-sql";
    "AFC-DSE-HUB-DB-TEST" = "caz-w0cuaa-dse-p-sql";
    "AFC-DSE-HUB-DB-DEV" = "caz-w0cuaa-dse-p-sql";

    "tedsProdDB" = "caz-w0cuaa-dse-p-trac-sql";
    "tedsTestDB" = "caz-w0cuaa-dse-p-trac-sql";
    "VA-AFC-DDSD-DSE-P-SQL-DB-TRAC-01" = "caz-w0cuaa-dse-p-trac-sql";
    "VA-AFC-DDSD-DSE-P-SQL-DB-TRAC-02" = "caz-w0cuaa-dse-p-trac-sql";
    "VA-AFC-DDSD-DSE-P-SQL-DB-TRAC-04" = "caz-w0cuaa-dse-p-trac-sql";
    "vastr" = "caz-w0cuaa-dse-p-trac-sql";

    "AFC_HQ_CIO_CMAD_ITPortfolioRationalization" = "caz-w0cuaa-dse-p-cmad-sql";
    
    "DCA2_JMC_NIPR" = "caz-w0cuaa-dse-p-jmc-sql"
}

foreach ($db in $hashtable.Keys)
{
    
    $resourceGroupName = (Get-AzureRmResourceGroup | Get-AzureRmSqlServer | where {$_.ServerName -eq $hashtable[$db]}).ResourceGroupName
    ##Write-Host "$db on $($hashtable[$db]) in resource group $resourceGroupName"
    Get-AzSqlDatabaseTransparentDataEncryption -ServerName $hashtable[$db] -ResourceGroupName $resourceGroupName -DatabaseName $db
    Write-Host 
}