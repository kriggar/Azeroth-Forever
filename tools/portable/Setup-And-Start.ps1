param(
  [switch]$SkipDownload
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Root = (Resolve-Path $PSScriptRoot).Path
$Server = Join-Path $Root 'Server'
$Cache = Join-Path $Root '.downloads'
$Archive = Join-Path $Cache 'base.tar.zst.001'
$BaseUri = 'https://github.com/Corfirean/coa-server-build/releases/download/base/base.tar.zst.001'
$BaseSha256 = '2da8ddcffde326f49e1ce73c9fc1df1ed1d8017cc281977d607bce90ba0b5936'

function Ensure-Baseline {
  $manager = Join-Path $Server 'Scripts\manage.py'
  $python = Join-Path $Server 'Runtime\python\python.exe'
  $world = Join-Path $Server 'Core\worldserver.exe'
  if ((Test-Path $manager) -and (Test-Path $python) -and (Test-Path $world)) {
    Write-Host 'Using existing portable CoA server installation.'
    return
  }

  if ((Test-Path $Server) -and ((Get-ChildItem -LiteralPath $Server -Force | Measure-Object).Count -gt 0)) {
    throw "Server folder exists but is incomplete. Move it aside before retrying: $Server"
  }

  if ($SkipDownload) {
    throw 'No complete server is installed. Run Start_Azeroth_Forever.bat to download it.'
  }

  New-Item -ItemType Directory -Force -Path $Cache | Out-Null
  if (-not (Test-Path $Archive)) {
    Write-Host 'First launch: downloading the original CoA Server Manager base package (approximately 1.5 GB).'
    Write-Host 'The download comes from the ORIGINAL publisher, not a repack hosted by Azeroth Forever.'
    try {
      Import-Module BitsTransfer -ErrorAction Stop
      Start-BitsTransfer -Source $BaseUri -Destination $Archive -ErrorAction Stop
    } catch {
      Write-Warning 'BITS is unavailable or failed; switching to the HTTPS downloader.'
      Invoke-WebRequest -Uri $BaseUri -OutFile $Archive -UseBasicParsing
    }
  }

  Write-Host 'Checking the publisher release archive against its pinned SHA-256 digest...'
  $digest = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($digest -ne $BaseSha256) {
    Remove-Item -LiteralPath $Archive -Force
    throw 'The downloaded server did not match the pinned SHA-256. It has been deleted; no files were installed.'
  }

  $stage = Join-Path $Root '.installing-server'
  if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Force -Recurse }
  New-Item -ItemType Directory -Force -Path $stage | Out-Null

  $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
  if (-not $tar) {
    throw 'Windows tar.exe is required. Use a current Windows 10/11 installation.'
  }

  Write-Host 'Extracting the verified CoA server package...'
  & $tar.Source -xf $Archive -C $stage
  if ($LASTEXITCODE -ne 0) {
    throw 'Windows tar could not extract the zstd archive. The downloaded package remains cached for retry.'
  }

  $managerScripts = @(Get-ChildItem -LiteralPath $stage -Filter manage.py -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Name -eq 'Scripts' })
  if ($managerScripts.Count -ne 1) {
    throw "Expected one CoA Scripts\manage.py after extraction, found $($managerScripts.Count)."
  }

  $repackRoot = $managerScripts[0].Directory.Parent.FullName
  foreach ($needed in @('Runtime\python\python.exe', 'Core\worldserver.exe',
                       'Core\authserver.exe', 'Settings\repack.json', 'mysql\data\mysql')) {
    if (-not (Test-Path (Join-Path $repackRoot $needed))) {
      throw "Official base archive is missing required component: $needed"
    }
  }

  if (Test-Path $Server) { Remove-Item -LiteralPath $Server -Force -Recurse }
  Move-Item -LiteralPath $repackRoot -Destination $Server
  if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Force -Recurse }
  Remove-Item -LiteralPath $Archive -Force
  Write-Host 'Portable server files installed successfully.'
}

function Start-LocalRealm {
  $python = Join-Path $Server 'Runtime\python\python.exe'
  $scriptPath = Join-Path $Server 'Scripts\manage.py'
  Push-Location $Server
  try {
    Write-Host 'Starting local MySQL, authserver and worldserver...'
    & $python -B $scriptPath start-all
    if ($LASTEXITCODE -ne 0) { throw 'Server startup failed. Check Server\Core\Logs for errors.' }

    $loginPath = Join-Path $Root 'LOCAL_LOGIN.txt'
    if (-not (Test-Path $loginPath)) {
      Write-Host 'Creating the local development login...'
      $password = [guid]::NewGuid().ToString('N').Substring(0,16)
      $request = @{ username = 'AFPLAYER'; password = $password; gm = $true } |
        ConvertTo-Json -Compress
      $output = $request | & $python -B $scriptPath create-account-once 2>&1
      if ($LASTEXITCODE -ne 0) {
        Write-Warning ('Automatic account creation failed: ' + ($output | Out-String))
        Write-Warning 'Create an account using the CoA Server Manager account screen.'
      } else {
        @(
          'Azeroth Forever local development account'
          'Username: AFPLAYER'
          ('Password: ' + $password)
          'Realm address: 127.0.0.1'
          'KEEP THIS FILE PRIVATE. This local account has developer permissions.'
        ) | Set-Content -LiteralPath $loginPath -Encoding UTF8
        Write-Host "Your login has been saved locally to: $loginPath"
      }
    }

    Write-Host ''
    Write-Host 'Azeroth Forever server is running on this PC.'
    Write-Host 'Use a compatible Conquest of Azeroth / Ascension game client.'
    Write-Host 'Realmlist: 127.0.0.1'
    Write-Host 'Use Stop_Azeroth_Forever.bat to shut the server down.'
  } finally {
    Pop-Location
  }
}

try {
  if ($Root -notmatch '^[\x00-\x7F]+$') {
    throw "Extract the ZIP to an ASCII-only path such as C:\Games\Azeroth-Forever."
  }
  Ensure-Baseline
  Start-LocalRealm
} catch {
  Write-Host ''
  Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
  exit 1
}
