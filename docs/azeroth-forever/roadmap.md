# Azeroth Forever — development roadmap

## Phase 0 — Source foundation
- [ ] Import the complete public CoA/AzerothCore source and provenance at a recorded commit.
- [ ] Check class/spec definitions, configuration templates and the imported SQL/world content.
- [ ] Confirm working build/test prerequisites and matching client expectations.
- [ ] Verify that no game-client binaries or private credentials are committed.

**Exit:** complete version-controlled code with auditable upstream attribution. No claim of a running server.

## Phase 1 — Classic 1–60 systems
- [ ] Inventory CoA current XP scaling, starting zones, level scaling, travel, boosts, talents, crafting and raid gates.
- [ ] Define level-by-level XP, difficulty and itemization goals and test representative level bands.
- [ ] Implement server-side Classic progression rules behind explicit configuration options.
- [ ] Run upstream-prescribed focused verification and preserve migration history.

**Exit:** stable level 1–60 progression through the intended content using all supported classes.

## Phase 2 — Every CoA class
- [ ] Generate the definitive class/spec matrix directly from source.
- [ ] Audit talent trees, scaling, class resources, weapon rules, pets and starting abilities.
- [ ] Balance group roles, PvE and PvP without flattening distinctive class mechanics.
- [ ] Record focused regression coverage and manual acceptance for each class.

**Exit:** every existing CoA class creates, levels, learns, specs and contributes to solo and group content.

## Phase 3 — World & instances
- [ ] Restore a grounded risk/reward landscape across original Azeroth zones.
- [ ] Adapt quests, dungeons, raids, profession recipes, rewards and world events to this class roster.
- [ ] Improve encounter pacing, threat, rewards and player cooperation.

## Phase 4 — Presentation
- [ ] Prototype compatible client-side interface, environment, weather and lighting changes.
- [ ] Document the necessary client assets/DBCs and any patch or addon delivery procedure.
- [ ] Do not imply server-only modifications add modern lighting to the WoW 3.3.5a renderer.

## Phase 5 — Continuous testing
- [ ] Configure an independently hosted authserver, worldserver and database.
- [ ] Add repeatable build/test pipelines and explicit deployment approvals.
- [ ] Provide a stable test server plus one-time client installation and an updater for client-side changes.

## Scope and release standards

A checked-in source tree is **not** itself a playable realm. Server deployment, the compatible client, matching content and an actual in-game playtest are separate acceptance milestones.
