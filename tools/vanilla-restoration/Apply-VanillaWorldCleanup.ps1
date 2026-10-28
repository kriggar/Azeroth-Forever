# Azeroth Forever targeted world-object cleanup on a local CoA Manager installation.
# Runs against the real Manager MySQL database using the locally created admin-client.ini.
# This script does NOT modify executables, remove quest templates, or touch characters.
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)][string]$ServerRoot,
    [switch]$Apply
)
$ErrorActionPreference = 'Stop'
$ServerRoot = (Resolve-Path -LiteralPath $ServerRoot).Path
$mysql = Join-Path $ServerRoot 'mysql\bin\mysql.exe'
$dump = Join-Path $ServerRoot 'mysql\bin\mysqldump.exe'
$clientSettings = Join-Path $ServerRoot 'mysql\admin-client.ini'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$sqlFiles = @(
    (Join-Path $base '001_remove_call_boards.sql'),
    (Join-Path $base '002_remove_experimental_transporters.sql')
)
foreach ($path in @($mysql, $dump, $clientSettings) + $sqlFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required file is missing: $path"
    }
}
$database = 'acore_world'
$defaults = "--defaults-extra-file=$clientSettings"

# This is the main (CoA) world DB only. Other realms use separate schemas.
# Refuse to modify an unknown realm database.
$names = & $mysql $defaults '--batch' '--skip-column-names' '--execute=SHOW DATABASES LIKE "acore_world";' 2>&1
if ($LASTEXITCODE -ne 0 -or ($names -join '').Trim() -ne $database) {
    throw 'Default CoA world database not found or unavailable. No changes were made.'
}

$report = @'
SELECT "Call Board", g.guid, g.id, t.name
FROM gameobject AS g JOIN gameobject_template AS t ON t.entry=g.id
WHERE g.id IN (402000,402001);
SELECT "Experimental Teleporter", g.guid, g.id, t.name
FROM gameobject AS g JOIN gameobject_template AS t ON t.entry=g.id
WHERE t.ScriptName="go_coa_experimental_teleporter";
'@
Write-Host 'Verified objects present in the local CoA world database:'
& $mysql $defaults "--database=$database" '--batch' '--raw' "--execute=$report"
if ($LASTEXITCODE -ne 0) { throw 'Object audit failed; no changes were made.' }

if (-not $Apply) {
    Write-Host 'REPORT ONLY. No changes made. Add -Apply to back up the world DB and remove those verified spawns.'
    return
}

Write-Warning 'Stop playing and log out of the game before applying. This is not an in-game hot reload.'
$backupDir = Join-Path $ServerRoot 'AzerothForever-DB-Backups'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupFile = Join-Path $backupDir ("world-before-vanilla-" + $timestamp + ".sql")
if (-not $PSCmdlet.ShouldProcess($database, "Backup and remove verified optional object spawns")) {
    return
}
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Write-Host "Backing up world database to $backupFile"
& $dump $defaults '--single-transaction' '--quick' '--routines' '--triggers' '--events' '--databases' $database "--result-file=$backupFile"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $backupFile) -or
    (Get-Item -LiteralPath $backupFile).Length -lt 1024) {
    throw 'World database backup failed or was suspiciously small. NO cleanup SQL was applied.'
}
Write-Host 'Database backup completed.'
foreach ($sqlFile in $sqlFiles) {
    Write-Host "Applying $(Split-Path -Leaf $sqlFile)"
    # Use stdin, which avoids putting SQL or credentials into the command line.
    Get-Content -LiteralPath $sqlFile -Raw | & $mysql $defaults "--database=$database"
    if ($LASTEXITCODE -ne 0) {
        throw "Database cleanup failed: $sqlFile. Restore from $backupFile before continuing."
    }
}
Write-Host 'Verified board and experimental teleporter spawn cleanup applied.'
Write-Host 'Restart the worldserver before checking the world in-game.'
Write-Host "Backup retained: $backupFile"
