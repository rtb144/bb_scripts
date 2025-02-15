<#
1. Import XML from Stig package. Extract the following:
    - ID
    - RuleID
    - Severity
    - Check Content (code)
    - Indicate what type of query it is (az cli or sql)
2. Store into another XML file.
3. Edit XML file to only keep the code/script aspect


Note: 
    - Need to better structure the xml file. 
    - Could intake params, but too much typing

#>



<#
XCCDF.XML TO CLASS
#>
$export = @()
#C:\Users\1512181607121002.CIV\Documents\azuresqlserverstigs\Powershell_scripts\primary\dictionary\U_MS_Azure_SQL_DB_V2R2_STIG\U_MS_Azure_SQL_DB_V2R2_Manual_STIG\U_MS_Azure_SQL_DB_STIG_V2R2_Manual-xccdf.xml
$StigXml = [xml](Get-Content -Path "..\azuresqlserverstigs\Powershell_scripts\primary\dictionary\U_MS_Azure_SQL_DB_V2R2_STIG\U_MS_Azure_SQL_DB_V2R2_Manual_STIG\U_MS_Azure_SQL_DB_STIG_V2R2_Manual-xccdf.xml") 
foreach ($stig in $StigXml.Benchmark.Group) {
    $row = [Stig]::new(
    $stig.id
    ,$stig.Rule.id
    ,$stig.Rule.severity 
    ,$stig.Rule.check."check-content" )
    $export += $row
}
$ExportXml = $export | ConvertTo-Xml -As "Document" -Depth 1

# DO NOT OVERWRITE
#$ExportXml.Save("..\azuresqlserverstigs\Powershell_scripts\primary\dictionary\exportStig.xml")






foreach ($stig in $StigXml.Benchmark.Group) {
    $rule = $stig.Rule.id
    $id = $stig.id
    ("dict[""$rule""] = ""string"" #$id")
}