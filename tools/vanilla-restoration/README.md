# Call Board cleanup (CoA world database)

**This is source work for a future vanilla build; it is not applied to the user's running Windows server automatically.**

Verified from `modules/mod-hero-call-board/data/sql/db-world/2026_09_28_00_hero_call_board.sql`:

| Object | Entry | Original spawn GUID | Map |
|---|---:|---:|---:|
| Stormwind Hero's Call Board | 402000 | 7905400 | 0 |
| Orgrimmar Warchief's Command Board | 402001 | 7905401 | 1 |

## Immediate GM fix for a locally running original CoA server

Log into a GM account (the Windows installer attempts to create `AFTESTER` with GM access).

From Stormwind, enter `.gobject target 402000`. **Verify** the returned object name and GUID. If it is the verified module spawn, `.gobject delete 7905400` removes it from the world database and current world. If GUID is different, do not blindly use 7905400; use the verified GUID reported for the target object.

In Orgrimmar, the equivalent original spawn is `7905401`. Use the same verify-first approach.

For the **unidentified armored NPC next to the board**, target it and run `.npc info` to learn its name, entry and GUID. Only after confirming it is unwanted, use `.npc delete` on the selected NPC. Never delete an NPC purely because it stands beside a board; it could be a standard NPC or an active player/bot.

## Build and database cleanup

- Disable the `mod-hero-call-board` CMake module in the custom build profile. This module is included in the existing exclusion list on `feature/vanilla-coa-baseline`.
- Back up the **actual installed world DB** via official CoA Manager before applying `001_remove_call_boards.sql`.
- Apply only to the world database and confirm the removed entries no longer spawn after server restart.
- Other transports, custom NPCs, PvP systems and resurrection hooks still require individual audits and are NOT cleaned by this SQL.
- Do not run all upstream module SQL migrations after cleaning: some may reinsert these spawns.
- Keep custom map/trainer/CoA class dependencies; alternate quest entry points may be necessary for intended preserved content.
