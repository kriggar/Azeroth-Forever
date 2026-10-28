# Azeroth Forever native client interface installer (Windows PowerShell).
# The UI is embedded in the *client FrameXML* via a reversible patch-Z.MPQ.
# It is NOT loaded through Interface\AddOns\AzerothForeverUI.
# Never edits Wow.exe/Ascension.exe, CoA game data, existing MPQs or servers.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ClientFolder,
    [string]$FrameXMLArchive = '',
    [string]$ServerRoot = '',
    [switch]$BuildOnly,
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'
$toolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$client = (Resolve-Path -LiteralPath $ClientFolder).Path
$data = Join-Path $client 'Data'
$addons = Join-Path $client 'Interface\AddOns'
$oldAddon = Join-Path $addons 'AzerothForeverUI'
$patch = Join-Path $data 'patch-Z.MPQ'
$manifest = Join-Path $data 'patch-Z.MPQ.azeroth-forever.json'
$working = Join-Path $env:LOCALAPPDATA 'AzerothForever\NativeUI'
$srcCommit = 'c5149b96a9938ae9073ff8bb1662e42d2b7b5090'
$mpqDigest = 'ca4bc40d24ff0ae094e8e6118591a59cecb56b9227923e806e9a116d5e761277'
$mpqURL = 'https://github.com/thegraydot/mpqcli/releases/download/v0.11.0/mpqcli-windows-amd64.exe'
$srcURL = 'https://codeload.github.com/Adrestie/mod-forever-ui/zip/' + $srcCommit

if (-not (Test-Path -LiteralPath $data -PathType Container)) {
    throw "This is not a WoW client folder (missing Data): $client"
}
$exe = @('Ascension.exe','Wow.exe','WoW.exe') |
    ForEach-Object { Join-Path $client $_ } |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1
if (-not $exe) { throw "Cannot find Ascension.exe or Wow.exe in $client" }

$running = Get-Process -Name Ascension,Wow,WoW -ErrorAction SilentlyContinue
if ($running) { throw 'Close the WoW client before installing or restoring the interface.' }

if ($Restore) {
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        throw 'No Azeroth Forever native UI manifest exists. Refusing to delete unknown patch files.'
    }
    $installed = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    if ((-not $installed.patchSha256) -or (-not (Test-Path -LiteralPath $patch -PathType Leaf))) {
        throw 'Manifest/patch mismatch; no restore was performed.'
    }
    $current = (Get-FileHash -Algorithm SHA256 -LiteralPath $patch).Hash.ToLowerInvariant()
    if ($current -ne $installed.patchSha256) {
        throw 'patch-Z.MPQ has changed. Refusing to remove modified or unrelated client data.'
    }
    Remove-Item -LiteralPath $patch -Force
    Remove-Item -LiteralPath $manifest -Force
    if ($installed.previousAddonBackup -and
        (Test-Path -LiteralPath $installed.previousAddonBackup -PathType Container) -and
        -not (Test-Path -LiteralPath $oldAddon)) {
        New-Item -ItemType Directory -Force -Path $addons | Out-Null
        Move-Item -LiteralPath $installed.previousAddonBackup -Destination $oldAddon
    }
    Write-Host 'Removed the Azeroth Forever native interface patch and restored the previous toolbar (if present).'
    Write-Host 'Original game executables, CoA databases and other MPQs were never changed.'
    return
}

if (Test-Path -LiteralPath $patch) {
    throw "patch-Z.MPQ already exists. Refusing to replace or merge unknown client content: $patch"
}
if (Test-Path -LiteralPath $manifest) {
    throw 'A prior native UI install manifest exists but the archive is missing. Investigate before trying again.'
}
if (-not $FrameXMLArchive) {
    $FrameXMLArchive = Join-Path $data 'patch-B.MPQ'
}
if (-not (Test-Path -LiteralPath $FrameXMLArchive -PathType Leaf)) {
    throw "Could not find original CoA FrameXML archive: $FrameXMLArchive. Specify -FrameXMLArchive explicitly."
}
$FrameXMLArchive = (Resolve-Path -LiteralPath $FrameXMLArchive).Path

New-Item -ItemType Directory -Force -Path $working | Out-Null
$toolDir = Join-Path $working 'tools'
$mpqExe = Join-Path $toolDir 'mpqcli-windows-amd64.exe'
New-Item -ItemType Directory -Force -Path $toolDir | Out-Null
if (-not (Test-Path -LiteralPath $mpqExe -PathType Leaf)) {
    Write-Host 'Downloading the pinned open-source MPQ archive tool...'
    Invoke-WebRequest -Uri $mpqURL -OutFile $mpqExe -MaximumRedirection 5
}
$got = (Get-FileHash -Algorithm SHA256 -LiteralPath $mpqExe).Hash.ToLowerInvariant()
if ($got -ne $mpqDigest) {
    Remove-Item -LiteralPath $mpqExe -Force
    throw 'MPQ tool failed pinned SHA256 verification. Refusing to execute it.'
}

$sourceRoot = Join-Path $working ("mod-forever-ui-" + $srcCommit)
if (-not (Test-Path (Join-Path $sourceRoot 'data\addon\ForeverUI\ForeverUI.toc'))) {
    $zip = Join-Path $working ('mod-forever-ui-' + $srcCommit + '.zip')
    Write-Host 'Downloading the pinned GPL-2.0 full-interface source and art...'
    Invoke-WebRequest -Uri $srcURL -OutFile $zip -MaximumRedirection 5
    Expand-Archive -LiteralPath $zip -DestinationPath $working -Force
}
foreach ($required in @('LICENSE','data\addon\ForeverUI\ForeverUI.toc','data\art\interface\foreverui')) {
    if (-not (Test-Path (Join-Path $sourceRoot $required))) {
        throw "Incomplete upstream UI source: $required"
    }
}

# Reuse the Python runtime included with the installed official CoA Manager.
$python = $null
if ($ServerRoot) {
    $candidate = Join-Path $ServerRoot 'Runtime\python\python.exe'
    if (Test-Path -LiteralPath $candidate) { $python = $candidate }
}
if (-not $python) {
    $candidate = Join-Path (Split-Path -Parent $client) 'CoA Server\Runtime\python\python.exe'
    if (Test-Path -LiteralPath $candidate) { $python = $candidate }
}
if (-not $python) {
    foreach ($candidate in @(
        'C:\Azeroth-Forever\Azeroth-Forever-Official-CoA-Server-Offline\CoA Server\Runtime\python\python.exe',
        'python.exe'
    )) {
        if ($candidate -eq 'python.exe' -and -not (Get-Command python.exe -ErrorAction SilentlyContinue)) { continue }
        try {
            & $candidate --version 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $python = $candidate; break }
        } catch { }
    }
}
if (-not $python) { throw 'Python was not detected. Pass -ServerRoot pointing to the installed CoA Server folder.' }

$buildScript = Join-Path $toolRoot 'build_native_patch.py'
if (-not (Test-Path -LiteralPath $buildScript -PathType Leaf)) {
    throw "Missing native patch builder: $buildScript"
}
$destination = Join-Path $working 'patch-Z.MPQ'
if (Test-Path $destination) { Remove-Item $destination -Force }
if (Test-Path ($destination + '.json')) { Remove-Item ($destination + '.json') -Force }
Write-Host 'Building the complete client-native MPQ overlay...'
& $python -B $buildScript --upstream $sourceRoot --toc-archive $FrameXMLArchive --mpqcli $mpqExe --output $destination
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
    throw 'Native UI build or MPQ readback verification failed. No client files changed.'
}

$sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash.ToLowerInvariant()
if ($BuildOnly) {
    Write-Host "Build and readback verification passed: $destination"
    Write-Host "SHA256: $sha"
    Write-Host 'No client files were changed (BuildOnly selected).'
    return
}

$backupAddon = $null
if (Test-Path -LiteralPath $oldAddon -PathType Container) {
    $backupBase = Join-Path $client 'AzerothForever-UI-Backups'
    New-Item -ItemType Directory -Force -Path $backupBase | Out-Null
    $backupAddon = Join-Path $backupBase ('AzerothForeverUI-old-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Move-Item -LiteralPath $oldAddon -Destination $backupAddon
}
try {
    Copy-Item -LiteralPath $destination -Destination $patch -ErrorAction Stop
    $readbackSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $patch).Hash.ToLowerInvariant()
    if ($readbackSha -ne $sha) { throw 'Installed MPQ checksum mismatch.' }
    [pscustomobject]@{
        version = 1
        sourceCommit = $srcCommit
        patchSha256 = $sha
        patchPath = $patch
        previousAddonBackup = $backupAddon
        builtFromArchive = $FrameXMLArchive
        gameExecutable = (Split-Path -Leaf $exe)
        clientTestedInGame = $false
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifest -Encoding UTF8
} catch {
    if (Test-Path $patch) { Remove-Item -LiteralPath $patch -Force }
    if ($backupAddon -and (Test-Path $backupAddon) -and -not (Test-Path $oldAddon)) {
        Move-Item -LiteralPath $backupAddon -Destination $oldAddon
    }
    throw
}
Write-Host 'Built-in full-interface MPQ installed into the CoA client.'
Write-Host 'Nothing was installed in Interface\AddOns.'
Write-Host 'It does not patch Ascension.exe, Wow.exe, your database, or CoA class definitions.'
Write-Warning 'The 3.3.5 client can reject modified FrameXML. If that happens, close the game and rerun this script with -Restore.'
Write-Host 'This patch uses a third-party modern UI port as the starting point; native CoA compatibility requires in-game testing.'
