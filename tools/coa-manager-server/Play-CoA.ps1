param(
  [string]$ClientFolder = '',
  [switch]$ClientOnly,
  [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-CoAClient {
  param([string]$StartLocation)
  $oneUp = Split-Path -Parent $StartLocation
  $twoUp = Split-Path -Parent $oneUp
  $candidates = @(
    (Join-Path $StartLocation 'client'),
    (Join-Path $oneUp 'client'),
    (Join-Path $twoUp 'client'),
    'D:\world of warcraft server\client'
  )
  foreach ($candidate in ($candidates | Select-Object -Unique)) {
    if (-not (Test-Path -LiteralPath (Join-Path $candidate 'Data') -PathType Container)) { continue }
    foreach ($executable in @('Ascension.exe','Wow.exe','WoW.exe')) {
      if (Test-Path -LiteralPath (Join-Path $candidate $executable) -PathType Leaf) {
        return $candidate
      }
    }
  }
  return $null
}

function Update-Realmlist {
  param([string]$Folder)
  $localeFolders = @(Get-ChildItem -LiteralPath (Join-Path $Folder 'Data') -Directory)
  $changedCount = 0
  $newline = [Environment]::NewLine
  foreach ($locale in $localeFolders) {
    $realmlist = Join-Path $locale.FullName 'realmlist.wtf'
    $languageFile = Join-Path $locale.FullName ("locale-" + $locale.Name + ".MPQ")
    if (-not (Test-Path -LiteralPath $realmlist -PathType Leaf) -and
        -not (Test-Path -LiteralPath $languageFile -PathType Leaf)) { continue }

    $original = if (Test-Path -LiteralPath $realmlist -PathType Leaf) {
      [IO.File]::ReadAllText($realmlist)
    } else { '' }

    if ($original -match '(?im)^\s*set\s+realmlist\s+') {
      $text = [regex]::Replace(
        $original, '(?im)^\s*set\s+realmlist\s+[^\r\n]*', 'set realmlist 127.0.0.1'
      )
    } elseif ([string]::IsNullOrWhiteSpace($original)) {
      $text = 'set realmlist 127.0.0.1' + $newline
    } else {
      $text = $original.TrimEnd([char]13, [char]10) + $newline + 'set realmlist 127.0.0.1' + $newline
    }

    if ($text -ne $original) {
      if (Test-Path -LiteralPath $realmlist -PathType Leaf) {
        $backup = Join-Path $Root 'Realmlist-Backups'
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupName = 'realmlist-' + $locale.Name + '-' + $stamp +
          '-' + [guid]::NewGuid().ToString('N').Substring(0,6) + '.wtf'
        Copy-Item -LiteralPath $realmlist -Destination (Join-Path $backup $backupName)
      }
      [IO.File]::WriteAllText($realmlist, $text, (New-Object System.Text.UTF8Encoding($false)))
      $changedCount++
    }
  }
  if ($changedCount -eq 0) {
    Write-Host 'Client realmlist is already set, or no locale data were found.'
  } else {
    Write-Host "Updated $changedCount realmlist file(s) to 127.0.0.1; previous settings are backed up."
  }
}

if (-not $ClientOnly) {
  $startScript = Join-Path $Root 'Install-And-Start.ps1'
  if (-not (Test-Path -LiteralPath $startScript)) {
    throw "Missing Azeroth Forever server startup script: $startScript"
  }
  & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $startScript
  if ($LASTEXITCODE -ne 0) {
    throw 'CoA server startup did not succeed. Read the startup error above.'
  }
}

if (-not $ClientFolder) { $ClientFolder = Find-CoAClient -StartLocation $Root }
if (-not $ClientFolder) {
  throw 'Game client not detected. Extract this server folder next to your existing client folder.'
}
$ClientFolder = (Resolve-Path -LiteralPath $ClientFolder).Path
if (-not (Test-Path -LiteralPath (Join-Path $ClientFolder 'Data') -PathType Container)) {
  throw 'Selected client is missing its Data folder.'
}
$exe = @('Ascension.exe','Wow.exe','WoW.exe') | ForEach-Object {
  Join-Path $ClientFolder $_
} | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $exe) { throw 'Selected CoA client is missing Ascension.exe or Wow.exe.' }

if (-not $NoLaunch) {
  $existing = Get-Process -Name Ascension,Wow,WoW -ErrorAction SilentlyContinue
  if ($existing) { throw 'Close the running game client before switching its realmlist.' }
}

Update-Realmlist -Folder $ClientFolder
if ($NoLaunch) {
  Write-Host 'Client realmlist smoke test completed without launching the game.'
  return
}
Write-Host 'Launching your Conquest of Azeroth client...'
Write-Host 'Test account details are saved in LOCAL_LOGIN.txt in the server folder.'
Start-Process -FilePath $exe -WorkingDirectory $ClientFolder
