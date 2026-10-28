# Windows local hosting — Azeroth Forever (CoA Server Manager)

This setup installs the **publisher's original CoA server base**, not yet the customized Azeroth Forever build. The custom vanilla-CoA source branch requires a separate compile and database migration.

## 1. Download
Visit https://github.com/kriggar/Azeroth-Forever/actions/workflows/coa-manager-offline-server.yml

Choose a **successful** run with the published `Azeroth-Forever-Official-CoA-Server-Offline` artifact. If no successful run/artifact exists, do not claim the installer is ready; inspect the workflow error and rerun after fixing. Artifacts currently have one-day retention. GitHub may require sign-in to download.

The workflow compiles the real publisher Manager core installer, includes the publisher's original signed base archive, installs it on Windows during CI, tests MySQL/authserver/worldserver ports and creates an account. A green build does NOT establish that your WoW client successfully logged in.

## 2. Install on your Windows PC
- Use a separate empty directory (e.g. `C:\Azeroth-Forever`) with an ASCII-only path. Avoid OneDrive/Google Drive sync directories.
- Extract the **entire** artifact ZIP, not the repository Code ZIP.
- Confirm `Start-Server.bat`, `Stop-Server.bat`, `CoA-Manager-Install.exe`, and `Official-Server-Package\manifest.json.sig` exist.
- Double-click `Start-Server.bat`; let its genuine Manager install engine initialize MySQL, authserver and worldserver. Do not independently install a conflicting MySQL service.
- If successful, the installer places the installed services in `CoA Server\`, including `Settings\database.json` and `Core\worldserver.exe`.
- Keep `LOCAL_LOGIN.txt` private; it includes the test account username/password. The launcher generates the account only if that file is absent.
- Stop using `Stop-Server.bat`.

## 3. Check services
From PowerShell, while the server runs:

```powershell
$root = 'C:\Azeroth-Forever'
Test-Path (Join-Path $root 'CoA Server\Settings\database.json')
Get-Content (Join-Path $root 'CoA Server\Settings\repack.json') | ConvertFrom-Json | Select-Object mysqlPort,authPort,worldPort
Test-NetConnection 127.0.0.1 -Port 3724
Test-NetConnection 127.0.0.1 -Port 8085
```

The common auth/world port defaults are shown above; if the installed `repack.json` reports other ports, test those instead. Never publish `Settings\database.json` or local credentials. Server errors may be available under `CoA Server\Core\Logs`.

## 4. Log in locally
Use a legally acquired, **compatible CoA game client**. In its relevant `realmlist.wtf` (location depends on client build), point to:

```text
set realmlist 127.0.0.1
```

Make sure the authentication database realm address corresponds to localhost and the actual worldserver port. If you can authenticate but the realm list is empty/offline, inspect the auth database's `realmlist` table and server logs; take a database backup before changing records. A plain unmodified WoW client may not support custom CoA classes/maps.

## 5. Network access for a friend (later)
Start with localhost first. For private access, use Tailscale on both PCs and point the client and advertised realm address to the host's Tailscale IPv4 address. Configure Windows Defender Firewall to allow the server's authentication and world TCP ports **only** on the intended private network/interface. Don't expose MySQL to the Internet, and don't port-forward the database port.

## 6. Troubleshooting
- Missing `Settings\database.json`: initialization failed. Do **not** use the deprecated portable bootstrapper, and do not fabricate a DB config file.
- No workflow artifact: verify that the CI startup and account-creation tests passed, and rerun if the one-day artifact expired.
- Ports closed: check launcher output, core logs, and Windows Firewall; don't assume startup succeeded from a script printing its initial message.
- Client fails after realm selection: check realm address, configured world port, version compatibility, database consistency, and CoA-specific client patches.
- Never overwrite an existing populated `CoA Server` folder with a new baseline archive. Back up databases and credentials first.

## Current limits
The repository's `feature/vanilla-coa-baseline` changes only provide a build-time module filter and a restoration roadmap. No claim of successful vanilla gameplay, custom installer integration, or player login testing is made here.
