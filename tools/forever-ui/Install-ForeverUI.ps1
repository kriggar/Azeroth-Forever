# Install the CoA-compatible Azeroth Forever UI into an existing compatible client.
# No proprietary UI/game files are distributed or replaced.
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$ClientFolder = '',
    [switch]$Uninstall
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-CompatibleClient([string]$start) {
    $parent = Split-Path -Parent $start
    $grandparent = Split-Path -Parent $parent
    foreach ($candidate in @(
        (Join-Path $start 'client'), (Join-Path $parent 'client'),
        (Join-Path $grandparent 'client'), 'D:\world of warcraft server\client'
    )) {
        if (-not (Test-Path (Join-Path $candidate 'Data') -PathType Container)) { continue }
        foreach ($exe in @('Ascension.exe','Wow.exe','WoW.exe')) {
            if (Test-Path (Join-Path $candidate $exe) -PathType Leaf) { return $candidate }
        }
    }
    return $null
}

if (-not $ClientFolder) { $ClientFolder = Find-CompatibleClient $root }
if (-not $ClientFolder) {
    throw 'CoA client not found automatically. Pass -ClientFolder "D:\path\to\your\client".'
}
$ClientFolder = (Resolve-Path -LiteralPath $ClientFolder).Path
if (-not (Test-Path -LiteralPath (Join-Path $ClientFolder 'Data') -PathType Container)) {
    throw "Not a valid CoA game client (missing Data directory): $ClientFolder"
}
$hasExe = @('Ascension.exe','Wow.exe','WoW.exe') | Where-Object {
    Test-Path -LiteralPath (Join-Path $ClientFolder $_) -PathType Leaf
}
if (-not $hasExe) { throw "Not a supported CoA client path: $ClientFolder" }
$running = Get-Process -Name Ascension,Wow,WoW -ErrorAction SilentlyContinue
if ($running) { throw 'Close the WoW client before installing or restoring the UI.' }

$source = Join-Path $root 'AzerothForeverUI'
$target = Join-Path $ClientFolder 'Interface\AddOns\AzerothForeverUI'
$backup = Join-Path $ClientFolder 'Interface\AzerothForeverBackups'

if ($Uninstall) {
    if (Test-Path -LiteralPath $target -PathType Container) {
        if ($PSCmdlet.ShouldProcess($target, 'Uninstall AzerothForeverUI addon')) {
            Remove-Item -LiteralPath $target -Force -Recurse
            Write-Host 'Addon uninstalled. Relaunch the client for its original UI.'
        }
    } else { Write-Host 'Addon is not installed.' }
    return
}

foreach ($file in @('AzerothForeverUI.toc','AzerothForeverUI.lua')) {
    if (-not (Test-Path -LiteralPath (Join-Path $source $file) -PathType Leaf)) {
        throw "Incomplete addon source; missing $file"
    }
}
if ($PSCmdlet.ShouldProcess($target, 'Install Azeroth Forever UI addon')) {
    if (Test-Path -LiteralPath $target -PathType Container) {
        New-Item -ItemType Directory -Force -Path $backup | Out-Null
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $destination = Join-Path $backup ('AzerothForeverUI-' + $timestamp)
        Move-Item -LiteralPath $target -Destination $destination
        Write-Host "Existing addon backed up to: $destination"
    }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item -LiteralPath (Join-Path $source 'AzerothForeverUI.toc') -Destination $target
    Copy-Item -LiteralPath (Join-Path $source 'AzerothForeverUI.lua') -Destination $target
    Write-Host "Installed AzerothForeverUI to: $target"
    Write-Host 'At the character selection AddOns screen, enable it (Load out of date AddOns if necessary).'
    Write-Host 'In-game: /afui on | /afui off | /afui achievements'
}
