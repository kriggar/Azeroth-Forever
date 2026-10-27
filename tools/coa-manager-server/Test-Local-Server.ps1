param(
  [Parameter(Mandatory=$true)][string]$ServerRoot,
  [switch]$StopWhenDone
)
$ErrorActionPreference = 'Stop'
$ServerRoot = (Resolve-Path -LiteralPath $ServerRoot).Path
$Python = Join-Path $ServerRoot 'Runtime\python\python.exe'
$Manager = Join-Path $ServerRoot 'Scripts\manage.py'
$Settings = Join-Path $ServerRoot 'Settings\repack.json'

foreach ($required in @($Python, $Manager, $Settings, (Join-Path $ServerRoot 'Settings\database.json'),
                          (Join-Path $ServerRoot 'Core\worldserver.exe'), (Join-Path $ServerRoot 'Core\authserver.exe'))) {
  if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
    throw "Missing required installed server file: $required"
  }
}

$serverConfiguration = Get-Content -LiteralPath $Settings -Raw | ConvertFrom-Json
$started = $false

function Assert-ServerPort([string]$name, [int]$port) {
  $client = New-Object System.Net.Sockets.TcpClient
  try {
    $attempt = $client.BeginConnect('127.0.0.1', $port, $null, $null)
    if (-not $attempt.AsyncWaitHandle.WaitOne(15000)) {
      throw "$name TCP port $port did not respond within 15 seconds"
    }
    $client.EndConnect($attempt)
    Write-Host "PASS: $name responds at 127.0.0.1:$port"
  } finally {
    $client.Dispose()
  }
}

Push-Location $ServerRoot
try {
  Write-Host 'Checking CoA server startup using the official CoA Server Manager launcher...'
  & $Python -B $Manager start-all
  if ($LASTEXITCODE -ne 0) { throw 'Official CoA Server Manager start-all failed' }
  $started = $true

  Assert-ServerPort 'MySQL' ([int]$serverConfiguration.mysqlPort)
  Assert-ServerPort 'authentication' ([int]$serverConfiguration.authPort)
  Assert-ServerPort 'game world' ([int]$serverConfiguration.worldPort)

  Write-Host 'Creating a test WoW account through the running worldserver...'
  $password = [guid]::NewGuid().ToString('N').Substring(0,16)
  $account = @{
    username = 'AFTESTACCOUNT'
    password = $password
    gm = $true
  } | ConvertTo-Json -Compress
  $accountResult = $account | & $Python -B $Manager create-account-once 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "Live server account creation failed (exit code $LASTEXITCODE): $($accountResult | Out-String)"
  }
  Write-Host 'PASS: worldserver accepted new account creation.'
  Write-Host 'PASS: local authserver and worldserver ports are accepting connections.'
  Write-Host 'This verifies a login-ready realm but not in-game visual/character compatibility with a client.'
} finally {
  if ($StopWhenDone) {
    Write-Host 'Stopping the disposable test server...'
    & $Python -B $Manager stop-all
    if ($LASTEXITCODE -ne 0) {
      Write-Warning 'The test server stop script exited nonzero.'
    }
  }
  Pop-Location
}
