<# Run the scripts manually, havent had type to write globals
Run in this order:
    -> classlib.psm1
    -> load-stig.ps1
#>

#using module ..\primary\classlib.psm1
#pwsh ..\azuresqlserverstigs\Powershell_scripts\primary\load-stig.ps1

$ErrorActionPreference = 'STOP '

function Get-PassingCriteria {
    param (
        [string]$RuleID
        ,[string]$Text
    )

    if( $null -eq $text ) { return $false }
    elseif (  $null -ne $dict[$RuleID] )
    {
        $validate = $false
        foreach($item in $dict[$RuleID])
        {
            if($Text -match $item)
            {
                $validate = $true
            }
            else { return $false }
        }
        return $validate
    }
    else {
        return $false
    }
    
}

$ServerList = Get-AzSqlServer

foreach($Server in $ServerList)
{
    # Sql Token to run queries
    $SN = $Server.ServerName
    $RGN = $Server.ResourceGroupName
    $DBList = Get-AzSqlDatabase -ResourceGroupName $RGN -ServerName $SN
    foreach ($db in $DBList)
    {
        if($db.DatabaseName -eq "master") { continue }
        $DBN = $db.DatabaseName
        $LogicalServerName = $SN
        $ServerName = $SN

        $RGname = $RGN
        $ResourceGroup = $RGN
        $ResourceGroupName = $RGN

        $DBName = $DBN
        $AzureSqlDbName = $DBN
        
        #Storage Blob
        $SARGname = "caz-w0cuaa-dse-p-rgp-core"
        $StorageAcctName = "cazafcdsepecorestglog"
        
        $DBN
        [xml]$blankckl = (Get-Content -Path "..\azuresqlserverstigs\Powershell_scripts\primary\dictionary\stig_azsql_blank - cmrs.xml") 
        $StigResultList = @()
        $access_token = (Get-AzAccessToken -ResourceUrl https://database.usgovcloudapi.net).Token
        <#
        store data
        #>
        foreach ($a in $StigCheckList)
        {
            $DBN + "," + $a.RuleId
            if($a.Method -eq 1)
            {   
                $res = Invoke-Sqlcmd -ServerInstance $Server.FullyQualifiedDomainName -Database $DBName -AccessToken $access_token -query $a.Code | Out-String
                $StigResultList += [StigResult]::new($a.Id,$a.RuleId,$res)
            }
            if($a.Method -eq 0)
            {   
                if(($a.RuleId -eq "SV-255321r1018558_rule" -or 
                $a.RuleId -eq "SV-255322r1018559_rule" -or
                $a.RuleId -eq "SV-255339r961128_rule") -and $DBN -eq "master")
                {
                    $res = "Master DB cannot enable Transparent Data Encryption (TDE) because it contains system objects. `n(Source: https://learn.microsoft.com/en-us/azure/azure-sql/database/transparent-data-encryption-tde-overview?view=azuresql&tabs=azure-portal)"
                    $StigResultList += [StigResult]::new($a.Id,$a.RuleId,$res)
                }
                elseif($a.RuleId -eq "SV-255320r962034_rule" -and $DBN -eq "master")
                {
                    $res = "Master DB cannot enable encrypted. `n(Source: https://learn.microsoft.com/en-us/sql/relational-databases/databases/system-databases?view=azuresqldb-current)"
                    $StigResultList += [StigResult]::new($a.Id,$a.RuleId,$res)
                }
                else {
                    $res = Invoke-Expression $a.Code | Out-String
                    $StigResultList += [StigResult]::new($a.Id,$a.RuleId,$res)
                }
            }
            if($a.Method -eq 2)
            {   
                $res = $autopass[$a.RuleId]
                $StigResultList += [StigResult]::new($a.Id,$a.RuleId,$res)
            }
        }
        if (!(Test-Path -Path "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\$DBN")) {
            New-Item -ItemType Directory -Path "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\$DBN"
        }


        <#
        export location
        #>
        $StigResultList | Export-CSV -Path "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\$DBN\$DBN-results.csv" -NoTypeInformation
        
        [xml]$blankckl = (Get-Content -Path "..\azuresqlserverstigs\Powershell_scripts\primary\dictionary\stig_azsql_blank - cmrs.xml") 
        foreach ($stig in $blankckl.IMPORT_FILE.ASSET.TARGET.FINDING) {

            foreach ($row in $StigResultList)
            {
                if($stig.FINDING_ID.ID -eq $row.RuleId -and $null -ne $row.Result )
                { 
                    $commentDump = "Script ran and results are automatically imported into dialog on $(Get-Date). `n`n"
                    $state = Get-PassingCriteria -RuleID $row.RuleID -Text $row.Result
                    if( $DBN -eq "master" -and
                            ($row.RuleId -eq "SV-255321r1018558_rule" -or 
                            $row.RuleId -eq "SV-255322r1018559_rule" -or
                            $row.RuleId -eq "SV-255339r961128_rule" -or 
                            $row.RuleId -eq"SV-255320r962034_rule") ) { $state = $true}

                    if($state)
                    {   
                        $stig.finding_status = "NF"
                        $commentDump += "Based on results, there is no finding. "
                    }
                    else
                    {
                        $stig.finding_status = "O"
                        $commentDump += "Based on results, there is finding or false negative."
                    }
                    $commentDump += $row.Result
                    $stig.COMMENT = $commentDump
                }
            }
        }
        $blankckl.Save("..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\$DBN\$DBN-cmrs.xml")
    }
}



