# Azeroth Forever — native full client interface (experimental)

**This builds a full WotLK 3.3.5-compatible interface INSIDE THE CLIENT FrameXML load process, not a separate AddOns-folder toolbar.** The third-party reference is the GPL-2.0 [Adrestie/mod-forever-ui](https://github.com/Adrestie/mod-forever-ui), pinned to commit c5149b96a9938ae9073ff8bb1662e42d2b7b5090. Its original license remains in the separately downloaded source.

The port covers action bars, player/target/party frames, cast bars, minimap, chat, quest tracker, bags, game/system menus, achievements, character sheet, talents, spellbook, auction/mail and other windows. It contains over 100 Lua UI modules rather than the previous toolbar-only preview.

**Not yet verified:** exact WoW: Forever (2026) visual parity, correct operation with this specific Ascension/CoA executable, all 21 custom class resources/talents, persistent profiles, in-game character selection, and controller navigation.

## Critical compatibility rules

- This is a full client UI integration, NOT a server-side gameplay change.
- The build deliberately excludes login/character creation GlueXML so the 21 original CoA classes are not replaced.
- The script preserves the live FrameXML.toc from your CoA client archive and appends a native UI load sequence.
- The output installs into Data/patch-Z.MPQ. **If patch-Z already exists**, the tool inventories it, produces a merged copy, verifies every original CoA file, writes a SHA256-checked backup outside Data, and atomically replaces the archive. If full verification is impossible, it fails safely without changing the client. It never patches the executable or server.
- A standard 3.3.5a client verifies its built-in FrameXML integrity and might reject modified UI files. Some customized CoA clients may already support them, but that is NOT established here. The installer does not patch executables or disable signature checking. Signed/unknown MPQs are rejected rather than rewritten.
- Native FrameXML does not have addon SavedVariables. Currently UI positions are in-memory only. Persistent settings need a native client settings bridge.
- This is experimental; keep a full working client backup. The installer can roll back its own verified archive.
- No Blizzard art or game binaries are committed to this repository. Source and art are obtained from the pinned upstream by the installer on your PC.

## Install on Windows — only after CI succeeds

1. Close WoW and back up your complete CoA game-client folder.
2. Download the Azeroth-Forever-Native-UI-Installer-EXPERIMENTAL artifact from the [native UI build](https://github.com/kriggar/Azeroth-Forever/actions/workflows/native-forever-client-ui.yml).
3. Extract the artifact.
4. Run PowerShell in the extracted folder, pointing at your game client (the folder containing Ascension.exe or Wow.exe):

    powershell -NoProfile -ExecutionPolicy Bypass -File ".\Install-NativeForeverUI.ps1" -ClientFolder "D:\path\to\your\client"

5. The installer downloads pinned source, validates the MPQ tool checksum, builds and readback-verifies a client-native archive, and copies it to Data/patch-Z.MPQ. It safely moves aside the old broken toolbar addon if found. If patch-Z already exists it automatically backs it up under AzerothForever-UI-Backups, merges the native UI files into a verified copy, and preserves all original CoA entries. Do not delete patch-Z yourself.
6. If your FrameXML.toc is not in Data/patch-B.MPQ, provide the real MPQ using -FrameXMLArchive "D:\path\to\client\Data\patch-XX.MPQ". The installer refuses to guess.
7. Launch CoA and check class spellbook, talents, resources, unit frames, main action bars, system bar, achievements, and quests.

To generate the patch without touching your game-client folder, add -BuildOnly.

## Undo

Close the client and use:

    powershell -NoProfile -ExecutionPolicy Bypass -File ".\Install-NativeForeverUI.ps1" -ClientFolder "D:\path\to\your\client" -Restore

Restore verifies the installed archive SHA256. When an original patch-Z existed, it restores the original from its SHA-verified backup; when none existed, it removes only the new patch. The previous preview addon is also restored if the installer had moved it. It does not modify the installed CoA server, player database or exe.

## How this works

- build_native_patch.py reads the original effective FrameXML.toc from the installed client.
- Each UI Lua script from the upstream port is embedded under Interface/FrameXML/AzerothForeverNative and loaded in the original order; artwork is embedded under Interface/foreverui.
- The native begin/end bridges initialize upstream UI listeners without registering another addon.
- mpqcli produces a fresh WotLK MPQ and extracts it to verify the full member inventory.
- No Interface/AddOns/ForeverUI or GlueXML files are included in the output.
- The workflow validates the builder and Lua syntax, plus MPQ construction on a representative test FrameXML.toc. A real CoA in-game integration test is still required.

## Remaining mandatory integration tasks

Validate modified FrameXML integrity behavior in the specific CoA client, update any 3.3.5 custom-class HUD conflicts, preserve all 21 CoA classes and their custom resources, add settings persistence and exact Forever 2026 look, and finish in-game UI regression testing.

## CoA talents are NOT stock WotLK talents

Azeroth Forever preserves **all 21 Conquest of Azeroth classes**. Their player-facing talent window is `CoATalentFrame`, with **two authentic trees** (Class and Specialization), connected to the existing `C_CharacterAdvancement` client API, pending-build budget, required nodes, respec, specialized class node visuals and Save/Undo. It is not `PlayerTalentFrame` or stock `GetTalentInfo`.

The native packaging step explicitly **does not execute** the upstream port's `Talents.lua`, `TalentsSearch.lua` or `TalentsData.lua`: those are WotLK three-tab controllers and can otherwise generate a duplicate/incorrect panel. Our native `AzerothForeverCoATalents.lua` adds modern Forever-styled background, borders, header dividers, smaller legible text and scales the *existing* CoA talent window to screen. The original CoA node buttons and all their scripts, search box, Save Changes, Undo and specialization selection are preserved in place.

CoA talents remain **client-load-on-demand** through the owner's existing `Ascension_CoATalents` package; this is a dependency of the provided CoA client, **not a new add-on to install**. The presentation changes ship inside the game-client MPQ as FrameXML.

The appearance is still **in-game unverified** until the patched client is launched and class/spec trees are opened. The required goal is parity with WoW: Forever's modern talent-panel appearance while retaining the CoA talent function. Do not claim this is finished just because the native Lua and MPQ tests pass.

The full mandatory client panel list, with per-panel implementation status, is maintained at `tools/forever-native-ui/ui_contract.json`. Unimplemented gamepad/Legacy/Camping/new renderer functionality is tracked explicitly instead of falsely presenting the old client as a 2026 game client.

## Approved first-screen talent layout (replaces rejected spec-card drafts)

Opening Talents on any of the 21 CoA classes must show its **real connected Class and Specialization talent trees immediately**. The old CoA four-card screen and the rejected new black sidebar/card screen have both been removed from the native package. The reference aesthetic is the user's approved WoW: Forever screenshot: framed atmospheric background, dense connected node branches, rank counts on each original CoA node, an unobtrusive specialization selector, and unobstructed bottom Save/Undo controls.

The CoA client supplies **two** talent trees rather than the classic three (Class plus the selected Specialization). We do not invent a third tree or replace a CoA talent with stock Arms/Fury/Protection talent data. The modern look adapts the official reference to those two original CoA trees.

`AzerothForeverCoATreeHome.lua` makes the native CoATalentFrame.TreeView the default first page; `AzerothForeverCoATalents.lua` styles the original tree backgrounds/headers and retains original point counts. Buttons use the existing CoASpecChoiceMixin.OnSelected handler and server-side C_CharacterAdvancement validation. All changes are inside the native client MPQ, not an additional addon. There is no fake talent tree data.

The trial-specific micro/menu-button cleanup and a consolidated Escape > Options/Edit Mode panel are in `AzerothForeverNativeGameMenu.lua`. Only identified Ascension-only trial controls are suppressed; the original client secure Logout/Quit/Return handlers remain. The exact Ascension trial icon in the user's client still needs in-game verification; keep that item marked pending rather than assume its runtime name.

**Release gate:** unit/Lua syntax, MPQ file verification and Windows upgrade/restore tests do not establish visual parity. The user's live screenshots are the final acceptance test for (1) direct first-screen CoA tree, (2) recognizable Forever styling, (3) removal of specific Trial icon, (4) no duplicate/broken UI controls, and (5) every CoA node/Save handler functional.
