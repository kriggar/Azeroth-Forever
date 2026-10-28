# Select the CoA game-client folder graphically, then install or restore
# the native client MPQ. No scripting skills required.
param([switch]$Restore, [switch]$BuildOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
$browser = New-Object System.Windows.Forms.FolderBrowserDialog
$browser.Description = 'Select the CoA client folder containing Ascension.exe or Wow.exe'
$browser.ShowNewFolderButton = $false
if ($browser.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host 'Cancelled; no client files changed.'
    return
}
$installer = Join-Path $PSScriptRoot 'Install-NativeForeverUI.ps1'
& $installer -ClientFolder $browser.SelectedPath -Restore:$Restore -BuildOnly:$BuildOnly
if (-not $?) { exit 1 }
