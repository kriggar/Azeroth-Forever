-- Azeroth Forever: remove the Ascension Call Boards from world spawns.
-- Based on modules/mod-hero-call-board/data/sql/db-world/2026_09_28_00_hero_call_board.sql
-- DO NOT APPLY without a full world database backup.
-- Intended for the *world* database, NOT auth or characters.
--
-- 402000 = Hero's Call Board (Stormwind), module spawn GUID 7905400.
-- 402001 = Warchief's Command Board (Orgrimmar), module spawn GUID 7905401.
-- All spawns of these specific custom object IDs are removed, regardless of GUID,
-- so locally duplicated boards are cleaned up as well.
-- No class trainer, creature, quest template, or custom map data is deleted.
-- This does NOT remove quest-discovery popups from the executable; disable
-- mod-hero-call-board in the custom build, too.
-- Some of the removed boards used to provide quests; maintain alternate
-- quest starters for allowed custom maps before deploying this to a public realm.

DELETE FROM `gameobject`
WHERE `id` IN (402000, 402001);
