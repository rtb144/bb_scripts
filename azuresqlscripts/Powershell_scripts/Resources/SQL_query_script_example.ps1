Connect-AzAccount -Environment AzureUSGovernment 
Set-AzContext -Subscription 'AFC-HQAFC-AFCDSE-P'   
#Disconnect-AzAccount    
 
<#
Update-AzConfig -DefaultSubscriptionForLogin 'AFC-HQAFC-AFCDSE-P'    
$PSVersionTable  
#>
 
Install-Module -Name SqlServer   
Import-Module -Name SqlServer -Force
 
 
Get-AzRoleAssignment -Scope "/subscriptions/0a916cc4-630e-42e5-b4d5-f1b1c1be2d94" -PrincipalId "8e379580-d242-4a53-97cf-5b5c30b46180"   
 
Select-AzSubscription -SubscriptionName 'AFC-HQAFC-AFCDSE-P'
 
# Install-Module SQLServer
 
$access_token = (Get-AzAccessToken -ResourceUrl https://database.usgovcloudapi.net).Token
 
#Invoke-Sqlcmd -ServerInstance caz-w0cuaa-dse-p-sql.database.usgovcloudapi.net -Database ModCop-test -AccessToken $access_token -query 'select * from cft_description'
 
<#
Invoke-Sqlcmd -ServerInstance caz-w0cuaa-dse-p-sql.database.usgovcloudapi.net -Database ModCop-test -AccessToken $access_token -query "INSERT INTO STIG.GROUP_TEST (Group_ID
           ,Rule_ID
           ,STIG_ID
           ,Severity
           ,Classification
           ,Finding)
     VALUES
           ('test_group'
           ,'A123'
           ,'STIG_ID'
           ,'CAT I'
           ,'Class 1'
           ,'Y')"
#>
 
Invoke-Sqlcmd -ServerInstance caz-w0cuaa-dse-p-sql.database.usgovcloudapi.net -Database ModCop-test -AccessToken $access_token -query "INSERT INTO STIG.GROUP_TEST (Group_ID
           ,Rule_ID
           ,STIG_ID
           ,Severity
           ,Classification
           ,Finding)
     VALUES
           ('test_group2'
           ,'A456'
           ,'STIG_ID'
           ,'CAT II'
           ,'Class 1'
           ,'N')"
 
 
# Get-Variable -Scope local
 
Get-AzSqlServerActiveDirectoryOnlyAuthentication  -ServerName caz-w0cuaa-dse-p-sql -ResourceGroupName CAZ-W0CUAA-DSE-P-RGP-DATA
 
#Invoke-Sqlcmd -ServerInstance caz-w0cuaa-dse-p-sql.database.usgovcloudapi.net -Database ModCop-test -AccessToken $access_token -query 'select * from cft_description'
#Invoke-Sqlcmd -ServerInstance  caz-w0cuaa-dse-p-sql.database.usgovcloudapi.net -Database ModCop-test -AccessToken $access_token -Query "SELECT @@SERVERNAME as Name, create_date FROM sys.databases Where name='modcop-test'" -ErrorAction Stop -ConnectionTimeout 3
#Write-Output "CHECK $check"     