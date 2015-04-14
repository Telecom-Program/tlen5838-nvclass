#Connect-VIServer vcenter.int.colorado.edu
$Students = Import-CSV students_tlen5838.csv
$Datacenter = "ECEE 2B80"
$ClusterName = "Sandbox"
$DestFolder = "Network and System Virtualization"
$Datastore = "Hollywood"
$VDSwitch = "vDS-Hollywood-Switch0"

foreach($Student in $Students)
{
    $Owner = "ad\" + $Student.identikey
    
    $SourceIntPortgroup = "NVCLASS Gauri One"
    $DestinationIntPortgroup = "NVCLASS " + $Student.lastname + " " + $Student.identikey + " One"
    $SourceDMZPortgroup = "NVCLASS Gauri Two"
    $DestinationDMZPortgroup = "NVCLASS " + $Student.lastname + " " + $Student.identikey + " Two"
    $DestinationVlanRange = "6" + $Student.number + "0-" + "6" + $Student.number + "5"
    $DestinationMgmtPortgroup = "NVCLASS " + $Student.lastname + " " + $Student.identikey + " Management"
    $DestinationMgmtVLANID = "6" + $Student.number + "0"
    $DestinationStor1Portgroup = "NVCLASS " + $Student.lastname + " " + $Student.identikey + " Storage One"
    $DestinationStor1VLANID = "6" + $Student.number + "2"
    $DestinationStor2Portgroup = "NVCLASS " + $Student.lastname + " " + $Student.identikey + " Storage Two"
    $DestinationStor2VLANID = "6" + $Student.number + "3"
    
    #New-VDPortgroup -VDSwitch $VDSwitch -Confirm:$false -Name $DestinationIntPortgroup -VlanTrunkRange $DestinationVlanRange
    #New-VDPortgroup -VDSwitch $VDSwitch -Confirm:$false -Name $DestinationDMZPortgroup -VlanTrunkRange $DestinationVlanRange
    New-VDPortgroup -VDSwitch $VDSwitch -Confirm:$false -Name $DestinationMgmtPortgroup -VlanId $DestinationMgmtVLANID
    New-VDPortgroup -VDSwitch $VDSwitch -Confirm:$false -Name $DestinationStor1Portgroup -VlanId $DestinationStor1VLANID
    New-VDPortgroup -VDSwitch $VDSwitch -Confirm:$false -Name $DestinationStor2Portgroup -VlanId $DestinationStor2VLANID
    
    $VmName = "NVCLASS " + $Student.lastname + "-" + $Student.identikey + " DC-01 ESXi-01" 
    Write-Host "Cloning UNIX VM $VmName"
    $Template = Get-Template -Name "ITP NVCLASS ESXi Template" -Location $Datacenter
    $Vm = New-VM -Name $VmName -ResourcePool $ClusterName -Template $Template -Datastore $Datastore -Location $DestFolder
    $Vm | Get-NetworkAdapter | Where {$_.NetworkName -eq $SourceIntPortgroup } | Set-NetworkAdapter -Portgroup $DestinationIntPortgroup -Confirm:$false
    $Vm | Get-NetworkAdapter | Where {$_.NetworkName -eq $SourceDMZPortgroup } | Set-NetworkAdapter -Portgroup $DestinationDMZPortgroup -Confirm:$false
    New-VIPermission -Role "Virtual machine user" -Principal $Owner -Entity $VmName
    $Vm | Start-VM
    
    $VmName = "NVCLASS " + $Student.lastname + "-" + $Student.identikey + " DC-01 ESXi-02" 
    Write-Host "Cloning VM $VmName"
    $Template = Get-Template -Name "ITP NVCLASS ESXi Template" -Location $Datacenter
    $Vm = New-VM -Name $VmName -ResourcePool $ClusterName -Template $Template -Datastore $Datastore -Location $DestFolder
    $Vm | Get-NetworkAdapter | Where {$_.NetworkName -eq $SourceIntPortgroup } | Set-NetworkAdapter -Portgroup $DestinationIntPortgroup -Confirm:$false
    $Vm | Get-NetworkAdapter | Where {$_.NetworkName -eq $SourceDMZPortgroup } | Set-NetworkAdapter -Portgroup $DestinationDMZPortgroup -Confirm:$false
    New-VIPermission -Role "Virtual machine user" -Principal $Owner -Entity $VmName
    $Vm | Start-VM
    
    $SourceDMZPortgroup = "OIT Private CU-2B80-RACK6"
    $VmName = "NVCLASS " + $Student.lastname + "-" + $Student.identikey + " DC-01 Storage-01" 
    Write-Host "Cloning VM $VmName"
    $Template = Get-Template -Name "CentOS 6.5 x86_64" -Location $Datacenter
    $Vm = New-VM -Name $VmName -ResourcePool $ClusterName -Template $Template -Datastore $Datastore -Location $DestFolder
    $Vm | Get-NetworkAdapter | Where {$_.NetworkName -eq $SourceDMZPortgroup } | Set-NetworkAdapter -Portgroup $DestinationMgmtPortgroup -Confirm:$false
    $Vm | New-NetworkAdapter -NetworkName $DestinationStor1Portgroup -StartConnected
    $Vm | New-NetworkAdapter -NetworkName $DestinationStor2Portgroup -StartConnected
    New-VIPermission -Role "Virtual machine user" -Principal $Owner -Entity $VmName
    $Vm | Start-VM

}