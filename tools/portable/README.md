# Azeroth Forever — portable local server bootstrap (Windows)

This folder is the source for the **Azeroth-Forever-Portable-Server-Installer.zip** GitHub Actions artifact.

## User experience

1. Download the ZIP from the [Portable Server ZIP workflow](https://github.com/kriggar/Azeroth-Forever/actions/workflows/portable-server-zip.yml).
2. Extract to an ASCII-only Windows path, e.g. `C:\Games\Azeroth-Forever`.
3. Double-click `Start_Azeroth_Forever.bat`.

On first launch the script downloads **the original published CoA Server Manager base server archive** over HTTPS from its publisher, verifies its pinned SHA-256, extracts it into the local `Server` folder, and uses the packaged server launcher to start MySQL, authserver and worldserver. It attempts to create a private local development login and writes it to `LOCAL_LOGIN.txt`. Subsequent launches reuse the installed server without downloading it again. Stop with `Stop_Azeroth_Forever.bat`.

**Important:** This initial ZIP is a **one-click download-and-install bootstrapper**, not a self-contained 10 GB server archive. It does **not** contain World of Warcraft/CoA client assets, DBCs, map files or any proprietary game data. The publisher-hosted base archive supplies the needed server-side data; you must already have a compatible legally acquired CoA/Ascension client. The first launch needs internet and free disk space.

### What this does not establish

- The exact official base server has not yet been end-to-end tested in this new Azeroth Forever installer. The ZIP's packaging checks are not a substitute for a Windows startup/gameplay test.
- The original base package is a **baseline**, not the full current CoA Server Manager updated build, and it does not include Azeroth Forever gameplay changes.
- Later changes to our C++ source must be **compiled into new server executables** and safely applied. Editing GitHub code does not patch a running server automatically.
- Official CoA Server Manager also manages cumulative signed updates and data migrations. Do not overlay these blindly or point the Manager's automatic updater at an experimental custom server directory.
- The client may need its realmlist set to `127.0.0.1` to join the local realm. The script does not modify unrelated client folders.

If the packaged baseline proves incompatible with the installed client, use the original [CoA Server Manager](https://github.com/Corfirean/coa-server-manager/releases/latest) to install/update a compatible local server before introducing custom binaries.

## Safety, trust and reproducibility

- Original archive: `https://github.com/Corfirean/coa-server-build/releases/download/base/base.tar.zst.001`
- Expected SHA-256: `2da8ddcffde326f49e1ce73c9fc1df1ed1d8017cc281977d607bce90ba0b5936`
- The script refuses an archive with any other digest.
- Scripts never publish local accounts, passwords, databases or personal game files to GitHub.
- The bootstrap is designed for **localhost only**, not an internet-facing server. Do not expose the development realm directly.
- Server base and extractions live locally under `Server` and are excluded from version control and the build artifact.
- `LOCAL_LOGIN.txt` contains your local development account and must remain private.

## Source attribution

Azeroth Forever server source: [kriggar/Azeroth-Forever](https://github.com/kriggar/Azeroth-Forever).

Original server pack and management tools: [Corfirean/coa-server-build](https://github.com/Corfirean/coa-server-build) and [Corfirean/coa-server-manager](https://github.com/Corfirean/coa-server-manager). The official publisher says client-extracted game data are not covered by its source-code license; accordingly these are not copied into this ZIP.
