# ============================================
# GPO & Windows Update Cache Reset Script (Run as Admin)
# ============================================

# --- ADMIN CHECK & ELEVATE ---
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Host "Elevating script to run as Administrator..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- LOG SETUP ---
$LogFolder = "C:\Temp"
$LogPath   = "$LogFolder\Policy_Reset_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

if (!(Test-Path $LogFolder)) { New-Item -Path $LogFolder -ItemType Directory | Out-Null }
Start-Transcript -Path $LogPath -Append

Write-Host "`n===== POLICY RESET STARTED =====" -ForegroundColor Cyan

# --- DELETE GPO FILES ---
Write-Host "Deleting GroupPolicy folder..."
Remove-Item "C:\Windows\System32\GroupPolicy\*" -Recurse -Force -ErrorAction SilentlyContinue

# --- CLEAR WINDOWS UPDATE CACHE ---
Write-Host "Deleting SoftwareDistribution folder..."
Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue

# --- GPUPDATE ---
Write-Host "Updating Group Policy..."
cmd.exe /c "echo N | gpupdate /force"

Write-Host "`n===== PROCESS COMPLETED =====" -ForegroundColor Cyan
Stop-Transcript

# --- WAIT BEFORE EXIT ---
Write-Host "Press any key to exit..."
[System.Console]::ReadKey() | Out-Null
Exit 0
