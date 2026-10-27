$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Package = Join-Path $Root 'Official-Server-Package'
$Server = Join-Path $Root 'CoA Server'
$Installer = Join-Path $Root 'CoA-Manager-Install.exe'

function Fail($message) {
  Write-Host "ERROR: $message" -ForegroundColor Red
  exit 1
}

if (-not [string]::IsNullOrEmpty(($Root -replace '[\x00-\x7F]', ''))) {
  Fail "Extract into an English-letter path, for example D:\Azeroth-Forever."
}

if (-not (Test-Path (Join-Path $Server 'Runtime\python\python.exe'))) {
  if (-not (Test-Path $Installer)) { Fail 'CoA Server Manager installer executable is missing.' }
  if (-not (Test-Path (Join-Path $Package 'manifest.json.sig'))) { Fail 'Official signed base package is missing.' }
  if (Test-Path $Server) {
    $items = @(Get-ChildItem -LiteralPath $Server -Force -ErrorAction SilentlyContinue)
    if ($items.Count -gt 0) { Fail "Incomplete existing server folder found; not overwriting it: $Server" }
  }
  Write-Host 'Installing the ORIGINAL CoA Server Manager distribution (offline from the files in this ZIP).'
  & $Installer $Package $Server
  if ($LASTEXITCODE -ne 0) { Fail 'CoA Server Manager install failed; see the error above.' }
}

$Python = Join-Path $Server 'Runtime\python\python.exe'
$Manage = Join-Path $Server 'Scripts\manage.py'
if (-not (Test-Path (Join-Path $Server 'Settings\database.json'))) {
  Fail 'The server database was not initialized correctly.'
}
if (-not (Test-Path $Manage)) { Fail 'Missing official CoA Server Manager launch script.' }

Push-Location $Server
try {
  Write-Host 'Starting bundled MySQL, authentication server, and world server...'
  & $Python -B $Manage start-all
  if ($LASTEXITCODE -ne 0) { Fail 'CoA server could not start; inspect CoA Server\Core\Logs.' }

  $LoginFile = Join-Path $Root 'LOCAL_LOGIN.txt'
  if (-not (Test-Path $LoginFile)) {
    $pass = [guid]::NewGuid().ToString('N').Substring(0, 16)
    $request = @{ username = 'AFTESTER'; password = $pass; gm = $true } | ConvertTo-Json -Compress
    $output = $request | & $Python -B $Manage create-account-once 2>&1
    if ($LASTEXITCODE -eq 0) {
      @(
        'Azeroth Forever — private local test account'
        'Username: AFTESTER'
        "Password: $pass"
        'Realm: 127.0.0.1'
        'Developer/GM account. Keep this file private.'
      ) | Set-Content -Path $LoginFile -Encoding UTF8
    } else {
      Write-Warning 'Automatic account creation failed. Use the CoA Server Manager account screen.'
      Write-Warning ($output | Out-String)
    }
  }
  Write-Host 'The local server startup completed.'
  Write-Host 'Realm address: 127.0.0.1'
  Write-Host 'To connect, use the separate compatible Conquest of Azeroth client.'
  Write-Host 'To stop the server, run Stop-Server.bat.'
} finally {
  Pop-Location
}
