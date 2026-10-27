# Azeroth Forever

**Goal: one working Conquest of Azeroth server download that you extract, start, and test locally.**

## Download the server

**[CoA Server Manager — offline server package and Windows installation tests](https://github.com/kriggar/Azeroth-Forever/actions/workflows/coa-manager-offline-server.yml)**

The new workflow compiles **CoA Server Manager's actual open-source Rust installation engine**, includes the publisher's signed server base archive and verifies it before launching the server installation. The real Manager installer initializes MySQL and creates new local database credentials on each PC. **Only use a build once its Windows installation test has passed.**

**Why not the green Code → Download ZIP button?** GitHub's Code ZIP exports tracked source code. The working server contains large prebuilt binaries and game data that exceed ordinary Git file limits; client-extracted data also have separate redistribution rights. A tested Windows server distribution must be downloaded as a separately packaged artifact or authorized release.

## Status

- Previous custom ZIP installer **FAILED** its Windows startup test because it skipped the CoA Server Manager database initialization (`Settings/database.json` was absent). Do not use the old `tools/portable/` launcher.
- The real Manager installation workflow is now being integrated and tested.
- The separate Windows build pipeline compiles our **future customized server code**; a successful source-code commit is not automatically a playable server update.

## What stays in GitHub

This repository currently also contains the open-source server code used for gameplay development, based on `Corfirean/azerothcore-wotlk-coa` at the pinned revision recorded in [MANAGER_SOURCE.md](MANAGER_SOURCE.md). We retain the source to modify classes, spells, talents, quests, and other mechanics. It is distinct from the installed server.

**Azeroth Forever's direction:** keep every Conquest of Azeroth class and specialization, but develop a grounded, slower, vanilla-style Azeroth leveling and exploration experience.

## Sources, distribution and licenses

- [CoA Server Manager (official open-source manager)](https://github.com/Corfirean/coa-server-manager)
- [Publisher's signed CoA server base package](https://github.com/Corfirean/coa-server-build/releases/tag/base)
- [Server-core source fork](https://github.com/Corfirean/azerothcore-wotlk-coa)

This is an independent project; preserve GPL/AGPL notices. The client-extracted DBC/maps/vmaps/mmaps data in the publisher's package are **not covered by the open-source code license**. Don't commit those proprietary files or personal server credentials to this public repository.
