-- Azeroth Forever: vanilla world, preserved custom maps and CoA class training.
--
-- Remove only precisely identified permanent transport/portal spawns authored by
-- the optional Ascension travel/event systems. Do not broadly delete gameobjects,
-- gameobject_template, quest-related scenery, trainers, or CoA class-quest items.
--
-- First-Class Experimental Teleporter: rev_20261008_00_experimental_teleporter.sql
-- The script is disabled in vanilla mode as a second layer of protection.
DELETE FROM `gameobject` WHERE `id` = 323232;
-- Historical fixed spawn GUIDs were 7905410-7905416. The template is retained
-- so other databases / client references do not become invalid.
DELETE FROM `gameobject`
WHERE `guid` BETWEEN 7905410 AND 7905416 AND `id` = 323232;

-- The open-world Void Portal invasion event is optional and not vanilla travel.
-- rev_20261024_46_ascension_void_portal.sql owns the spawn group GUIDs below.
-- Remove group references before creature spawns to avoid orphaned groups.
DELETE FROM `spawn_group`
WHERE `groupId` IN (9000001, 9000002, 9000003, 9000004)
  AND `spawnType` = 0
  AND `spawnId` BETWEEN 8001308 AND 8001327;
DELETE FROM `creature_addon` WHERE `guid` BETWEEN 8001308 AND 8001327;
DELETE FROM `creature`
WHERE `guid` BETWEEN 8001308 AND 8001327 AND `id` = 23746;
DELETE FROM `spawn_group_template`
WHERE `groupId` IN (9000001, 9000002, 9000003, 9000004)
  AND `groupName` LIKE 'Void Portal%';
DELETE FROM `ascension_void_portal_group`
WHERE `groupId` IN (9000001, 9000002, 9000003, 9000004);
DELETE FROM `gameobject` WHERE `id` = 239828;

-- The rows defining client/display templates are deliberately preserved.
-- CoA class trainers, custom map data, and required quest objects are untouched.

-- Worldforged ground loot objects (the module owns approximately 2,469 placements).
-- Their templates and spawns are explicitly labeled worldforged_pickup by
-- modules/mod-worldforged-pickups/data/sql/db-world/*.sql. Leave all ordinary
-- quest objects and all CoA class-chain GOs alone, regardless of their map.
-- Keep item/loot definitions and character ledgers intact for a reversible rollback.
DELETE g FROM `gameobject` AS g
LEFT JOIN `gameobject_template` AS t ON t.`entry` = g.`id`
WHERE g.`ScriptName` = 'worldforged_pickup'
   OR t.`ScriptName` = 'worldforged_pickup';

-- Optional extra world fixtures, not CoA class trainers or their quest props.
-- Hero's Call / Warchief's Command Board (mod-hero-call-board).
DELETE FROM `gameobject` WHERE `id` IN (402000, 402001);

-- Optional forestry resource-node spawns authored by rev_20260928_82_woodcutting_spawns.
-- Do not remove unrelated objects or classic interactable trees by name.
DELETE FROM `gameobject`
WHERE `id` = 244614 AND `guid` BETWEEN 8000000 AND 8200000;
