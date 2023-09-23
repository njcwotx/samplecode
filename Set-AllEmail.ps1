Import-Module "C:\Scripts\Nathan\DellStoragePowerShellSDK_v3_3_1_58\DellStorage.ApiCommandSet.psd1"

$report = @()
$dslist= @()
$rdmlist = @()

$mm = $(Get-Date).Month
$dd = $(Get-Date).Day
$yy = $(Get-Date).Year
$hour = $(Get-Date).Hour
$minute = $(Get-Date).Minute

$AllEmailInfo = @()

$DSMList = Import-CSV .\dsm.txt
foreach($dsm in $DSMList){

$infoAdd = "" | Select DataCenter,BusinessUnit,DsmIP
$infoAdd.DataCenter = $dsm.DC
$infoAdd.BusinessUnit = $dsm.BU 
$infoAdd.DsmIP = $dsm.IP

$DSMPassword = ConvertTo-SecureString $dsm.Password -AsPlainText -Force

$DSMConnection = Connect-DellApiConnection -HostName $dsm.IP -User $dsm.Username -Password $DSMPassword
$DSMConnection
$infoAdd | ft -auto

$ControllerInfo = Get-DellScController -Connection $DSMConnection | Sort ScSerialNumber | Select ScSerialNumber,Name,UniqueName,HardwareSerialNumber,Model,ServiceTag,IpAddress,BmcIpAddress,Version,ScName,InstanceName,InstanceId,Leader,LastBootTime,DateCreated,DateUpdated


foreach($obj in $ControllerInfo){

    if ($obj.Leader -like "True"){
        
        $users = Get-DellScUser -Connection $DSMConnection -ScSerialNumber $obj.ScSerialNumber
        $AdminUser = $users | ?{ $_.Name -eq "Admin"}
        Set-DellScUser -Instance $AdminUser -EmailAddress "email@anotherdomain.com" -EmailAddress2  "email@somedomain.com" -EmailAddress3 "email2@domain.com" -Connection $DSMConnection
    
    }
} # end of Merge Controller Info

Disconnect-DellApiConnection -Connection $DSMConnection


} # end foreach DSM
