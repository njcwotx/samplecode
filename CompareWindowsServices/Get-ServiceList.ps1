# get-ServiceList.ps1
param(
    [Parameter(Position=0,mandatory=$true)]
    [PSObject]$ServerList,
    [Parameter(Position=1,mandatory=$true)]
    [string] $ChgNum
)

$outputFile = "./ServicesList-$chgNum-$(get-date -f MMddyy-hhmm).csv"

$AllServerServices = @()

$Servers = Get-Content ./$ServerList






#$svcs = get-service -ComputerName  USAWSITEDC002D | Select Name,RequiredServices,Container,DependentServices,DisplayName,MachineName,Servicehandle,ServiceName,ServicesDependsOn,ServiceType,Status,StartType

#$svcs | Select MachineName,Name,DisplayName,ServiceHandle,Status,StartType,ServiceName,RequiredServices,DependentServices | ft

foreach($server in $Servers){

    $svcs = get-service -ComputerName  $server | Select MachineName,Name,DisplayName,Status,StartType,ServiceName
    
   
    foreach($svc in $svcs){
        $AllServerServices += $svc
    }


}

$AllServerServices | Export-Csv -NoTypeInformation $outputFile
