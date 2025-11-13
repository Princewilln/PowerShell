 <#
     HP Display Input Manager - Version 2
     Author: Princewill Nwokeke (modified for full automation)
     Purpose: Fully interactive HP Display manager for non-technical users
     Features:
         - Automatic HPCMSL installation if missing
         - Execution policy bypass
         - Handles multiple HP displays
         - START/END markers for each display for debugging
 #>

 # --- Step 0: Bypass Execution Policy ---
 if ($PSVersionTable.PSEdition -eq 'Desktop') {
     $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
     if ($currentPolicy -eq 'Restricted') {
         Write-Host "Execution policy is Restricted. Temporarily bypassing..." -ForegroundColor Yellow
         Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
     }
 }

 Clear-Host
 Write-Host "=== HP Display Input Manager - Version 2 ===" -ForegroundColor Cyan

 # --- Step 1: Ensure HPCMSL Module is installed ---
 if (-not (Get-Module -ListAvailable -Name HPCMSL)) {
     Write-Host "HPCMSL module not found. Attempting automatic installation..." -ForegroundColor Yellow
     try {
         Install-Module -Name HPCMSL -Force -Scope CurrentUser -AllowClobber
         Write-Host "HPCMSL module installed successfully." -ForegroundColor Green
     }
     catch {
         Write-Host "❌ Failed to install HPCMSL module: $($_.Exception.Message)" -ForegroundColor Red
         Write-Host "Please run PowerShell as Administrator to install the module." -ForegroundColor Red
         exit
     }
 }

 Import-Module HPCMSL -ErrorAction Stop
 Write-Host "Module 'HPCMSL' imported.`n" -ForegroundColor Green

 # --- Step 2: Get connected HP displays ---
 $displays = Get-HPDisplay
 if (-not $displays) {
     Write-Host "❌ No HP displays detected. Please check your connections." -ForegroundColor Red
     exit
 }

 foreach ($display in $displays) {
     $displayName = if ($display.ProductName) { $display.ProductName } else { 'Unknown Display' }

     # --- START marker for this display ---
     Write-Host "`n=== START Display: $displayName (SN: $($display.SerialNumber)) ===" -ForegroundColor Cyan

     Write-Host "--------------------------------------"
     Write-Host "Display: $displayName"
     Write-Host "Serial Number: $($display.SerialNumber)"
     Write-Host "--------------------------------------"

     # --- Show Current Settings ---
     $activeInput = $display.ActiveInput -or "N/A"
     $autoInput = $display.AutoInputEnabled -or "N/A"
     $autoSleep = $display.AutoSleepMode -or "N/A"
     $powerMode = $display.PowerManagement -or "N/A"

     Write-Host "`n[1] Current Active Input: $activeInput" -ForegroundColor Yellow
     Write-Host "[2] Auto Input Enabled: $autoInput"
     Write-Host "[3] Auto Sleep Mode: $autoSleep"
     Write-Host "[4] Power Management Mode: $powerMode"

     # --- Step 3: Auto Input Change ---
     $choice = Read-Host "`nDo you want to change Auto Input? (Y/N)"
     if ($choice -match '^[Yy]$') {
         $newVal = Read-Host "Enter new value (True/False or Enable/Disable)"
         $boolVal = switch ($newVal.ToLower()) {
             "true" { $true }
             "false" { $false }
             "enable" { $true }
             "disable" { $false }
             default { $null }
         }
         if ($boolVal -ne $null) {
             try { Set-HPDisplay -SerialNumber $display.SerialNumber -AutoInputEnabled $boolVal; Write-Host "✔ Auto Input set to $boolVal" -ForegroundColor Green }
             catch { Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red }
         } else { Write-Host "⚠ Invalid entry. Skipping." -ForegroundColor Yellow }
     }

     # --- Step 4: Auto Sleep Change ---
     $choice = Read-Host "`nDo you want to change Auto Sleep Mode? (Y/N)"
     if ($choice -match '^[Yy]$') {
         $newVal = Read-Host "Enter new value (True/False or Enable/Disable)"
         $boolVal = switch ($newVal.ToLower()) {
             "true" { $true }
             "false" { $false }
             "enable" { $true }
             "disable" { $false }
             default { $null }
         }
         if ($boolVal -ne $null) {
             try { Set-HPDisplay -SerialNumber $display.SerialNumber -AutoSleepMode $boolVal; Write-Host "✔ Auto Sleep set to $boolVal" -ForegroundColor Green }
             catch { Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red }
         } else { Write-Host "⚠ Invalid entry. Skipping." -ForegroundColor Yellow }
     }

     # --- Step 5: Power Management Change ---
     $choice = Read-Host "`nDo you want to change Power Management mode? (Y/N)"
     if ($choice -match '^[Yy]$') {
         $newVal = Read-Host "Enter new mode (Normal / PowerSave)"
         if ($newVal -in @("Normal","PowerSave")) {
             try { Set-HPDisplay -SerialNumber $display.SerialNumber -PowerManagement $newVal; Write-Host "✔ Power Management set to $newVal" -ForegroundColor Green }
             catch { Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red }
         } else { Write-Host "⚠ Invalid entry. Skipping." -ForegroundColor Yellow }
     }

     # --- Step 6: Active Input Change ---
     Write-Host "`nAvailable Input Modes:" -ForegroundColor Cyan
     $inputs = @("HDMI1","HDMI2","DP1","DP2","USBCVideo1","USBCVideo2","USBCVideo1Thunderbolt4","USBCVideo2Thunderbolt4")
     for ($i=0; $i -lt $inputs.Count; $i++) { Write-Host "[$($i+1)] $($inputs[$i])" }

     $choice = Read-Host "`nEnter the number to switch Active Input (or press Enter to skip)"
     if ($choice -and $choice -match '^\d+$' -and $choice -le $inputs.Count) {
         $selected = $inputs[$choice - 1]
         try { Set-HPDisplay -SerialNumber $display.SerialNumber -ActiveInput $selected; Write-Host "✔ Input changed to $selected" -ForegroundColor Green }
         catch { Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red }
     } else { Write-Host "⏭ Skipped Active Input change." }

     Write-Host "`n✅ Finished managing $displayName."
     # --- END marker for this display ---
     Write-Host "=== END Display: $displayName (SN: $($display.SerialNumber)) ===`n" -ForegroundColor Cyan
 }

 Write-Host "`nAll tasks completed successfully!" -ForegroundColor Cyan
