# Azeroth Forever — World of Warcraft: Forever reference specification

**Reference is Blizzard's World of Warcraft: Forever (2026), NOT original WoW 1.12 or WoW Classic Era.**
This is a compatibility-conscious independent CoA server and client-side modding effort.
**The existing publisher server package installed on Windows is NOT rebuilt by a GitHub source commit.**

## Non-negotiable project rules
- Preserve all **21 original Conquest of Azeroth classes and their specializations**, abilities, talents, appropriate character UI, and class-specific resource systems.
- Preserve custom class trainers, class/profession trainer availability, custom maps, and playable quests (including existing custom quests).
- Preserve the original Azeroth social/travel/group gameplay. Restore standard, quest-oriented exploration rather than custom mall-hub activities.
- Remove or disable unrelated Ascension enhancements, high-risk PvP, forced war-mode choices, capital/town resurrection shortcuts, Hero Boards, custom lottery/prestige/loot systems, and extraneous transporters. Don't destroy map/quest portals or quests needed to play the retained content.
- Replace the client HUD and native windows toward the **modern WoW: Forever interface**: action bars, unit frames, cast bars, target frames, minimap, quest tracker, menus, character sheet, inventory, professions, talent pane, achievements, Legacy pane, settings, and **system/micro-menu bar**.
- Use native WoW achievements as the basis. WoW: Forever **Legacy Challenges** are a separate progress system, not a relabeling of achievements.

## Verified Forever product references (official Blizzard)
- https://worldofwarcraft.blizzard.com/en-us/forever/
- https://worldofwarcraft.blizzard.com/en-us/news/24303313 (2026-09-13 deep dive)
- https://worldofwarcraft.blizzard.com/en-us/news/24303862 (2026-09-12 overview)
- https://worldofwarcraft.blizzard.com/en-gb/news/24307383/get-to-know-the-world-of-warcraft-forever-legacy-system (2026-09-23)
- https://worldofwarcraft.blizzard.com/en-us/news/24302070 (rulesets)

## Official-system acceptance matrix

| Feature | Forever target | Status in *this repository branch* |
|---|---|---|
| CoA classes + specializations | All 21 untouched, full spell/talent/class resource support | Source preserved; not exhaustively tested |
| CoA trainers/maps/quests | Preserve all existing quest/map/class additions | Source preserved; rehoming removed board quests remains unresolved |
| Optional Ascension modules | Only explicitly audited required exceptions | **Changed:** default strict CMake allowlist (none) |
| High-risk / loot-drop PvP | No Ascension High Risk | **Changed:** registration suppressed; existing character aura cleanup on login; not built |
| PvP flagging / corpse | Standard core, no capital-city resurrection shortcuts | **Changed:** custom handlers suppressed + utility spell removal; requires tests |
| Hero Boards | Remove from Stormwind and Orgrimmar | **Prepared:** backup-first SQL for confirmed spawns, not automatically deployed |
| Custom experimental transporters | Remove nonquest spawns | **Prepared:** scripted object deletion, not automatically deployed |
| Native achievements | Standard WoW achievement evaluation + Realm First | **Changed:** seasonal game-mode criteria disabled, actual DB/achievement IDs still need audit |
| Forever-like system bar | Compact modern HUD menu with functional buttons | **Added:** Lua 3.3.5 client addon MVP; not tested on user's CoA build |
| Full pixel-matched Forever interface | All native and system panels, class-compatible | **Not complete:** legacy CoA client cannot execute the modern Forever UI APIs directly |
| Classic-paced 1–60 combat | Level cap 60, 10–15 sec ordinary kills; no world level scaling, no flying | **Not implemented/verified** |
| Rule sets | Normal, PvP, RP; Hardcore when compatible | **Not implemented:** local single-realm supports only its currently configured gameplay mode |
| Legacy System | Challenges, account-wide points, per-character spending and rewards | **Not implemented:** requires DB migrations + server logic + client UI |
| Camping & Professions | Campfires, profession structures, new recipes, food bonuses | **Not implemented** |
| Transmog | Opt-in cosmetic appearance only | **Not implemented/verified** |
| Item stats | New Forever itemization / hybrid stats and class balance | **Not implemented/verified** |
| Gamepad | Official-like controller navigation and bindings | **Not implemented** |
| HD/SD models & modern environmental rendering | User-selectable Forever visuals | **Unavailable in current 3.3.5 client without engine/assets work** |
| Realmless infrastructure | Cross-character-name rulesets and player ecosystems | **Not implemented:** requires major networking/back-end redesign |
| New Forever quests/zones/races | Source-inspired compatible content for the CoA client | **Not implemented:** Forever content cannot simply be copied into older client |

These are requirements, not completion claims. Sources describe the announced/beta Forever behavior as of 2026-10-28. It launches on 2026-11-04; details may change.

## Files changed/added
- `modules/CMakeLists.txt`: default-off module allowlist, with audited exceptions explicitly opt-in.
- `src/server/coa/CoAScriptLoader.cpp`: disable known nonclass gameplay registrations in vanilla mode; retain class and quest handlers.
- `src/server/coa/AzerothForeverVanillaCleanup.cpp`: clear obsolete HighRisk/WarMode/mercenary/PvE auras and custom resurrection spells from existing logins, without touching CoA class spells.
- `src/server/coa/AscensionAchievementConditions.cpp`: disable Ascension-only seasonal achievement criteria, retain Realm First handling.
- `tools/vanilla-restoration/001_remove_call_boards.sql`, `002_remove_experimental_transporters.sql`, `Apply-VanillaWorldCleanup.ps1`: identified world-spawn cleanup with a mandatory database backup.
- `tools/forever-ui/AzerothForeverUI/*`: initial functional dark system bar, including native achievement button; avoids overwriting the class HUD.
- `tools/forever-ui/Install-ForeverUI.ps1`: reversible addon installation to a compatible local client.

## How to try the client UI now
The addon is **independent of server recompilation**:
1. Get this branch of the repository (Code -> Download ZIP -> branch `feature/vanilla-coa-baseline`).
2. Extract it locally. Close the game client.
3. From PowerShell, execute:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\forever-ui\Install-ForeverUI.ps1 -ClientFolder "D:\path\to\your\client"`
4. At the WoW client AddOns panel enable the addon (allow out-of-date if the custom client asks). Login.
5. `/afui on` uses the new system bar; `/afui off` restores the native micro-buttons; `/afui achievements` opens Blizzard's native achievement panel.

This is a first functional UI layer and **not pixel-identical to modern WoW: Forever**. It does not copy Blizzard's proprietary 2026 UI code or assets.

## How to inspect and apply known world-object cleanup
1. Log all player characters out; do not run simultaneous database migrations.
2. Keep the local CoA Manager MySQL service accessible. Use the server root shown in your successful install message:
   `C:\Azeroth-Forever\Azeroth-Forever-Official-CoA-Server-Offline\CoA Server`
3. From the extracted source branch, run the audit first:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\vanilla-restoration\Apply-VanillaWorldCleanup.ps1 -ServerRoot "C:\Azeroth-Forever\Azeroth-Forever-Official-CoA-Server-Offline\CoA Server"`
4. To remove the confirmed board/experimental teleporter spawns with a backup:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\vanilla-restoration\Apply-VanillaWorldCleanup.ps1 -ServerRoot "C:\Azeroth-Forever\Azeroth-Forever-Official-CoA-Server-Offline\CoA Server" -Apply`
5. Restart the worldserver after cleanup. Do not remove the backup directory.

This SQL deliberately does **not** automatically remove unidentified NPCs or random custom objects, as many can be mandatory class trainers or quest starters. A true full DB cleanup requires comparing live CoA world rows against a vetted vanilla baseline and a dependency map.

## Build/deployment gate
These commits are not reflected in a server previously installed from the official CoA Manager ZIP. The new C++ sources must pass a clean compilation, database migration, class trainer/quest regression testing, and real client login testing. Do not overwrite the existing working CoA Server or existing character database with a partially tested executable.

**Bottom line:** The entire Forever reference is the project target, but only the specific source changes and addon above are implemented so far. A complete functional Forever recreation is not yet delivered.
