# Azeroth Forever — compact WoW Forever-style Esc menu (native client patch)

**Release focus: game menu, UI scaling, alignment and Trial controls.** Talent-window changes are out of scope and **not loaded** by this build. All 21 original Conquest of Azeroth classes and their abilities remain part of the existing client/server.

This source package extends the user-uploaded **Azeroth-Forever-Native-UI-Installer-EXPERIMENTAL** workflow. The patch is installed into `Data/patch-Z.MPQ` via the existing CoA client `Interface/FrameXML/FrameXML.toc`, **not through a player-installed AddOns folder**. It downloads the pinned GPL-2.0 [Adrestie/mod-forever-ui](https://github.com/Adrestie/mod-forever-ui) source and art when built on Windows. Its third-party license must be preserved.

## What changed

- **Single Game Menu owner:** the original upstream `GameMenu.lua` is deliberately excluded from the load list. The new `AzerothForeverNativeGameMenu.lua` reuses the same ForeverUI frame and three-slice red button resources. It centers a uniform 200×33 button column inside a 256 px game-menu panel, without the previous duplicate layout hooks.
- **Functional Esc workflow:** Options (client-native settings), Edit Mode (ForeverUI Customize UI), and where native click handlers exist: Macros, AddOns, Support; then Log Out, Exit Game and Return to Game. No fake shop or unsupported system control. Original secure Logout/Quit/Continue scripts remain unchanged.
- **No Trials:** removes explicitly named Ascension Trial UI controls, Trial labels in the game menu, and extra custom micro-menu items without touching action bars or progression.
- **Smaller interface:** old 82% or full-size 100% UI is changed to **76%** on login. Existing smaller manual scales remain intact; if you prefer full size, choose it again after login. In-game `/afui scale 0.76` can be used to select 76% immediately; the Settings > Interface slider goes 64%–100%.
- **Alignment:** consistent Esc menu rows, centered panel, compact native micro-menu reflow, and overlap-based spellbook/bag search cleanup. The previous cleanup no longer suppresses a separate search field merely because it contains “search,” and it does not touch the CoA talent search.
- **No change to character creation, talent window, server, executable, game accounts or database.** Login/GlueXML is excluded.

## Installation — test on a separate client copy

1. Extract the ZIP outside the game-client folder.
2. Close World of Warcraft and make a complete copy of the playable CoA client.
3. Run **`BUILD-ONLY-Native-UI.bat`**, point it at the test client copy, and inspect the verified candidate report. This step **does not install**.
4. If that succeeds, run **`INSTALL-Native-UI.bat`**, select the same **test copy**, and allow the installer to place the new verified patch in `Data/patch-Z.MPQ`.
5. Launch the test client, log in, press **Esc** and check the Game Menu. Test Options, Edit Mode, Log Out/Exit/Return, macro and AddOns buttons (if offered), minimap/microbar placement, and `/afui scale 0.76`.
6. Inspect any UI errors with `/console scriptErrors 1`, `/afui errors` and `/afui audit`. Do **not** replace the only playable client until it passes.

On a Windows machine with PowerShell and Python installed, the equivalent non-installing command is:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-NativeForeverUI.ps1 -ClientFolder "D:\path\to\test-client" -BuildOnly
```

For a client already patched by an earlier native installer, the script verifies the existing manifest and patch hash, locates the original SHA256-verified CoA `patch-Z.MPQ` backup, **builds from the original instead of recursively merging old UI scripts**, then atomically swaps the archive. If the manifest or backup is missing/modified, it refuses the upgrade.

### Restore

Close the game and run **`Restore-Native-UI.bat`** on the test client copy, or:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-NativeForeverUI.ps1 -ClientFolder "D:\path\to\test-client" -Restore
```

The original patch is SHA256-checked before restore. An empty-baseline install can remove its newly added patch. No source MPQ, client executable or server database is directly modified.

## Evidence and limits

**Verified locally:** 13 Python source/staging tests, 3 Lua 5.4 mocked runtime tests, and syntax parsing of 10 bundled Lua scripts. Tested conditions include aligned button geometry, preserve secure native click handlers, remove Trial UI, skip upstream competing GameMenu controller, preserve CoA original talent window, 76% scale migration, keep smaller custom scales, and hide overlapping searches only when actual geometry overlaps.

**Not yet verified:** building a real MPQ with the third-party `mpqcli` binary, running the Windows Ascension.exe client, checking actual Esc-menu screenshots pixel-by-pixel, or online server play. These steps require a Windows/client environment and successful external build tools. Passing mock tests does not prove perfect WoW Forever visual parity.

Sources for reference behavior: [WoW Forever Edit Mode](https://www.wowhead.com/forever/guide/ui/ui-hud-edit-mode-guide), [WoW Game Menu description](https://warcraft.wiki.gg/wiki/Game_menu). The GPL-2.0 port is a third-party interface reconstruction, not Blizzard's official Forever client.
