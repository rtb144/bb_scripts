
<####################################################
#####################################################
 Environment Variables
#####################################################
#####################################################>

<####################################################
AZ LOGIN
#####################################################>
#$cloud = "AzureUSGovernment"
#$subName = "AFC-HQAFC-AFCDSE-P"
#$region = "usgovvirginia"

# Set the USG links/settings and login via browser
#az cloud set --name $cloud
#if($(az account show) -eq $null)
#{
#    az login --use-device-code
#}

#az account set --subscription $subName
# az account show

<####################################################
GET AZ SQL SERVER LIST
#####################################################>
#$ServerList = az sql server list | ConvertFrom-Json
#foreach ($Server in $ServerList)
#{
#    $Server.name 
#    #+ "; " + $Server.fullyQualifiedDomainName
#}


<####################################################
Server Connection
#####################################################>
# Install-Module -Name SqlServer   
# Import-Module -Name SqlServer -Force
# Import-Module -Name Az.Accounts -Force
# Import-Module -Name Az.Sql -force
# Install-Module AzTable -Force
# Install-Module Az.Monitor -Force
# Install-Module SQLServer
# Install-Module Az.Storage -Force


# Connect via browsers
Connect-AzAccount -Environment AzureUSGovernment -DeviceCode


# Set subscriptions
# Get-AzRoleAssignment -Scope "/subscriptions/0a916cc4-630e-42e5-b4d5-f1b1c1be2d94" -PrincipalId "8e379580-d242-4a53-97cf-5b5c30b46180"   
# Select-AzSubscription -SubscriptionName 'AFC-HQAFC-AFCDSE-P'
 

# Sql Token to run queries
$access_token = (Get-AzAccessToken -ResourceUrl https://database.usgovcloudapi.net).Token




#create ckl from blank template
$ErrorActionPreference = 'SilentlyContinue '
$ServerList = Get-AzSqlServer
foreach($Server in $ServerList)
{
    # Sql Token to run queries
    $SN = $Server.ServerName
    $RGN = $Server.ResourceGroupName
    $DBList = Get-AzSqlDatabase -ResourceGroupName $RGN -ServerName $SN
    foreach ($db in $DBList)
    {
        
        $DBN = $db.DatabaseName
        if (!(Test-Path -Path "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\$DBN")) {
            New-Item -ItemType Directory -Path "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\$DBN"
        }
        Copy-Item C:\Users\1512181607121002.CIV\Documents\azuresqlserverstigs\Powershell_scripts\primary\dictionary\stig_azsql_blank.cklb "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\stig-azsql-$DBN.cklb"
        #Remove-Item "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\$DBN\stig-azsql-$DBN.cklb"
    }
}

