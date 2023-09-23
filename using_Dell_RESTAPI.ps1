

$mm = $(Get-Date).Month
$dd = $(Get-Date).Day
$yy = $(Get-Date).Year
$hour = $(Get-Date).Hour
$minute = $(Get-Date).Minute

## -$mm-$dd-$yy-$hour-$minute

$report = @()

Function Get-DellFullWarranty([string]$Service_Tag,[string]$Verbose)
{
    
    $apikey = "your api key here"
    $url = "https://api.dell.com/support/assetinfo/v4/getassetwarranty/"+$Service_Tag+"?apikey="+$apikey
    #Write-Host $url
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", 'application/json; charset=utf-8')
    $headers.Add("Accept", 'application/json')
    #Write-Host $headers
    $results = Invoke-WebRequest -Uri $url -ContentType application/json -Headers $headers -Method Get
    #Write-Host $results
    $resultsjson = $results | Select -ExpandProperty Content
    $WarrantyInfo = $resultsjson | ConvertFrom-Json
    $EndDate = ""
    foreach ($i in $WarrantyInfo.AssetWarrantyResponse.AssetEntitlementData) {
        #if (($i.ServiceLevelCode) -eq "S9" -or ($i.ServicelevelCode -eq "S1")) {
            if ($EndDate -gt $i.EndDate) {
                #write-host "Ignoring" $i.EndDate
            } else {
                $EndDate = $i.EndDate
            }
            #$EndDate = $i.EndDate

    }
    if (!$Verbose) {
        Return $EndDate
    } else {
        write-host "here"
        Return $WarrantyInfo.AssetWarrantyResponse
    }
}


foreach ( $item in  (import-csv "./taglist.csv") ){

    $results = Get-DellFullWarranty $item.ServiceTag Verbose

    foreach ($R in $results){
        $line = "" | Select Hostname,ServiceTag,Model,AssesServiceTag,AssetShipDate,MachineDescription,StartDate,EndDate,ServiceLevelDescription,ServiceLevelCode,ServiceLevelGroup,EntitlementType,ServiceProvider,ItemNumber
        $line.Hostname = $item.Hostname
        $line.ServiceTag = $item.ServiceTag
        $line.Model = $item.Model
        $line.AssetServiceTag = $R.AssesHeaderData.ServiceTag
        $line.AssetShipDate = $R.AssesHeaderData.AssetShipDate
        $line.MachineDescription = $R.AssesHeaderData.MachineDescription
        $line.StartDate = $R.AssetEntitlementData.StartDate
        $line.EndDate = $R.AssetEntitlementData.EndDate
        $line.ServiceLevelDescription = $R.AssetEntitlementData.ServiceLevelDescription
        $line.ServiceLevelCode = $R.AssetEntitlementData.ServiceLevelCode
        $line.ServiceLevelGroup = $R.AssetEntitlementData.ServiceLevelGroup
        $line.EntitlementType = $R.AssetEntitlementData.EntitlementType
        $line.ServiceProvider = $R.AssetEntitlementData.ServiceProvider
        $line.ItemNumber = $R.AssetEntitlementData.ItemNumber

        $report += $line

        $line

        Start-Sleep 2       

    }
    Start-Sleep 5     
}

$report | Export-Csv -NoTypeInformation ./DellWarranty_Summary-$mm-$dd-$yy-$hour-$minute.csv
