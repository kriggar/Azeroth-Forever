# Azeroth Forever

Azeroth Forever is an independent, Classic-style World of Warcraft server development project based on the public [Conquest of AzerothCore](https://github.com/Conquest-of-AzerothCore/azerothcore-wotlk-coa) source.

**Core design:** retain every supported Conquest of Azeroth class and specialization, with a challenging vanilla-inspired level 1–60 experience in the original Azeroth world.

## Goals

- Keep the entire CoA class roster, spell identities, and specialization systems.
- Rework pacing, leveling, enemy difficulty, combat and group roles around Classic-era gameplay.
- Prioritize Eastern Kingdoms and Kalimdor, world exploration, meaningful professions, items, dungeons and raids.
- Develop improved atmosphere and UI through a separate compatible client workstream; server changes alone cannot provide a new graphics renderer.
- Build reproducible development, test and deployment workflows.

## Source and status

The target upstream is `Conquest-of-AzerothCore/azerothcore-wotlk-coa`. This repository is being initialized for the source import and game development. **Do not treat this README as evidence that the CoA server has been imported or built.**

A playable server also needs a compatible client, the required game data and world database, database credentials, a build environment, and a server host. The source code alone is not a complete client download.

### Copyright and licensing

Preserve all upstream copyright and license notices when importing code, especially the GPL-2.0 root license and any individual file notices. Do not commit copyrighted Blizzard client binaries, proprietary game assets, credentials, or players' personal data. The project is independent and is not endorsed by Blizzard Entertainment or the CoA developers.
