# You must run this script as an administrator.

# Use the InstanceId from the previous step. You can get this by running:
# Get-PnpDevice -Class "Display"
$InstanceId = "PCI\VEN_8086&DEV_7D45&SUBSYS_8C26103C&REV_08\3&11583659&0&10"

while ($true) {
    # Disable the device. -Confirm:$false prevents a confirmation prompt.
    Disable-PnpDevice -InstanceId $InstanceId -Confirm:$false

    # Wait for 30 seconds
    Start-Sleep -Seconds 30

    # Re-enable the device
    Enable-PnpDevice -InstanceId $InstanceId -Confirm:$false
    
    Write-Host "Display adapter disabled and re-enabled. Waiting 30 seconds..."
    Start-Sleep -Seconds 30
}
