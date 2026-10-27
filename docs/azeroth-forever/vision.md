# Azeroth Forever — design charter

## Identity

**Keep every existing Conquest of Azeroth class and specialization.** Azeroth Forever is not a vanilla-class conversion. Its goal is to preserve CoA class identity while presenting a Classic-style level 1–60 journey in the original world.

Class/spec counts must be verified against the imported source and matching client assets; do not guess or use the nine original classes as a fallback.

## Design principles

1. **Meaningful leveling:** level 1–60 should emphasize exploration, quest chains, class learning, world danger and rewarding gear upgrades.
2. **Deliberate combat:** resource management, crowd control, threat, positioning and recovery should matter. Avoid arbitrary health-sponge encounters.
3. **Distinct classes:** retain CoA resources, class-exclusive abilities, talents, pets and class fantasy. Each spec needs a meaningful role in solo and group content.
4. **Original Azeroth first:** start with Eastern Kingdoms and Kalimdor. Restrict expansion-era shortcuts when they undermine the intended travel and discovery loop.
5. **Social gameplay:** dungeons, raids, professions, crafting, trading and open-world cooperation should be valuable.
6. **Purposeful itemization:** strong level-band identities, useful crafted items, memorable drops and sensible power progression.
7. **Classic atmosphere:** a cohesive visual/audio direction, weather and environmental ambience. True lighting/rendering changes require a compatible client modification; the server alone cannot deliver them.
8. **Playable quality:** test character creation, training, class abilities, quests, instances, PvP and relevant client presentation before marking milestones complete.

## World and progression target

- Initial focus: levels 1–60 in vanilla-era Eastern Kingdoms and Kalimdor.
- Keep every supported CoA class and its character-creation requirements.
- Analyze the actual experience curve, movement systems, dungeon rules, professions and loot tables before tuning them.
- Treat the base client protocol, DBC, custom assets and UI patches as compatibility requirements rather than redistributable materials.

## Development discipline

- Start from an explicit upstream commit and retain source provenance.
- Record behavior before changing gameplay; add focused regression checks for fixes.
- Preserve upstream instructions, license notices, SQL migration history and test contracts.
- Do not commit server credentials, player data or proprietary game-client content.
- Separate compilation, server startup, database readiness, client compatibility and in-game visual checks.
