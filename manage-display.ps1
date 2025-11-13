<# 
    HP Display Input Manager (Interactive Full Version)
    Author: Princewill Nwokeke
    Purpose: Handle monitor settings via HP CMSL automatically for non‑technical user
#>

# Clear screen
Clear-Host
Write-Host "=== HP Display Input Manager ===" -ForegroundColor Cyan
Write-Host ""

# STEP 0: Ensure Execution Policy
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq 'Restricted') {
    Write-Host "Execution policy is Restricted. Updating to RemoteSigned for CurrentUser..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "Execution policy changed to RemoteSigned." -ForegroundColor Green
    }
    catch {
        Write-Host "Error changing execution policy: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
        exit
    }
}

# STEP 1: Check / Install HP CMSL Module
$moduleName = "HPCMSL"
if (-not (Get-Module -ListAvailable -Name $moduleName)) {
    Write-Host "HP CMSL module not found. Installing module '$moduleName' from PowerShell Gallery..." -ForegroundColor Yellow
    try {
        Install-Module -Name $moduleName -Scope AllUsers -Force -AcceptLicense
        Write-Host "Module '$moduleName' installed." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install module '$moduleName': $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Cannot continue without required HP module." -ForegroundColor Red
        exit
    }
}
# Import the module
try {
    Import-Module $moduleName -Force
    Write-Host "Module '$moduleName' imported." -ForegroundColor Green
}
catch {
    Write-Host "Failed to import module '$moduleName': $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# STEP 2: Get displays
try {
    $displays = Get-HPDisplay
}
catch {
    Write-Host "Error: Could not run Get-HPDisplay. Please ensure your monitor supports HP CMSL commands." -ForegroundColor Red
    exit
}

if (-not $displays) {
    Write-Host "No HP display objects returned." -ForegroundColor Red
    exit
}

# STEP 3: Interactive loop
foreach ($display in $displays) {
    # Safe naming
    $displayName = if ($display.ProductName) { $display.ProductName } elseif ($display.Name) { $display.Name } else { "Unknown Display" }
    $serial = if ($display.SerialNumber) { $display.SerialNumber } else { "Unknown Serial" }

    Write-Host "`n--------------------------------------"
    Write-Host "Display: $displayName"
    Write-Host "Serial Number: $serial"
    Write-Host "--------------------------------------"

    # Active Input
    $activeInput = if ($display.ActiveInput) { $display.ActiveInput } else { "N/A" }
    Write-Host "`n[1] Current Active Input: $activeInput" -ForegroundColor Yellow

    # Auto Input
    $autoInput = if ($display.AutoInputEnabled -ne $null) { $display.AutoInputEnabled } else { "N/A" }
    Write-Host "`n[2] Auto Input Enabled: $autoInput"
    $choice = Read-Host "Do you want to change Auto Input? (Y/N)"
    if ($choice -match '^[Yy]$') {
        $newVal = Read-Host "Enter new value (True/False or Enable/Disable)"
        switch ($newVal.ToLower()) {
            "true"   { $boolVal = $true }
            "false"  { $boolVal = $false }
            "enable" { $boolVal = $true }
            "disable"{ $boolVal = $false }
            default  { $boolVal = $null }
        }
        if ($boolVal -ne $null) {
            try {
                Set-HPDisplay -SerialNumber $serial -AutoInputEnabled $boolVal
                Write-Host "Auto Input set to $boolVal" -ForegroundColor Green
            }
            catch {
                Write-Host "Error changing Auto Input: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Invalid entry. Skipping Auto Input change." -ForegroundColor Yellow
        }
    }

    # Auto Sleep Mode
    $autoSleep = if ($display.AutoSleepMode -ne $null) { $display.AutoSleepMode } else { "N/A" }
    Write-Host "`n[3] Auto Sleep Mode: $autoSleep"
    $choice = Read-Host "Do you want to change Auto Sleep Mode? (Y/N)"
    if ($choice -match '^[Yy]$') {
        $newVal = Read-Host "Enter new value (True/False or Enable/Disable)"
        switch ($newVal.ToLower()) {
            "true"   { $boolVal = $true }
            "false"  { $boolVal = $false }
            "enable" { $boolVal = $true }
            "disable"{ $boolVal = $false }
            default  { $boolVal = $null }
        }
        if ($boolVal -ne $null) {
            try {
                Set-HPDisplay -SerialNumber $serial -AutoSleepMode $boolVal
                Write-Host "Auto Sleep Mode set to $boolVal" -ForegroundColor Green
            }
            catch {
                Write-Host "Error changing Auto Sleep Mode: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Invalid entry. Skipping Auto Sleep change." -ForegroundColor Yellow
        }
    }

    # Power Management
    $powerMode = if ($display.PowerManagement) { $display.PowerManagement } else { "N/A" }
    Write-Host "`n[4] Power Management Mode: $powerMode"
    $choice = Read-Host "Do you want to change Power Management mode? (Y/N)"
    if ($choice -match '^[Yy]$') {
        $newVal = Read-Host "Enter new mode (Normal / PowerSave)"
        if ($newVal -in @("Normal","PowerSave")) {
            try {
                Set-HPDisplay -SerialNumber $serial -PowerManagement $newVal
                Write-Host "Power Management set to $newVal" -ForegroundColor Green
            }
            catch {
                Write-Host "Error changing Power Management: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Invalid entry. Skipping Power Management change." -ForegroundColor Yellow
        }
    }

    # Change Active Input
    Write-Host "`n--------------------------------------"
    Write-Host "Available Input Modes:" -ForegroundColor Cyan
    $inputs = @("HDMI1","HDMI2","DP1","DP2","USBCVideo1","USBCVideo2","USBCVideo1Thunderbolt4","USBCVideo2Thunderbolt4")
    for ($i=0; $i -lt $inputs.Count; $i++) {
        Write-Host "[$($i+1)] $($inputs[$i])"
    }
    $choice = Read-Host "`nEnter the number to switch Active Input (or press Enter to skip)"
    if ($choice -and $choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $inputs.Count) {
        $selected = $inputs[[int]$choice - 1]
        try {
            Set-HPDisplay -SerialNumber $serial -ActiveInput $selected
            Write-Host "Display input changed to $selected" -ForegroundColor Green
        }
        catch {
            Write-Host "Error changing Active Input: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Skipped Active Input change."
    }

    Write-Host "`nFinished managing $displayName."
    Write-Host "--------------------------------------"
}

Write-Host "`nAll tasks completed!" -ForegroundColor Cyan
