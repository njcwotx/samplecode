<#
Create_BrocadeZoning.ps1

This script will help create the alias and zones for each of your hosts for a brocade switch.

While it will read from vcenter all information needed, it does not modify any Brocade switch or VMware settings, it will
output the various commands you can 'paste' into an ssh session on a brocade.  The advantage is you can
run this multiple times without concern, and verify before pasting the changes that they are what you intend.

This script is not self fulfilling, you have to supply some information before it works properly, but its still
much faster than manually zoning via the Brocade GUI!

Once the script completes, the output can be pasted directly into the Brocade CLI session as follows.

1. Login to the Fabric A Brocade switch and get the prompt
2. copy the -Aliases Fabric A- output directly into the logged in cli session.
3. If there are no errors, then type the command 'cfgsave', if there are errors or confusion, just simple exit the ssh session and the changes are lost.

4. once saved, you can copy the -Zones for Fabric A- output directly into the cli session.
5. If there are no errors, then type the command 'cfgsave', if there are errors or confusion, just simple exit the ssh session and the changes are lost.

6. Login to the Fabric B Brocade switch and get the prompt.
7. copy the -Aliases Fabric B- output directly into the logged in cli session.
8. If there are no errors, then type the command 'cfgsave', if there are errors or confusion, just simple exit the ssh session and the changes are lost.

9. once saved, you can copy the -Zones for Fabric B- output directly into the cli session.
10. If there are no errors, then type the command 'cfgsave', if there are errors or confusion, just simple exit the ssh session and the changes are lost.

At this point, log into the FABRIC A and B GUI sessions and go to the Zone Administrator and the "Zoning Config" tab, expand the zones and you will see your new zones ready to verify and be enabled.

Once you enable the zones, you can find the companion script "New-CMLServerList.ps1" and run it.  This will take the output of this script ServerList.txt and create all the new server entries on the Compellent array.

---- OBTAINING THE ZONE STRING ----
One thing to note is the $CMLZONESETFABA and $CMLSZONESETFABB arrays.  These can be obtained by copying them straight
from the config of the switch, typically before running this script you can do a 'configshow' on the target switch and copy and paste it into
your favorite text editor.  Look for the 'zone.' entries.  See this example below, 

zone.ZONE_280_DC_ARRAY01_DPS_BC3_BLADE1:ARRAY1_VIRT_29922_S4_P1;ARRAY1_VIRT_29922_S4_P3;ARRAY1_VIRT_29922_S5_P1;ARRAY1_VIRT_29922_S5_P3;ARRAY1_VIRT_29923_S4_P1;ARRAY1_VIRT_29923_S4_P3;ARRAY1_VIRT_29923_S5_P1;ARRAY1_VIRT_29923_S5_P3;DC_BLADE_BC3_BLADE1
zone.ZONE_283_DC_ARRAY01_DPS_BC3_BLADE4:ARRAY1_VIRT_29922_S4_P1;ARRAY1_VIRT_29922_S4_P3;ARRAY1_VIRT_29922_S5_P1;ARRAY1_VIRT_29922_S5_P3;ARRAY1_VIRT_29923_S4_P1;ARRAY1_VIRT_29923_S4_P3;ARRAY1_VIRT_29923_S5_P1;ARRAY1_VIRT_29923_S5_P3;DC_BLADE_BC3_BLADE4
zone.ZONE_284_DC_ARRAY01_DPS_BC3_BLADE5:ARRAY1_VIRT_29922_S4_P1;ARRAY1_VIRT_29922_S4_P3;ARRAY1_VIRT_29922_S5_P1;ARRAY1_VIRT_29922_S5_P3;ARRAY1_VIRT_29923_S4_P1;ARRAY1_VIRT_29923_S4_P3;ARRAY1_VIRT_29923_S5_P1;ARRAY1_VIRT_29923_S5_P3;DC_BLADE_BC3_BLADE5
zone.ZONE_285_DC_ARRAY01_DPS_BC3_BLADE6:ARRAY1_VIRT_29922_S4_P1;ARRAY1_VIRT_29922_S4_P3;ARRAY1_VIRT_29922_S5_P1;ARRAY1_VIRT_29922_S5_P3;ARRAY1_VIRT_29923_S4_P1;ARRAY1_VIRT_29923_S4_P3;ARRAY1_VIRT_29923_S5_P1;ARRAY1_VIRT_29923_S5_P3;DC_BLADE_BC3_BLADE6

The variables $CMLZONESETFABA and $CMLZONESETFABB need the text from this entry that is between the ':' and the last ';' that applies to the aliases for each port of the target Stroage Array.
Each zone config fragment becomes part of the zoning command for each host, and is presented in the "..w..","..x..","..y..","..z.." style as an element of the array variables.
------------------------------------

$STRIPSTART, $STRIPEND, $DOMAINSTR variables are all part of the string manipulation.  If you see in the zones listed in the 'zoneset' variables, you will find the array SN.  i found it sometiems moves within the string
depending upon which brocade, so $STRIPSTART and $STRIPEND are just convenient ways to have the array SN added to the new zone name.  I guess I could have just variablized it, but at the time this seemed a good way to play
with the methods available to a powershell variable :)  $DOMAINSTR ended up being added when I used this on another new implentation and found I had to strip this from the hostnames.

Output is in various forms for convenience, but the last 4 groups will output the actual Brocade CLI Strings.
There is also a ServerList.txt file, this is 'input' for another script "New-CMLServerList.ps1".  This script will be able to be run once you go into the brocade GUI and confirm and select the zones to be enabled.

* some zones include a numbering scheme to order the zones...if you have that see the script Create_BrocadeZoning-withSeed.ps1

Originally Created by nathan.chaote@nttdate.com
If you have questions feel free to ask.

**************   NOTICE OF DISCLAIMER ************
*****   Each time I used this, I had to make some adjustment to the strings modified to get naming convention just right so pay attention to the output, on this script you will see a "WTC_ had to be added to rowB
		to get my aliases to match naming convention on the array this version.  Just pay attention and you will be ok.  If I modify this, I will keep copies of various versions with the -blah to save them.


#>


# This is the target ESX Cluster, in new build scenarios, "Non-Prodcution" is common but sometimes you want to target a cluster to create zones for existing hosts
$VCCluster = "PRODUCTION"

# THIS IS AN ARRAY of EACH Compellent You want a zone for, simply cut this string from an existing zone on each Brocade switch config, its easier than you think....
# format array using "..","..",".." format, omit the first ":" and include the last ";" from the ZONE. lines in the config of the brocade

$CMLZONESETFABA = "MCTC_53103_VIRT_S4_P1;MCTC_53103_VIRT_S6_P1;MCTC_53104_VIRT_S4_P1;MCTC_53104_VIRT_S6_P1;"
$CMLZONESETFABB = "MCTC_53103_VIRT_S4_P2;MCTC_53103_VIRT_S6_P2;MCTC_53104_VIRT_S4_P2;MCTC_53104_VIRT_S6_P2;"

# STRIP is the num charachacters to arrive at the CML#_ when naming zones
#Position to start counting the strip
$STRIPSTART = 5
#Number of Charachters after the starting point to grab
$STRIPEND = 5


# Enter the domain name that typically is part of the ESX hostname, it needs to be stripped from the hostname later on.
$DOMAINSTR = ".domain.local"

#various array init
$report = @()
$combine = @()
$blade = @()
$fabricA = @()
$fabricB = @()
$AliasFabA = @()
$AliasFabB = @()
$ZoneFabA = @()
$ZoneFabB = @()
$CompellentCSV = @()


# This is the commonly used method to scan a cluster in esx and get the WWNs for each host.

#if you want to loop by cluster...
foreach ($esx in get-cluster  -Name $VCCluster  | get-vmhost | get-view | sort-object name){
## this gets all hosts in vcenter, but can take longer
##foreach ($esx in get-vmhost | get-view | sort-object name){
			
			
	foreach($hba in $esx.Config.StorageDevice.HostBusAdapter){
			$row = "" | select Cluster,Name,WWN
			$row.Cluster = $(Get-Cluster -VMHost $esx.name).name
			$row.Name = $esx.name

		if($hba.GetType().Name -eq "HostFibreChannelHba"){
			$wwn = $hba.PortWorldWideName
			$wwnhex = "{0:x}" -f $wwn
			$row.WWN = $wwnhex
			$report += $row
			}

	}

				
}
# display the raw object containing data
echo $report

# Consolidate the raw output to create a single array per host to assist subsequent processes
for($i=0;$i -le $report.length-1;$i++){

	if ($report[$i].Name -eq $report[$($i+3)].Name){
	$combine = "" | select Name,WWN1,WWN2, WWN3, WWN4
	$combine.Name = $report[$i].Name
	$combine.WWN1 = $report[$i].WWN
	$combine.WWN2 = $report[$($i+1)].WWN
	$combine.WWN3 = $report[$($i+2)].WWN
	$combine.WWN4 = $report[$($i+3)].WWN
	$blade += $combine
	}

}
# display raw consolidated data
$blade | ft -AutoSize

# Create the Brocade alias commands to paste into the brocades on Fabric A
foreach ($esx in $blade){
$rowA = "" | Select Name,WWNA	
$rowA.Name = $($($esx.name.ToUpper()).Replace("$DOMAINSTR","")).Replace("-","_")
$rowA.WWNA = $($esx.WWN1 -replace '..(?!$)', '$&:') + ";" + $($esx.WWN3 -replace '..(?!$)', '$&:')
$fabricA += $rowA
$AliasFabA += "alicreate "+'"'+$rowA.Name+'"'+", "+'"'+$rowA.WWNA+'"'
}

# Create the Brocade alias commands to paste into the brocades on Fabric B
foreach ($esx in $blade){
$rowB = "" | Select Name,WWNB
$rowB.Name = $($($esx.name.ToUpper()).Replace("$DOMAINSTR","")).Replace("-","_")
$rowB.WWNB = $($esx.WWN2 -replace '..(?!$)', '$&:') + ";" + $($esx.WWN4 -replace '..(?!$)', '$&:')
$fabricB += $rowB
$AliasFabB += "alicreate "+'"'+$rowB.Name+'"'+", "+'"'+$rowB.WWNB+'"'
}

# display each Host by fabric
echo "`n-Fabric A-"
$fabricA | ft -AutoSize

echo "`n-Fabric B-"
$fabricB | ft -AutoSize

# display each set of alias commands for each fabric
echo "`n-Aliases Fabric A-`n"
$AliasFabA | ft -AutoSize

echo "`n-Aliases Fabric B-`n"
$AliasFabB | ft -AutoSize


# Create the zoning commands to paste into the brocades for each fabric
# remember starting seed so we can match the zone number on fabric b
$SEED_Memory = $SEED

foreach ($zone in $FabricA){
	foreach ($cml in $CMLZONESETFABA){
	$StripCML = $($cml.substring($STRIPSTART,$STRIPEND))
	$Zonename = '"'+$zone.Name+"_"+$StripCML+'"'
	$ZoneFabA += "zonecreate "+$Zonename+', "'+$cml+$zone.Name+'"'
	$SEED++
	}

}

# restore the starting seed to match zone numbers for fabric b
$SEED = $SEED_Memory

foreach ($zone in $FabricB){
	foreach ($cml in $CMLZONESETFABB){
	$StripCML = $($cml.substring($STRIPSTART,$STRIPEND))
	$Zonename = '"'+$zone.Name+"_"+$StripCML+'"'
	$ZoneFabB += "zonecreate "+$Zonename+', "'+$cml+$zone.Name+'"'
	$SEED++
	}

}

echo "`n-Zones for Fabic A-`n"
$ZoneFabA | ft #| Out-File zonelist.txt

echo "`n-Zones for Fabic B-`n"
$ZoneFabB | ft #| Out-File zonelist.txt


# export the csv file to import into the Set-CompellentHost.ps1 script
foreach ($srv in $blade){
	$line = "" | Select ServerName,WWN1,WWN2
	$line.ServerName = $($srv.Name.ToUpper()).Replace("$DOMAINSTR","")
	$line.WWN1 = $srv.WWN1
	$line.WWN2 = $srv.WWN2
	$CompellentCSV += $line
}

$CompellentCSV | Export-Csv -NoTypeInformation ServerList.txt
