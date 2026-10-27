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
