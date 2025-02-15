class StigResultOutput {
    [string]$ServerName
    [string]$DatabaseName
    [string]$RuleId
    [string]$Finding
    StigResult (
        [string]$ServerName
        ,[string]$DatabaseName
        ,[string]$RuleId
        ,[string]$Finding
    ) {
        $this.ServerName = $ServerName
        $this.DatabaseName = $DatabaseName
        $this.RuleId = $RuleId
        $this.Finding = $Finding
    }
}

##### RESULTS
$ServerList = Get-AzSqlServer
$total = @{}
$data =@()
foreach($Server in $ServerList)
{
    # Sql Token to run queries
    $SN = $Server.ServerName
    $RGN = $Server.ResourceGroupName
    $DBList = Get-AzSqlDatabase -ResourceGroupName $RGN -ServerName $SN
    foreach ($db in $DBList)
    {
        $DBN = $db.DatabaseName
        $filepath = "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\$SN\$DBN\$DBN-cmrs.xml"
        if ((Test-Path -Path $filepath)){
            [xml]$xmlData = (Get-Content -Path $filepath) 
            foreach ($stig in $xmlData.IMPORT_FILE.ASSET.TARGET.FINDING) 
            {
                $data += [StigResultOutput]::new(
                    $SN
                    ,$Dbn
                    ,$stig.FINDING_ID.ID
                    ,$stig.FINDING_STATUS 
                )
            }
        }
        else {
            $false
        }
    }
}

$data | Export-CSV -Path "..\azuresqlserverstigs\Powershell_scripts\primary\stigresultdump\listoffindings$(Get-Date -Format "yyyyMMddHHmm").csv" -NoTypeInformation


foreach ($r in $data)
{
    if($r.RuleId -eq "SV-255301r960768_rule" -and $r.Finding -ne "NF" -and $r.DatabaseName -ne "master")
    {
         """" + $r.ServerName+ """, """+$r.databasename + """" 
    
    }
}




