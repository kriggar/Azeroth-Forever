# Azeroth Forever native client interface installer (Windows PowerShell).
# The UI is embedded in the *client FrameXML* via a reversible patch-Z.MPQ.
# It is NOT loaded through Interface\AddOns\AzerothForeverUI.
# Keeps a verified backup of any existing CoA patch-Z and merges onto a copy.
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
        throw 'No Azeroth Forever native UI manifest exists. The original patch is unchanged.'
    }
    $installed = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    if ((-not $installed.patchSha256) -or (-not (Test-Path -LiteralPath $patch -PathType Leaf))) {
        throw 'Manifest or installed MPQ missing. Nothing has been deleted.'
    }
    $current = (Get-FileHash -Algorithm SHA256 -LiteralPath $patch).Hash.ToLowerInvariant()
    if ($current -ne $installed.patchSha256) {
        throw 'The installed patch has changed. Refusing to overwrite unrelated newer client content.'
    }
    if ($installed.originalPatchBackup) {
        if (-not (Test-Path -LiteralPath $installed.originalPatchBackup -PathType Leaf)) {
            throw 'Cannot find the saved original CoA patch. No changes were made.'
        }
        $originalSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $installed.originalPatchBackup).Hash.ToLowerInvariant()
        if ($originalSha -ne $installed.originalPatchSha256) {
            throw 'The CoA patch backup hash does not match. No changes were made.'
        }
        $tempRestore = Join-Path $data ('.patch-Z-restore-' + [guid]::NewGuid().ToString('N') + '.tmp')
        Copy-Item -LiteralPath $installed.originalPatchBackup -Destination $tempRestore
        try {
            if ((Get-FileHash -Algorithm SHA256 -LiteralPath $tempRestore).Hash.ToLowerInvariant() -ne $originalSha) {
                throw 'Original patch backup failed copy verification.'
            }
            $discardedPatch = Join-Path $data ('.patch-Z-replaced-on-restore-' + [guid]::NewGuid().ToString('N') + '.bak')
            [System.IO.File]::Replace($tempRestore, $patch, $discardedPatch, $true)
            if (Test-Path -LiteralPath $discardedPatch) { Remove-Item -LiteralPath $discardedPatch -Force }
        } finally {
            if (Test-Path -LiteralPath $tempRestore) { Remove-Item -LiteralPath $tempRestore -Force }
        }
        Write-Host "Restored the original CoA patch-Z.MPQ from its checked backup."
    } else {
        # Version 1 installs introduced a brand new patch-Z and had no prior file.
        Remove-Item -LiteralPath $patch -Force
        Write-Host 'Removed the new native UI patch; no previous patch-Z was present.'
    }
    Remove-Item -LiteralPath $manifest -Force
    if ($installed.previousAddonBackup -and
        (Test-Path -LiteralPath $installed.previousAddonBackup -PathType Container) -and
        -not (Test-Path -LiteralPath $oldAddon)) {
        New-Item -ItemType Directory -Force -Path $addons | Out-Null
        Move-Item -LiteralPath $installed.previousAddonBackup -Destination $oldAddon
    }
    Write-Host 'Client UI rollback completed. Server binaries and databases were never changed.'
    return
}

$existingPatch = Test-Path -LiteralPath $patch -PathType Leaf
$upgrading = Test-Path -LiteralPath $manifest -PathType Leaf
$priorInstall = $null
$mergeSource = $patch
$currentInstalledSha = $null
if ($upgrading) {
    # Upgrade the previously installed native patch from the pristine,
    # verified original CoA backup. Never merge into the old UI recursively.
    $priorInstall = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    if (-not $existingPatch -or -not $priorInstall.patchSha256) {
        throw 'Previous UI install record is incomplete; refusing to upgrade.'
    }
    $currentInstalledSha = (Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($currentInstalledSha -ne $priorInstall.patchSha256) {
        throw 'Existing Azeroth Forever MPQ was modified outside this installer. Refusing to overwrite it.'
    }
    if (-not $priorInstall.originalPatchBackup) {
        throw 'Previous UI install has no original CoA MPQ backup; use Restore-Native-UI first.'
    }
    if (-not (Test-Path -LiteralPath $priorInstall.originalPatchBackup -PathType Leaf)) {
        throw 'Original CoA MPQ backup is missing. Upgrade refused; installed client unchanged.'
    }
    $mergeSource = (Resolve-Path -LiteralPath $priorInstall.originalPatchBackup).Path
    $baselineSha = (Get-FileHash -LiteralPath $mergeSource -Algorithm SHA256).Hash.ToLowerInvariant()
    if (-not $priorInstall.originalPatchSha256 -or $baselineSha -ne $priorInstall.originalPatchSha256) {
        throw 'Original CoA backup integrity check failed; refusing to upgrade.'
    }
    Write-Host 'Existing Azeroth Forever native UI detected: validated patch and pristine CoA backup.'
    Write-Host 'UPGRADE MODE: new interface will be merged from the original CoA MPQ, not the old UI.'
} elseif ($existingPatch) {
    $currentInstalledSha = (Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Host "Existing CoA patch-Z.MPQ detected: $patch"
    Write-Host 'Its contents will be preserved in a separate backup and verified through MPQ readback.'
}

if (-not $FrameXMLArchive) {
    $FrameXMLArchive = Join-Path $data 'patch-B.MPQ'
    if (-not (Test-Path -LiteralPath $FrameXMLArchive) -and $existingPatch) {
        $FrameXMLArchive = $patch
    }
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
$buildArguments = @('-B', $buildScript, '--upstream', $sourceRoot,
                    '--toc-archive', $FrameXMLArchive, '--mpqcli', $mpqExe,
                    '--output', $destination)
if ($existingPatch) {
    $buildArguments += @('--merge-archive', $mergeSource)
}
& $python @buildArguments
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

# The native full-UI payload has already passed the builder's MPQ readback.
# We now copy the original patch outside Data and confirm its SHA256.
$backupRoot = Join-Path $client 'AzerothForever-UI-Backups'
$backupPatch = $null
$originalSha = $null
if ($existingPatch) {
    $originalSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $mergeSource).Hash.ToLowerInvariant()
    $report = Get-Content -LiteralPath ($destination + '.json') -Raw | ConvertFrom-Json
    if (-not $report.merged_existing_patch -or
        $report.original_patch_sha256 -ne $originalSha -or
        $report.original_members_verified -le 0) {
        throw 'Original CoA MPQ preservation was not verified. No client files changed.'
    }
    if ($upgrading) {
        # Preserve the original backup across every update. Never replace it
        # with the already modified current Azeroth Forever archive.
        $backupPatch = $mergeSource
        Write-Host "Reusing verified original CoA backup: $backupPatch"
    } else {
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        $backupPatch = Join-Path $backupRoot ('patch-Z-original-' + (Get-Date -Format 'yyyyMMdd-HHmmss') +
            '-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.MPQ')
        Copy-Item -LiteralPath $patch -Destination $backupPatch -ErrorAction Stop
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $backupPatch).Hash.ToLowerInvariant() -ne $originalSha) {
            Remove-Item -LiteralPath $backupPatch -Force
            throw 'Existing CoA patch backup hash mismatched; refusing to install.'
        }
        Write-Host "Original CoA patch saved separately: $backupPatch"
    }
}
$backupAddon = if ($upgrading) { $priorInstall.previousAddonBackup } else { $null }
$manifestSwapBackup = $null
$manifestPending = Join-Path $data ('.af-manifest-' + [guid]::NewGuid().ToString('N') + '.tmp')
$swapped = $false
$installationComplete = $false
$swapBackup = $null
$pending = Join-Path $data ('.patch-Z-azeroth-forever-' + [guid]::NewGuid().ToString('N') + '.tmp')
try {
    # Ensure the client patch is never partially written: stage on the same
    # volume, verify, then atomically replace the existing file.
    Copy-Item -LiteralPath $destination -Destination $pending -ErrorAction Stop
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $pending).Hash.ToLowerInvariant() -ne $sha) {
        throw 'Native UI patch copy failed checksum verification.'
    }
    if ($existingPatch) {
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $patch).Hash.ToLowerInvariant() -ne $currentInstalledSha) {
            throw 'The installed patch changed after backup validation; refusing to replace it.'
        }
        $swapBackup = Join-Path $data ('.patch-Z-atomic-swap-backup-' + [guid]::NewGuid().ToString('N') + '.bak')
        [System.IO.File]::Replace($pending, $patch, $swapBackup, $true)
    } else {
        [System.IO.File]::Move($pending, $patch)
    }
    $swapped = $true
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $patch).Hash.ToLowerInvariant() -ne $sha) {
        throw 'Installed native UI patch hash mismatched.'
    }
    if (Test-Path -LiteralPath $oldAddon -PathType Container) {
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        $backupAddon = Join-Path $backupRoot ('AzerothForeverUI-old-' +
            (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' +
            [guid]::NewGuid().ToString('N').Substring(0,6))
        Move-Item -LiteralPath $oldAddon -Destination $backupAddon
    }
    [pscustomobject]@{
        version = 3
        sourceCommit = $srcCommit
        patchSha256 = $sha
        patchPath = $patch
        originalPatchBackup = $backupPatch
        originalPatchSha256 = $originalSha
        previousAddonBackup = $backupAddon
        builtFromArchive = $FrameXMLArchive
        gameExecutable = (Split-Path -Leaf $exe)
        clientTestedInGame = $false
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPending -Encoding UTF8
    if ($upgrading) {
        $manifestSwapBackup = Join-Path $data ('.af-manifest-previous-' + [guid]::NewGuid().ToString('N') + '.bak')
        [System.IO.File]::Replace($manifestPending, $manifest, $manifestSwapBackup, $true)
    } else {
        [System.IO.File]::Move($manifestPending, $manifest)
    }
    $installationComplete = $true
} catch {
    # If a later step failed, put the player's *original* patch back.
    # Never delete an original MPQ as a way of fixing the installation.
    if ($swapped -and (Test-Path -LiteralPath $patch -PathType Leaf)) {
        # Restore precisely the archive that existed before this attempt, even
        # during upgrades. The prior UI and first-ever original backup survive.
        if ($existingPatch -and $swapBackup -and
            (Test-Path -LiteralPath $swapBackup -PathType Leaf)) {
            $restorePending = Join-Path $data ('.patch-Z-emergency-' + [guid]::NewGuid().ToString('N') + '.tmp')
            Copy-Item -LiteralPath $swapBackup -Destination $restorePending
            if ((Get-FileHash -Algorithm SHA256 -LiteralPath $restorePending).Hash.ToLowerInvariant() -eq $currentInstalledSha) {
                $emergencyOldPatch = Join-Path $data ('.patch-Z-emergency-swap-' + [guid]::NewGuid().ToString('N') + '.bak')
                [System.IO.File]::Replace($restorePending, $patch, $emergencyOldPatch, $true)
                if (Test-Path -LiteralPath $emergencyOldPatch) {
                    Remove-Item -LiteralPath $emergencyOldPatch -Force
                }
            } else {
                Write-Warning "Previous MPQ retained at $swapBackup; automatic restoration could not be verified."
            }
        } elseif (-not $existingPatch) {
            Remove-Item -LiteralPath $patch -Force
        }
    }
    if ($manifestSwapBackup -and (Test-Path -LiteralPath $manifestSwapBackup -PathType Leaf)) {
        $manifestRestore = Join-Path $data ('.af-manifest-emergency-' + [guid]::NewGuid().ToString('N') + '.bak')
        [System.IO.File]::Replace($manifestSwapBackup, $manifest, $manifestRestore, $true)
        if (Test-Path -LiteralPath $manifestRestore) { Remove-Item -LiteralPath $manifestRestore -Force }
    }
    if ($backupAddon -and (Test-Path -LiteralPath $backupAddon) -and -not (Test-Path -LiteralPath $oldAddon)) {
        Move-Item -LiteralPath $backupAddon -Destination $oldAddon
    }
    throw
} finally {
    if (Test-Path -LiteralPath $pending) { Remove-Item -LiteralPath $pending -Force }
    if (Test-Path -LiteralPath $manifestPending) { Remove-Item -LiteralPath $manifestPending -Force }
    if ($installationComplete -and $manifestSwapBackup -and
        (Test-Path -LiteralPath $manifestSwapBackup)) {
        Remove-Item -LiteralPath $manifestSwapBackup -Force
    }
    # Clean the short-lived swap backup ONLY after the permanent, hash-checked
    # original patch backup and manifest both exist. If installation fails,
    # retaining this extra copy is safer than silently losing it.
    if ($installationComplete -and $swapBackup -and (Test-Path -LiteralPath $swapBackup)) {
        Remove-Item -LiteralPath $swapBackup -Force
    }
}
Write-Host 'Native full-interface patch installed or upgraded; pristine CoA archive backup preserved.'
Write-Host 'No addon or game executable was patched. CoA class and map assets remain in the archive.'
Write-Warning 'Modified FrameXML may be rejected by your CoA executable. If needed, close the game and run Restore-Native-UI.bat.'
Write-Host 'The new interface is experimental until tested in-game against your particular CoA client.'
