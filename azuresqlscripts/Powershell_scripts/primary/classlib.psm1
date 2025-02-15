
class Stig {
    [string]$Id 
    [string]$RuleId
    [string]$Severity
    [string]$Code
    [int]$Method
    Stig (
        [string]$Id 
        ,[string]$RuleId
        ,[string]$Severity
        ,[string]$Code
    ) {
        $this.Id = $Id
        $this.RuleId = $RuleId
        $this.Severity = $Severity
        $this.Code = $Code
        $this.Method= -1
    }
    Stig (

    ) {
        $this.Id = $null
        $this.RuleId = $null
        $this.Severity = $null
        $this.Code = $null
        $this.Method= -1
    }
}

class StigResult {
    [string]$Id 
    [string]$RuleId
    [string]$Result
    StigResult (
        [string]$Id 
        ,[string]$RuleId
        ,[string]$Result
    ) {
        $this.Id = $Id
        $this.RuleId = $RuleId
        $this.Result = $Result
    }
}

Class DataBase{
    [String]$Server
    [String]$ResourceGroup
    [String]$Database
    StigResult (
        [String]$Server
        ,[String]$ResourceGroup
        ,[String]$Database
    ) {
        $this.Server = $Server
        $this.ResourceGroup = $ResourceGroup
        $this.Database = $Database
    }
}

$dict = New-Object 'system.collections.generic.dictionary[string,string[]]'
$dict["SV-255301r960768_rule"] = @("True") #V-255301
$dict["SV-255302r960792_rule"] = @("db_owner") #V-255302
#$dict["SV-255303r960792_rule"] = " " #V-255303
$dict["SV-255304r960864_rule"] = @("No shared accounts.") #V-255304
#$dict["SV-255305r960864_rule"] = " " #V-255305
#$dict["SV-255306r960960_rule"] = " " #V-255306
#$dict["SV-255307r960960_rule"] = " " #V-255307
#$dict["SV-255308r961131_rule"] = " " #V-255308
#$dict["SV-255309r961149_rule"] = " " #V-255309
#$dict["SV-255310r961158_rule"] = " " #V-255310
#$dict["SV-255311r961158_rule"] = " " #V-255311
#$dict["SV-255312r961158_rule"] = " " #V-255312
$dict["SV-255313r961269_rule"] = @("Environment does not require labeling.")  #V-255313
$dict["SV-255314r961272_rule"] = @("Environment does not require labeling.")  #V-255314
$dict["SV-255315r961275_rule"] = @("Environment does not require labeling.") #V-255315
#$dict["SV-255316r961317_rule"] = " " #V-255316
#$dict["SV-255317r961359_rule"] = " " #V-255317
$dict["SV-255318r1018606_rule"] = "db_owner" #V-255318
#$dict["SV-255319r961461_rule"] = " " #V-255319
$dict["SV-255320r962034_rule"] = @("ENCRYPTED") #V-255320
$dict["SV-255321r1018558_rule"] = @("Enabled") #V-255321
$dict["SV-255322r1018559_rule"] = @("Enabled") #V-255322
#$dict["SV-255323r961656_rule"] = " " #V-255323
$dict["SV-255324r960879_rule"] = @("Enabled") #V-255324
$dict["SV-255325r960882_rule"] =@("Auditing is done through a managed instance governed by azure entra with role permission.") #V-255325
$dict["SV-255326r960885_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255326
$dict["SV-255327r960885_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255327
$dict["SV-255328r960888_rule"] = @("is_state_enabled           : True") #V-255328
$dict["SV-255329r960909_rule"] = "Audit logs are stored in third party (log analytics and blob storage)" #V-255329
#$dict["SV-255330r960930_rule"] = " " #V-255330
#$dict["SV-255331r960933_rule"] = " " #V-255331
#$dict["SV-255332r960936_rule"] = " " #V-255332
$dict["SV-255333r960963_rule"] = @("System Does not contain vendor-provided demonstration or sample databases, database applications, objects, and files.") #V-255333
#$dict["SV-255334r960966_rule"] = " " #V-255334
$dict["SV-255335r960969_rule"] = @("No shared accounts.") #V-255335
$dict["SV-255336r961044_rule"] = @("True") #V-255336
$dict["SV-255337r961053_rule"] = @("No shared accounts.") #V-255337
#$dict["SV-255338r961095_rule"] = " " #V-255338
$dict["SV-255339r961128_rule"] = @("Enabled") #V-255339
#$dict["SV-255340r961221_rule"] = " " #V-255340
#$dict["SV-255341r961353_rule"] = " " #V-255341
$dict["SV-255343r961392_rule"] = @("Enabled") #V-255343
#$dict["SV-255344r961398_rule"] = " " #V-255344
$dict["SV-255345r1018607_rule"] = @("APPLICATION_ROLE_CHANGE_PASSWORD_GROUP","BACKUP_RESTORE_GROUP",
"DATABASE_CHANGE_GROUP","DATABASE_OBJECT_CHANGE_GROUP","DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP",
"DATABASE_OBJECT_PERMISSION_CHANGE_GROUP","DATABASE_OPERATION_GROUP","DATABASE_OWNERSHIP_CHANGE_GROUP",
"DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_PRINCIPAL_CHANGE_GROUP","DATABASE_PRINCIPAL_IMPERSONATION_GROUP",
"DATABASE_ROLE_MEMBER_CHANGE_GROUP","DBCC_GROUP","SCHEMA_OBJECT_CHANGE_GROUP","SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP",
"SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP","USER_CHANGE_PASSWORD_GROUP") #V-255345
#$dict["SV-255346r961470_rule"] = " " #V-255346
#$dict["SV-255347r961470_rule"] = " " #V-255347
$dict["SV-255348r961638_rule"] = @("1.2") #V-255348
$dict["SV-255349r961641_rule"] = @("1.2") #V-255349
$dict["SV-255350r961791_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255350
$dict["SV-255351r961791_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255351
$dict["SV-255352r961797_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255352
$dict["SV-255353r961797_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255353
$dict["SV-255354r961800_rule"] = @("DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP", "DATABASE_OWNERSHIP_CHANGE_GROUP","DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_ROLE_MEMBER_CHANGE_GROUP",
                                    "SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP") #V-255354
$dict["SV-255355r961800_rule"] = @("DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP",
                                    "DATABASE_OWNERSHIP_CHANGE_GROUP","DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_ROLE_MEMBER_CHANGE_GROUP",
                                    "SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP")  #V-255355
$dict["SV-255356r961800_rule"] = @("DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP",
                                    "DATABASE_OWNERSHIP_CHANGE_GROUP","DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_ROLE_MEMBER_CHANGE_GROUP","SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP",
                                    "SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP") #V-255356
$dict["SV-255357r961800_rule"] = @("DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP",
                                    "DATABASE_OWNERSHIP_CHANGE_GROUP","DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_ROLE_MEMBER_CHANGE_GROUP","SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP",
                                    "SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP") #V-255357
$dict["SV-255358r961803_rule"] = @("SCHEMA_OBJECT_CHANGE_GROUP") #V-255358
$dict["SV-255359r961803_rule"] = @("SCHEMA_OBJECT_CHANGE_GROUP") #V-255359
$dict["SV-255360r961809_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255360
$dict["SV-255361r961809_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255361
$dict["SV-255362r961812_rule"] = @("DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP",
                                    "DATABASE_OWNERSHIP_CHANGE_GROUP","DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_ROLE_MEMBER_CHANGE_GROUP","SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP",
                                    "SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP") #V-255362
$dict["SV-255363r961812_rule"] = @("DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP",
                                    "DATABASE_OWNERSHIP_CHANGE_GROUP","DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_ROLE_MEMBER_CHANGE_GROUP","SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP",
                                    "SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP") #V-255363
$dict["SV-255364r961818_rule"] = @("SCHEMA_OBJECT_CHANGE_GROUP") #V-255364
$dict["SV-255365r961818_rule"] = @("SCHEMA_OBJECT_CHANGE_GROUP") #V-255365
$dict["SV-255366r961821_rule"] = @("SCHEMA_OBJECT_CHANGE_GROUP") #V-255366
$dict["SV-255367r961821_rule"] = @("SCHEMA_OBJECT_CHANGE_GROUP") #V-255367
$dict["SV-255368r961824_rule"] = @("SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP") #V-255368
$dict["SV-255369r961824_rule"] = @("SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP") #V-255369
$dict["SV-255370r961827_rule"] = @("APPLICATION_ROLE_CHANGE_PASSWORD_GROUP","BACKUP_RESTORE_GROUP","DATABASE_CHANGE_GROUP","DATABASE_OBJECT_CHANGE_GROUP","DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP","DATABASE_OPERATION_GROUP","DATABASE_OWNERSHIP_CHANGE_GROUP","DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_PRINCIPAL_CHANGE_GROUP","DATABASE_PRINCIPAL_IMPERSONATION_GROUP","DATABASE_ROLE_MEMBER_CHANGE_GROUP","DBCC_GROUP","SCHEMA_OBJECT_CHANGE_GROUP","SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP","SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP","USER_CHANGE_PASSWORD_GROUP") #V-255370
$dict["SV-255371r961827_rule"] = @("APPLICATION_ROLE_CHANGE_PASSWORD_GROUP","BACKUP_RESTORE_GROUP","DATABASE_CHANGE_GROUP","DATABASE_OBJECT_CHANGE_GROUP","DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP","DATABASE_OPERATION_GROUP","DATABASE_OWNERSHIP_CHANGE_GROUP","DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_PRINCIPAL_CHANGE_GROUP","DATABASE_PRINCIPAL_IMPERSONATION_GROUP","DATABASE_ROLE_MEMBER_CHANGE_GROUP","DBCC_GROUP","SCHEMA_OBJECT_CHANGE_GROUP","SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP","SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP","USER_CHANGE_PASSWORD_GROUP") #V-255371
$dict["SV-255372r961830_rule"] = @("APPLICATION_ROLE_CHANGE_PASSWORD_GROUP","BACKUP_RESTORE_GROUP","DATABASE_CHANGE_GROUP","DATABASE_OBJECT_CHANGE_GROUP","DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP","DATABASE_OPERATION_GROUP","DATABASE_OWNERSHIP_CHANGE_GROUP","DATABASE_PERMISSION_CHANGE_GROUP","DATABASE_PRINCIPAL_CHANGE_GROUP","DATABASE_PRINCIPAL_IMPERSONATION_GROUP","DATABASE_ROLE_MEMBER_CHANGE_GROUP","DBCC_GROUP","SCHEMA_OBJECT_CHANGE_GROUP","SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP","SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP","USER_CHANGE_PASSWORD_GROUP") #V-255372
$dict["SV-255373r961833_rule"] = @("SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP") #V-255373
$dict["SV-255374r961836_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255374
$dict["SV-255375r961836_rule"] = @("SCHEMA_OBJECT_ACCESS_GROUP") #V-255375
$dict["SV-255376r961839_rule"] = @("SPID","SERVERPROPERTY") #V-255376
$dict["SV-255377r961860_rule"] = @("Microsoft.Storage/storageAccounts/blobServices/containers/immutabilityPolicies") #V-255377


$autofail = New-Object 'system.collections.generic.dictionary[string,string]'

$autopass = New-Object 'system.collections.generic.dictionary[string,string]'
$autopass["SV-255337r961053_rule"] = "No shared accounts. Users are required to have CAR and sign on via Entra" #V-255337
$autopass["SV-255335r961053_rule"] = "No shared accounts. Users are required to have CAR and sign on via Entra" #V-255335
$autopass["SV-255333r960963_rule"] = "System does not contain vendor-provided demonstration or sample databases, database applications, objects, and files." #V-255333
$autopass["SV-255304r960864_rule"] = "No shared accounts. Users are required to have CAR and sign on via Entra" #V-255304
$autopass["SV-255329r960909_rule"] = "Audit logs are stored in third party (log analytics and blob storage)"
$autopass["SV-255325r960882_rule"] = "Auditing is done through a managed instance governed by azure entra with role permission." #V-255325
$autopass["SV-255315r961275_rule"] = "Environment does not require labeling." #V-255315
$autopass["SV-255313r961269_rule"] = "Environment does not require labeling."  #V-255313
$autopass["SV-255314r961272_rule"] = "Environment does not require labeling."  #V-255314