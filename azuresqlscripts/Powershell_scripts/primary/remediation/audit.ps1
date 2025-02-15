

$access_token = (Get-AzAccessToken -ResourceUrl https://database.usgovcloudapi.net).Token
$ServerList = Get-AzSqlServer
$serverlist.ServerName

$workspaceResourceId = "/subscriptions/0a916cc4-630e-42e5-b4d5-f1b1c1be2d94/resourcegroups/caz-w0cuaa-dse-p-rgp-core/providers/microsoft.operationalinsights/workspaces/caz-w0cuaa-dse-p-log"
$logAnalytics = "caz-w0cuaa-dse-p-log"

$RetentionInDays = "90"
$SARGname = "caz-w0cuaa-dse-p-rgp-core"
$StorageAcctName = "cazafcdsepecorestglog"
$StorageAccountResourceId = "/subscriptions/0a916cc4-630e-42e5-b4d5-f1b1c1be2d94/resourceGroups/CAZ-W0CUAA-DSE-P-RGP-CORE/providers/Microsoft.Storage/storageAccounts/cazafcdsepecorestglog"
foreach($Server in $ServerList)
{
    # Sql Token to run queries
    $SN = $Server.ServerName
    $RGN = $Server.ResourceGroupName

    #$data = Get-AzSqlServerAudit -ResourceGroupName $RGN -ServerName $SN | ConvertTo-Json
    Get-AzSqlServerAudit -ResourceGroupName $RGN -ServerName $SN | ConvertTo-Json
    #$data | Out-File -FilePath "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\$SN-AzSqlServerAuditProperty.txt"
    if($false)
    {
        Set-AzSqlServerAudit -ResourceGroupName $RGN -ServerName $SN `
            -LogAnalyticsTargetState Enabled `
            -WorkspaceResourceId $workspaceResourceId `
            -RetentionInDays $RetentionInDays `
            -BlobStorageTargetState Enabled `
            -StorageAccountResourceId $StorageAccountResourceId `
        -AuditActionGroup `
        APPLICATION_ROLE_CHANGE_PASSWORD_GROUP `
        ,BACKUP_RESTORE_GROUP `
        ,DATABASE_CHANGE_GROUP `
        ,DATABASE_LOGOUT_GROUP `
        ,DATABASE_OBJECT_CHANGE_GROUP `
        ,DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP `
        ,DATABASE_OBJECT_PERMISSION_CHANGE_GROUP `
        ,DATABASE_OPERATION_GROUP `
        ,DATABASE_OWNERSHIP_CHANGE_GROUP `
        ,DATABASE_PERMISSION_CHANGE_GROUP `
        ,DATABASE_PRINCIPAL_CHANGE_GROUP `
        ,DATABASE_PRINCIPAL_IMPERSONATION_GROUP `
        ,DATABASE_ROLE_MEMBER_CHANGE_GROUP `
        ,DBCC_GROUP `
        ,FAILED_DATABASE_AUTHENTICATION_GROUP `
        ,SCHEMA_OBJECT_CHANGE_GROUP `
        ,SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP `
        ,SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP `
        ,SCHEMA_OBJECT_ACCESS_GROUP `
        ,SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP `
        ,USER_CHANGE_PASSWORD_GROUP `
        -PredicateExpression " NOT ( `
        (Statement LIKE 'select SERVERPROPERTY(%)')  `
        OR (Statement LIKE 'SELECT @@SPID;'))"
    }
    
    <#
    Set-AzSqlServerAudit -ResourceGroupName $RGN -ServerName $SN `
    -LogAnalyticsTargetState Enabled `
    -WorkspaceResourceId $workspaceResourceId `
    -RetentionInDays $RetentionInDays `
    -BlobStorageTargetState Enabled `
    -StorageAccountResourceId $StorageAccountResourceId `
    -AuditActionGroup `
    APPLICATION_ROLE_CHANGE_PASSWORD_GROUP `
    ,BACKUP_RESTORE_GROUP `
    ,DATABASE_CHANGE_GROUP `
    ,DATABASE_LOGOUT_GROUP `
    ,DATABASE_OBJECT_CHANGE_GROUP `
    ,DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP `
    ,DATABASE_OBJECT_PERMISSION_CHANGE_GROUP `
    ,DATABASE_OPERATION_GROUP `
    ,DATABASE_OWNERSHIP_CHANGE_GROUP `
    ,DATABASE_PERMISSION_CHANGE_GROUP `
    ,DATABASE_PRINCIPAL_CHANGE_GROUP `
    ,DATABASE_PRINCIPAL_IMPERSONATION_GROUP `
    ,DATABASE_ROLE_MEMBER_CHANGE_GROUP `
    ,DBCC_GROUP `
    ,FAILED_DATABASE_AUTHENTICATION_GROUP `
    ,SCHEMA_OBJECT_CHANGE_GROUP `
    ,SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP `
    ,SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP `
    ,SCHEMA_OBJECT_ACCESS_GROUP `
    ,SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP `
    ,USER_CHANGE_PASSWORD_GROUP `
    -PredicateExpression " NOT ((Statement LIKE 'select SERVERPROPERTY(%)') OR (Statement LIKE 'SELECT @@SPID;'))"
    #>
}

$FormatEnumerationLimit   =-1
#Get-AzSqlServerAudit -ResourceGroupName $RGN -ServerName $SN
#Get-AzSqlDatabaseAudit -ResourceGroupName $RGN -ServerName $SN  -DatabaseName $DBN 