# get-ServiceList.ps1
param(
    [Parameter(Position=0,mandatory=$true)]
    [string] $ServicesBefore,
    [Parameter(Position=1,mandatory=$true)]
    [string] $ServicesAfter,
    [Parameter(Position=2,mandatory=$true)]
    [string] $ChgNum

)

$outputFile = "./ServicesComparison-$chgNum-$(get-date -f MMddyy-HHmm).csv"

$AllServerServiceComparisions = @()
$differences = @()

$SvcsBefore = Import-CSV $ServicesBefore
$SvcsAfter = Import-Csv $ServicesAfter

$Serverlist = $SvcsBefore | Select MachineName -Unique
$ServerList | ft -AutoSize
$ServerList.count

foreach($server in $ServerList){
    Write-Host $server.MachineName
    $HostBefore = $SvcsBefore | ?{$_.MachineName -eq $server.MachineName}
    $HostAfter = $SvcsAfter | ?{$_.MachineName -eq $server.MachineName}

    #cycle each before service, search for its after status and record the result
foreach($bsvc in $HostBefore){
    foreach($asvc in $HostAfter){
        if($bsvc.MachineName -eq $asvc.MachineName){
            if($bsvc.Name -eq $asvc.Name){
                $CompareLine = "" | Select MachineName,Name,DisplayName,BeforeStatus,AfterStatus,BStartType,AStartType,Changed


                $CompareLine.MachineName = $bsvc.MachineName
                $CompareLine.Name = $bsvc.Name
                $CompareLine.DisplayName = $bsvc.DisplayName
                $CompareLine.BeforeStatus = $bsvc.Status
                $CompareLine.AfterStatus = $asvc.Status
                $CompareLine.BStartType = $bsvc.StartType
                $CompareLine.AStartType = $asvc.StartType

                if($bsvc.Status -eq $asvc.Status){
                    $CompareLine.Changed = "NO"
                }else{
                    $CompareLine.Changed = "YES"
                }

                $AllServerServiceComparisions += $CompareLine
            #    Write-Host "added line " $CompareLine.MachineName "  " $CompareLine.Name
             
            }
        }

    }

}

    #break it down to just a simple service name list for Compare-Object to pull the before/after
    #uniques that are not en each list for that server
    $beforelist = $HostBefore | Select Name
    $afterlist = $HostAfter | Select Name

    #compare the list arrays and deterimine if its in before or after only
    $diff = "" | Select InputObject,SideIndicator
    $diff = Compare-Object $beforelist.Name $afterlist.Name

    $diff | ft -AutoSize

    foreach($d in $diff){

        $CompareLine = "" | Select MachineName,Name,DisplayName,BeforeStatus,AfterStatus,BStartType,AStartType,Changed


        $CompareLine.MachineName = $server.MachineName
        $CompareLine.Name = $d.InputObject

        if ($d.SideIndicator -eq "<="){
            $svc_before = $HostBefore | ?{$_.Name -eq $d.InputObject}
            $CompareLine.DisplayName = $svc_before.DisplayName
            $CompareLine.BeforeStatus = $svc_before.status
            $CompareLine.AfterStatus = "ServiceMissing"
            $CompareLine.BStartType = $svc_before.StartType
            $CompareLine.AStartType = "ServiceMissing"

        }else{
            $svc_after = $HostAfter | ?{$_.Name -eq $d.InputObject}
            $CompareLine.DisplayName = $svc_after.DisplayName
            $CompareLine.BeforeStatus = "NewService"
            $CompareLine.AfterStatus = $svc_after.Status
            $CompareLine.BStartType = "NewService"
            $CompareLine.AStartType = $svc_after.StartType

        }
                
        $CompareLine.Changed = "YES"

        $AllServerServiceComparisions += $CompareLine
    #    Write-Host "added line " $CompareLine.MachineName "  " $CompareLine.Name


    }

}
Write-Host "done compares, starting uniques"


foreach($server in $Serverlist){

    #$server
    #Make a service list just for this machine name
  ###  $beforeSvcs = $SvcsBefore | ?{$_.MachineName -eq $server.MachineName}
  ###  $afterSvcs = $SvcsAfter | ?{$_.MachineName -eq $server.MachineName}

 ###   $beforeSvcs.count
 ###   $afterSvcs.count

           
}




Write-Host "Starting CSV Dump"
$AllServerServiceComparisions | Export-Csv -NoTypeInformation $outputFile