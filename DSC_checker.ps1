#Set execution policy unrestricted
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# Registry base path for display drivers
$baseKey = "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"

# Flag to track if any key is missing or incorrect
$dscDisabled = $true

# Check for keys 0000 through 0009 (you can expand if needed)
foreach ($index in 0..9) {
    $subkey = "{0:D4}" -f $index
    $fullPath = Join-Path $baseKey $subkey

    if (Test-Path $fullPath) {
        try {
            $value = Get-ItemPropertyValue -Path $fullPath -Name "DpMstDscDisable" -ErrorAction Stop
            if ($value -ne 1) {
                $dscDisabled = $false
                break
            }
        } catch {
            $dscDisabled = $false
            break
        }
    }
}

# Output the result
if ($dscDisabled) {
    Write-Output "DSC is Disabled"
} else {
    Write-Output "DSC is Enabled"
}
