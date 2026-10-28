# Azeroth Forever — Vanilla Azeroth + CoA classes

This is the first development pass toward the requested ruleset: **vanilla-style
Azeroth at levels 1–60**, with **all Conquest of Azeroth classes and their
specializations, class trainers, class-quest interactables and custom-map data**.
This is **not** a conversion into the Warcraft Reborn class system, and it is
not meant to remove the CoA Ascension-client protocol.

## Kept

- `CoA.Enable = 1`, `CoA.ClassModel = "coa"`, `CoA.CharacterSelectionEnable = 1`,
  and `CoA.SendDisplayPatches = 1`: retain client protocol and CoA classes.
- All CoA class combat scripts, talents, spells and specialized trainer NPCs.
- All CoA trainer migrations, including those for Northshire, Coldridge,
  Valley of Trials, Deathknell, Camp Narache, Shadowglen, Ammen Vale and Sunstrider,
  plus city trainers and required class-quest objects.
- Custom map assets and 3D map navigation data. **Expansion = 2** remains until
  custom maps and starting areas are audited for expansion dependencies.
  **MaxPlayerLevel = 60** defines the vanilla leveling cap.
- Ordinary WoW PvP rules, battlegrounds, flight masters, inns, hearthstones,
  graveyard corpse runs, native resurrection, loot and professions.
- Normal 1x XP from kills, quests and exploration, 2x classic elite XP, and **no
  character XP from mining, herbalism or crafting**. Custom CoA progression rates
  are deliberately not used in the vanilla world.

## Disabled at the compiled-server level

- Ascension **High-Risk** and **War Mode** selection. Their alternate PvP auras
  and spell selections are stripped on existing-player login; a PvE ruleset aura
  may still be retained for Ascension client compatibility.
  World PvP flagging remains owned by the standard WoW core.
- Resurrect in Closest Town / Capital City spells (IDs 84423 and 84433).
  Both are rejected when cast and removed on character login.
- Dynamic open-world **Void Portal** event and its reward; the
  **First-Class Experimental Teleporter** is nonfunctional.
- 34 extra script registrations: non-vanilla reward caches, upgrade kits,
  bonuses, account conveniences, personal bank, portal scripts, wilderness
  extras, custom arena queue and certain time-saving systems.
  CoA class, trainer and world compatibility scripts remain active.
- `-DMODULES=disabled` in the Windows build prevents the optional
  non-core modules from being compiled into the vanilla realm. CoA itself is
  implemented in `src/server/coa`, not `modules/mod-ascension` (historical SQL).
- Non-vanilla scaling, world health/damage multipliers, quest/item auto
  scaling, PvE/PvP power, high-risk loot, bonus riding ranks, appearance
  unlocks, auto-collections and equipment upgrade convenience are off.

## Database cleanup — use the new migration (world database only)

`data/sql/updates/pending_db_world/rev_20261028_00_azeroth_forever_vanilla_remove_shortcut_spawns.sql`

It removes *targeted* optional spawns: experimental teleporters, Void Portal
event markers and spawn groups, Worldforged ground-item pickups (about 2,469
placements in the original module), two Call Board object IDs, and the
specific generated forestry object range. This is deliberately a spawn cleanup:
**it does not erase item templates, player characters, world maps, custom
class trainers, or the Class Quest GO IDs.** Historical high-risk loot escrow
is preserved.

Class trainer migration SQL and existing applied migration hashes are not
rewritten. New cleanup is a fresh forward migration, not an edited old migration.

## How to verify

```sh
python3 tools/vanilla/verify.py
```

CI runs this inexpensive source/regression check and the separate Windows
native source compiler. Only a successful native compile and a fresh Windows
test of the new server + database migration constitute a playable custom
build. The official CoA Server Manager `base` ZIP from earlier in the repo
still contains the **original upstream server**, not these modifications.

## Applying to an existing personal server

**Never overwrite the working CoA Server folder or live database directly.**
Back up your characters, all world/auth/character DBs, server configs and the
compatible client first. Use a fresh or disposable local installation:

1. Build the modified Windows `worldserver.exe` and `authserver.exe` from
   this feature branch. **Do not mix incompatible DLL/module configurations.**
2. Start from a clean copy of the correctly installed CoA Server Manager
   server. Keep its bundled MySQL runtime, client-derived data and per-machine
   credentials, none of which belong in public source control.
3. Install the newly compiled executables in that *test copy*, activate the
   vanilla `coa.conf` values and the level-60 worldserver config, and apply
   the new world database migration through the same managed SQL updater.
4. Verify MySQL/authserver/worldserver startup, an account, character creation
   for multiple CoA classes, their trainers, class spells, death at a graveyard,
   baseline transport, custom maps and absence of unwanted world objects.
5. Only after verification publish a distinct **Azeroth Forever — vanilla**
   downloadable package. Do not label upstream Manager base files as the custom build.

**This first pass is not an exhaustive audit** of every custom NPC and item
in the 7.59 GB Google Drive RAR: the Drive connector refused whole-archive
transfer with HTTP 413. The changes are grounded in the open-source CoA
fork and its authored SQL. Visual checks in each capital and starter zone,
plus DB fixture scans, are still necessary before claiming the whole world
contains only vanilla/CoA content.
