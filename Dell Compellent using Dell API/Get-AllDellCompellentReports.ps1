

#get-DellScDiskClass -Connection $DSMConnection -ScSerialNumber 



Import-Module "C:\Scripts\Nathan\DellStoragePowerShellSDK_v3_3_1_58\DellStorage.ApiCommandSet.psd1"

$report = @()
$dslist= @()


$mm = $(Get-Date).Month
$dd = $(Get-Date).Day
$yy = $(Get-Date).Year
$hour = $(Get-Date).Hour
$minute = $(Get-Date).Minute

#ReportArraysDeclarations
$AllControllerInfo = @()
$AllVolumeInfo = @()
$AllDiskClassStorageUsage = @()
$AllReplaysInfo =@()
$AllReplaysProfileInfo =@()
$AllReplaysProfileRuleInfo =@()
$AllTierInfo = @()
$AllTierStorageUsage = @()
$AllDiskClassInfo = @()
$AllArrayRawStorage = @()
$AllInstanceInfo = @()
$AllEnclosuresInfo = @()
$AllScUserInfo = @()
$AllDSMUserInfo = @()
$AllDiskInfo = @()
$AllArrayRawStorageReport = @()


$DSMList = Import-CSV C:\Users\nathan_choate\GIT\HCLS-VM-Toolkit\NATHAN\CmlStats\dsm.txt

function Convert-DellAPINumber{

	Param(
    	[Parameter(Mandatory=$true,
	    ValueFromPipeline=$true)]
    	[String]
    	$DellNumber 
    	)

	$DellNums = $DellNumber.split(' ')

	switch($DellNums[1]){
        "MB" { $value = 0 }
        "GB" { $value = $DellNums[0] / 1024 }
        "PB" { $value = [Decimal]$DellNums[0] * 1024 }
        default {$value = $DellNums[0]}
    	
	}
return $value
}

foreach($dsm in $DSMList){

$infoAdd = "" | Select DataCenter,BusinessUnit,DsmIP
$infoAdd.DataCenter = $dsm.DC
$infoAdd.BusinessUnit = $dsm.BU 
$infoAdd.DsmIP = $dsm.IP

$DSMPassword = ConvertTo-SecureString $dsm.Password -AsPlainText -Force

$DSMConnection = Connect-DellApiConnection -HostName $dsm.IP -User $dsm.Username -Password $DSMPassword
$DSMConnection
$infoAdd | ft -auto


#Basic Controller Data
$ControllerInfo = Get-DellScController -Connection $DSMConnection | Sort ScSerialNumber | Select ScSerialNumber,Name,UniqueName,HardwareSerialNumber,Model,ServiceTag,IpAddress,IpNetMask,IpGateway,BmcIpAddress,Version,ScName,InstanceName,InstanceId,Leader,LastBootTime,DateCreated,DateUpdate
#Basic Volume Data
$VolumeInfo = Get-DellScVolume -Connection $DSMConnection |Sort ScSerialNumber  | Select Name, DeviceId, Active, ConfiguredSize, Mapped, ScSerialNumber, SerialNumber, Status, VolumeFolder, VolumeFolderPath
#Basics Array Mgmt Data
$InstanceInfo = Get-DellStorageCenter -Connection $DSMConnection
#Basic Enclosure Info
$EnclosureInfo = Get-DellScEnclosure -Connection $DSMConnection
#Basic Disk Info
$DiskInfo = Get-DellScDisk -Connection $DSMConnection
#SC User Data
$DellScUserList = Get-DellScUser -Connection $DSMConnection
#Disk Usage By Tier Type
$TierInfo = Get-DellScStorageTypeTier -Connection $DSMConnection
#Disk Usage By Disk Type
## Must index with InstanceID -- $DiskUsage = Get-DellScDiskStorageUsage -Connection $DSMConnection
#Disk Usage By Disk Type
$DiskClassInfo = Get-DellScDiskClass -Connection $DSMConnection
#Replay Information
$ReplaysInfo = Get-DellScReplay -Connection $DSMConnection | Sort ScSerialNumber
#Replay Profile Information
$ReplaysProfileInfo = Get-DellScReplayProfile -Connection $DSMConnection | Sort ScSerialNumber
#Replay Profile Rule Information
$ReplaysProfileRuleInfo = Get-DellScReplayProfileRule -Connection $DSMConnection | Sort ScSerialNumber




foreach($obj in $ControllerInfo){
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $obj -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    Add-Member -InputObject $obj -MemberType NoteProperty -Name CacheSize -Value $(Get-DellScControllercachecard -Connection $DSMConnection -ControllerIndex $obj.HardwareSerialNumber).CacheSize
    $AllControllerInfo += $obj | Select Datacenter,BusinessUnit,DsmIP,ScSerialNumber,Name,UniqueName,HardwareSerialNumber,Model,CacheSize,ServiceTag,IpAddress,IpNetMask,IpGateway,BmcIpAddress,Version,ScName,InstanceName,InstanceId,Leader,LastBootTime,DateCreated,DateUpdated

    if ($obj.Leader -like "True"){
    $diskclass = Get-DellScDiskClass -Connection $DSMConnection -ScSerialNumber $obj.ScSerialNumber
    
    $StorageUsage = Get-DellStorageCenterStorageUsage -Connection $DSMConnection -Instance $obj.ScSerialNumber
    
    foreach($dc in $diskclass){
        $dcusage = Get-DellScDiskClassStorageUsage -Connection $DSMConnection -Instance $dc.InstanceId
        $dcline = "" | Select Datacenter,BusinessUnit,DsmIP,ScSerialNumber,ScName,EnclosureCount,DiskCount,ManagedCount,DiskClassInstanceId,DiskInstanceName,AllocatedSpace,AllocatedSpaceTB,FreeSpace,FreeSpaceTB,SpareSpace,SpareSpaceTB,TotalSpace,TotalSpaceTB,ClassTotalSpace,ClassTotalSpaceTB
        $dcline.DataCenter = $infoAdd.DataCenter
        $dcline.BusinessUnit = $infoAdd.BusinessUnit
        $dcline.DsmIP= $infoAdd.DsmIP
        $dcline.ScSerialNumber = $dc.ScSerialNumber
        $dcline.ScName = $dc.ScName
        $dcline.DiskClassInstanceId = $dc.DiskClassInstanceId
        $dcline.DiskInstanceName = $dc.InstanceName
        $dcline.EnclosureCount = $dcusage.EnclosureCount
        $dcline.DiskCount = $dc.DiskCount
        $dcline.ManagedCount = $dc.ManagedCount
        $dcline.AllocatedSpace = $dcusage.AllocatedSpace
        $dcline.FreeSpace = $dcusage.FreeSpace
        $dcline.SpareSpace = $dcusage.SpareSpace
        $dcline.TotalSpace = $dcusage.TotalSpace
        $dcline.ClassTotalSpace = $dc.TotalSpace
        $dcline.AllocatedSpaceTB = $($dcusage.AllocatedSpace | Convert-DellAPINumber)
        $dcline.FreeSpaceTB = $($dcusage.FreeSpace | Convert-DellAPINumber)
        $dcline.SpareSpaceTB = $($dcusage.SpareSpace | Convert-DellAPINumber)
        $dcline.TotalSpaceTB = $($dcusage.TotalSpace | Convert-DellAPINumber)
        $dcline.ClassTotalSpaceTB = $($dc.TotalSpace | Convert-DellAPINumber)
        $AllDiskClassStorageUsage += $dcline
        }
       
    $StorageUsageLine = "" | Select Datacenter,BusinessUnit,DsmIP,ScSerialNumber,SuScSerialNumber,ScName,SuScName,SuInstanceId,AlertThresholdPercent,AlertThreshold,AlertThresholdTB,Time,ConfiguredSpace,ConfiguredSpaceTB,AvailableSpace,AvailableSpaceTB,UsedSpace,UsedSpaceTB,AllocatedSpace,AllocatedSpaceTB,FreeSpace,FreeSpaceTB,BadSpace,BadSpaceTB,OversubscribedSpace,OversubscribedSpaceTB,SystemSpace,SavingVsRaidTen,SavingVsRaidTenTB,EfficiencyRatio,DataReductionRatio
    $StorageUsageLine.DataCenter = $infoAdd.DataCenter
    $StorageUsageLine.BusinessUnit = $infoAdd.BusinessUnit
    $StorageUsageLine.DsmIP= $infoAdd.DsmIP
    $StorageUsageLine.ScSerialNumber = $obj.ScSerialNumber
    $StorageUsageLine.ScName = $obj.ScName
        
    $StorageUsageLine.AlertThreshold = $StorageUsage.AlertThresholdSpace
    $StorageUsageLine.AlertThresholdTB = $($StorageUsage.AlertThresholdSpace | Convert-DellAPINumber)
    $StorageUsageLine.AlertThresholdPercent = $StorageUsage.StorageAlertThreshold
    $StorageUsageLine.AllocatedSpace = $StorageUsage.AllocatedSpace
    $StorageUsageLine.AllocatedSpaceTB = $($StorageUsage.AllocatedSpace | Convert-DellAPINumber)
    $StorageUsageLine.AvailableSpace = $StorageUsage.AvailableSpace
    $StorageUsageLine.AvailableSpaceTB = $($StorageUsage.AvailableSpace | Convert-DellAPINumber)
    $StorageUsageLine.BadSpace = $StorageUsage.BadSpace
    $StorageUsageLine.BadSpaceTB = $($StorageUsage.BadSpace | Convert-DellAPINumber)
    $StorageUsageLine.ConfiguredSpace = $StorageUsage.ConfiguredSpace
    $StorageUsageLine.ConfiguredSpaceTB = $($StorageUsage.ConfiguredSpace | Convert-DellAPINumber)
    $StorageUsageLine.FreeSpace = $StorageUsage.FreeSpace
    $StorageUsageLine.FreeSpaceTB = $($StorageUsage.FreeSpace | Convert-DellAPINumber)
    $StorageUsageLine.OversubscribedSpace = $StorageUsage.OversubscribedSpace
    $StorageUsageLine.OversubscribedSpaceTB = $($StorageUsage.OversubscribedSpace | Convert-DellAPINumber)
    $StorageUsageLine.SavingVsRaidTen = $StorageUsage.SavingVsRaidTen
    $StorageUsageLine.SavingVsRaidTenTB = $($StorageUsage.SavingVsRaidTen | Convert-DellAPINumber)
    $StorageUsageLine.EfficiencyRatio = $StorageUsage.SystemDataEfficiencyRatio
    $StorageUsageLine.DataReductionRatio = $StorageUsage.SystemDataReductionRatio
    $StorageUsageLine.SystemSpace = $StorageUsage.SystemSpace
    $StorageUsageLine.Time = $StorageUsage.Time
    $StorageUsageLine.UsedSpace = $StorageUsage.UsedSpace
    $StorageUsageLine.UsedSpaceTB = $($StorageUsage.UsedSpace | Convert-DellAPINumber)
    $StorageUsageLine.SuScName = $StorageUsage.ScName
    $StorageUsageLine.SuScSerialNumber = $StorageUsage.ScSerialNumber
    $StorageUsageLine.SuInstanceId = $StorageUsage.InstanceId
        
    $AllArrayRawStorage += $StorageUsageLine
   
     
	$newline = $StorageUsageLine | Select Datacenter,BusinessUnit,DsmIP,ScSerialNumber,ScName,ConfiguredSpaceTB,AvailableSpaceTB,UsedSpaceTB,FreeSpaceTB,FreePercent,OversubscribedSpaceTB
	$newline.FreePercent = $StorageUsageLine.FreeSpaceTB / $StorageUsageLine.AvailableSpaceTB
	$AllArrayRawStorageReport += $newline
}
    
}# end of Controller Info


foreach($obj in $VolumeInfo){
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $obj -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    Add-Member -InputObject $obj -MemberType NoteProperty -Name ConfiguredSizeTB -Value $($obj.ConfiguredSize | Convert-DellAPINumber)
    $AllVolumeInfo += $obj | Select DataCenter,BusinessUnit,DsmIP,Name,DeviceId, Active, ConfiguredSize,ConfiguredSizeTB, Mapped, ScSerialNumber, SerialNumber, Status, VolumeFolder, VolumeFolderPath
} #end of Merge Volume Info    

foreach ($line in $InstanceInfo){
    Add-Member -InputObject $line -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $line -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $line -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    $AllInstanceInfo += $line | Select Datacenter, BusinessUnit, DsmIP, Name, ScSerialNumber, ScName, Version, HostOrIpAddress, ManagementIp, Connected, UniqueName, InstanceId, InstanceName, PortsBalanced
    }

foreach ($line in $EnclosureInfo){
    Add-Member -InputObject $line -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $line -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $line -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    $AllEnclosuresInfo += $line | Select DataCenter,BusinessUnit,DsmIP,ScSerialNumber,ScName,Name,InstanceName,InstanceId,ObjectType,EnclosureModel,Model,ShelfId,Type,ServiceTag,IndicatorOn,NonCriticalCondition,CriticalCondition,UnrecoverableCondition,Status,Revision,DrawerCapacity,NumberDrawers,Enclosurecapacity,StatusDescription,StatusMessage
    }

foreach ($line in $DiskInfo){
    Add-Member -InputObject $line -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $line -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $line -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    $AllDiskInfo += $line
    }

foreach ($line in $DellScUserList){
    Add-Member -InputObject $line -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $line -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $line -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    $AllScUserInfo += $line | Select Datacenter, BusinessUnit, DsmIP, Name,Privilege,RealName,ScName,ScSerialNumber,CreatedBy,CreatedOn,UpdatedBy,ModifiedOn,SessionTimeout,Locked,CreatedByGroupLogin,DirectoryUser
    } 

foreach($obj in $ReplaysInfo){
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $obj -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    Add-Member -InputObject $obj -MemberType NoteProperty -Name SizeTB -Value $($obj.Size | Convert-DellAPINumber)
    $AllReplaysInfo += $obj | Select DataCenter,BusinessUnit,DsmIP,Active,ConsistencyGroup,Consistent,CreateVolume,Description,ExpireTime,Expires,FreezeTime,GlobalIndex,MarkedForExpiration,Parent,ReplayProfile,ReplayProfileRule,Size,SizeTB,Source,SpaceRecovery,WritesHeldDuration,ScName,ScSerialNumber,UniqueName,InstanceId,InstanceName,ObjectType
} #end of Replay Info  

foreach($obj in $ReplaysProfileInfo){
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $obj -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    $AllReplaysProfileInfo += $obj | Select DataCenter,BusinessUnit,DsmIP,EnforceReplayCreationTimeout,ExpireIncompleteReplaySets,MoreVolumesAllowed,Name,Notes,ReplayCreationTimeout,RuleCount,Type,UserCreated,VolumeCount,ScName,ScSerialNumber,UniqueName,InstanceId,InstanceName,ObjectType
} #end of Replay Profile Info  


foreach($obj in $ReplaysProfileRuleInfo){
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $obj -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DateOfMonth -Value $obj.Schedule.DateOfMonth
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DayOfWeek -Value $obj.Schedule.DayOfWeek
    Add-Member -InputObject $obj -MemberType NoteProperty -Name EndTime -Value $obj.Schedule.EndTime
    Add-Member -InputObject $obj -MemberType NoteProperty -Name Interval -Value $obj.Schedule.Interval
    Add-Member -InputObject $obj -MemberType NoteProperty -Name MonthOfYear -Value $obj.Schedule.MonthOfYear
    Add-Member -InputObject $obj -MemberType NoteProperty -Name ScheduleType -Value $obj.Schedule.ScheduleType
    Add-Member -InputObject $obj -MemberType NoteProperty -Name StartDateTime -Value $obj.Schedule.StartDateTime
    Add-Member -InputObject $obj -MemberType NoteProperty -Name StartTime -Value $obj.Schedule.StartTime
    Add-Member -InputObject $obj -MemberType NoteProperty -Name WeekOfMonth -Value $obj.Schedule.WeekOfMonth
    Add-Member -InputObject $obj -MemberType NoteProperty -Name ObjectName -Value $obj.Schedule.ObjectName


    $AllReplaysProfileRuleInfo += $obj | Select DataCenter,BusinessUnit,DsmIP,Expiration,Name,ReplayProfile,Schedule,DateOfMonth,DayOfWeek,EndTime,Interval,MonthOfYear,ScheduleType,StartDateTime,StartTime,WeekOfMonth,ObjectName,ScName,ScSerialNumber,UniqueName,InstanceId,InstanceName,ObjectType
} #end of Replay Profile Info  


foreach($obj in $TierInfo){
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $obj -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    $AllTierInfo += $obj 

    $TierStorageInfo = Get-DellScStorageTypeTierStorageUsage -Connection $DSMConnection -Instance $obj.InstanceId
    foreach($obj in $TierStorageInfo){
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $obj -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    Add-Member -InputObject $obj -MemberType NoteProperty -Name AllocatedSpaceTB -Value $($obj.AllocatedSpace | Convert-DellAPINumber)
    Add-Member -InputObject $obj -MemberType NoteProperty -Name FreeSpaceTB -Value $($obj.FreeSpace | Convert-DellAPINumber)
    Add-Member -InputObject $obj -MemberType NoteProperty -Name NonAllocatedSpaceTB -Value $($obj.NonAllocatedSpace | Convert-DellAPINumber)
    Add-Member -InputObject $obj -MemberType NoteProperty -Name UsedSpaceTB -Value $($obj.UsedSpace | Convert-DellAPINumber)
    Add-Member -InputObject $obj -MemberType NoteProperty -Name TierDataReductionSpaceSavingsTB -Value $($obj.TierDataReductionSpaceSavings | Convert-DellAPINumber)

    $AllTierStorageUsage += $obj | Select DataCenter,BusinessUnit,DsmIP,AllocatedSpace,AllocatedSpaceTB,FreeSpace,FreeSpaceTB,NonAllocatedSpace,NonAllocatedSpaceTB,TierDataReductionSpaceSavings,TierDataReductionSpaceSavingsTB,Time,UsedSpace,UsedSpaceTB,ScName,ScSerialNumber,UniqueName,InstanceId,InstanceName,ObjectType
    }

} #end of Merge Volume Info  

foreach($obj in $DiskClassInfo){
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $obj -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $obj -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    Add-Member -InputObject $obj -MemberType NoteProperty -Name TotalSpaceTB -Value $($obj.TotalSpace | Convert-DellAPINumber)
    $AllDiskClassInfo += $obj | Select DataCenter,BusinessUnit,DsmIP,DiskCount,ManagedCount,Name,SpareCount,TotalSpace,TotalSpaceTB,UnhealthyCount,ScName,ScSerialNumber,UniqueName,InstanceId,InstanceName,ObjectType
} #end of Merge Volume Info  


$ThisDSM = Get-DellEMUser -Connection $DSMConnection | Select Name, Privilege, UniqueName, PasswordLatModified
foreach ($line in $ThisDSM){
    Add-Member -InputObject $line -MemberType NoteProperty -Name DataCenter -Value $infoAdd.DataCenter
    Add-Member -InputObject $line -MemberType NoteProperty -Name BusinessUnit -Value $infoAdd.BusinessUnit
    Add-Member -InputObject $line -MemberType NoteProperty -Name DsmIP -Value $infoAdd.DsmIP
    $AllDSMUserInfo += $line | Select DataCenter,BusinessUnit,DsmIP,Name, Privilege, UniqueName, PasswordLatModified
}

Disconnect-DellApiConnection -Connection $DSMConnection

} # end foreach DSM


#Get-DellScController
$AllControllerInfo | Export-Csv -NoTypeInformation C:/reports/AllControllerInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScVolume
$AllVolumeInfo | Export-Csv -NoTypeInformation C:/reports/AllVolumeInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellStorageCenter
$AllInstanceInfo | Export-Csv -NoTypeInformation C:/reports/AllDSMInstanceInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScEnclosure
$AllEnclosuresInfo | Export-Csv -NoTypeInformation C:/reports/AllEnclosuresInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScDisk
$AllDiskInfo  | Export-Csv -NoTypeInformation C:/reports/AllDiskInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScDiskClassStorageUsage
$AllDiskClassStorageUsage | Export-Csv -NoTypeInformation C:/reports/AllDiskClassStorageUsage-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScReplay
$AllReplaysInfo | Export-Csv -NoTypeInformation C:/reports/AllReplayInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScReplayProfile
$AllReplaysProfileInfo | Export-Csv -NoTypeInformation C:/reports/AllReplayProfileInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScReplayProfile
$AllReplaysProfileRuleInfo | Export-Csv -NoTypeInformation C:/reports/AllReplayProfileRuleInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScStorageTypeTier
$AllTierInfo | Export-Csv -NoTypeInformation C:/reports/AllTierInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScStorageTypeTierStorageUsage
$AllTierStorageUsage | Export-Csv -NoTypeInformation C:/reports/AllTierStorageUsage-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScDiskClass
$AllDiskClassInfo | Export-Csv -NoTypeInformation C:/reports/AllDiskClassInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellStorageCenterUsage
$AllArrayRawStorage | Export-Csv -NoTypeInformation C:/reports/AllArrayRawStorage-$mm-$dd-$yy-$hour$minute.csv
#Get-DellScUser
$AllScUserInfo | Export-Csv -NoTypeInformation C:/reports/AllScUserInfo-$mm-$dd-$yy-$hour$minute.csv
#Get-DellEmUser
$AllDSMUserInfo | Export-Csv -NoTypeInformation C:/reports/AllDSMUserInfo-$mm-$dd-$yy-$hour$minute.csv
#Raw storage made into a nicer report
$AllArrayRawStorageReport | Export-Csv -NoTypeInformation C:/reports/AllArrayRawStorageReport-$mm-$dd-$yy-$hour$minute.csv