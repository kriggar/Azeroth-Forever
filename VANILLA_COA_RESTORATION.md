# Vanilla CoA restoration — implementation checklist

## Intended experience
Keep all 21 Conquest of Azeroth classes and their specializations, required class trainers, original WoW content, and custom maps. Everything else should use standard WoW behavior where feasible. The underlying core is AzerothCore/WotLK, so a genuine vanilla 1.12 world is **not** achieved by just turning off modules.

## Phase 1 — optional module build filtering
`-DAZEROTH_FOREVER_VANILLA=ON` is the default CMake option in `modules/CMakeLists.txt`. It removes named optional gameplay modules from the discovery list; CoA itself is built from `src/server/coa`. Review each excluded module for class/trainer/map dependencies before merging.

## Phase 2 — server scripts and configuration (not yet implemented)
- Find and disable high-risk PvP enrollment, penalties, loot-loss, forced flags, and resurrection hooks.
- Restore default corpse release, graveyard selection, corpse recovery, and spirit-healer behavior; prevent automatic capital-city resurrection.
- Audit all optional systems not implemented as modules, including code in `src/server/coa` and custom world scripts.
- Set ordinary XP, loot, mob damage, movement and travel pacing as appropriate for the intended Classic-style progression.
- Do not disable essential class trainers, class spells, class quests, custom maps or zone transition requirements.

## Phase 3 — world database migration (not yet implemented)
Build an idempotent migration against the *actual installed CoA database*, not guessed IDs. Record the full existing rows in a backup before deleting custom `gameobject`, `creature`, `areatrigger_teleport`, `spell_target_position`, graveyard-link, or other spawn records. Remove only verified nonessential transporters, event boards, custom vendors, PvP objects, and teleporters. Retain gameplay-critical portal objects used by allowed maps. Restore standard graveyard links and flight masters.

## Phase 4 — client patch cleanup (not yet implemented)
Inspect shipped client MPQ patches / addons and verify which changes are needed for CoA class definitions, maps, trainers, spell UI or custom assets. Remove only patches solely responsible for unwanted custom UI or world objects. Client patch cleanup cannot be inferred from server source alone.

## Phase 5 — validation
1. Clean CMake configure; verify module graph lacks the named optional modules and core CoA classes are still linked.
2. Compile, install, initialize **fresh** local DB, start authserver/worldserver.
3. Create one character for each of the 21 CoA classes; verify login, spells, talents and trainers.
4. Check ordinary death and resurrection in multiple zones: ghost at corpse, nearby spirit healer, not capital-city respawn.
5. Test PvP flagging with no high-risk features.
6. Inspect Stormwind, Orgrimmar, starter areas, and custom maps for unwanted transporters/objects.
7. Test normal quests, loot, flight paths, dungeon entrances, battleground access and dungeon graveyards.
8. Verify old realm databases are never modified without backups.
9. Run actual Windows CoA Manager end-to-end installation tests; source build alone is not a playable release.

## Scope warning
The build-time filter is a **first step**, not a completed vanilla conversion. No database cleanup, executable test or live-game verification is claimed by this commit.
