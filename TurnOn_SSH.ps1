for($i=1; $i -le 9; $i++) {
    Connect-VIServer -Server 100.67.$i.2 -User root -Password itplab123
    Get-VMHost | Foreach { Start-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq "TSM-SSH"} ) }
}