<#
Loading Custom XML to $StigCheckList Variable
#>

$CheckXml = [xml](Get-Content -Path "..\azuresqlserverstigs\Powershell_scripts\primary\dictionary\exportStig.xml") 
$global:StigCheckList = @()
foreach ($a in $CheckXml.Objects.object)
{  
    $row = [Stig]::new()
   foreach($b in $a.Property)
   {
        if($b.Name -eq "Id") { $row.Id = $b."#Text" }
        elseif ($b.Name -eq "RuleId") { $row.RuleId = $b."#Text" }
        elseif ($b.Name -eq "Severity") { $row.Severity = $b."#Text" }
        elseif ($b.Name -eq "Code") { $row.Code = $b."#Text" }
        elseif ($b.Name -eq "Method") { $row.Method = $b."#Text" }
   }
   $StigCheckList += $row
}