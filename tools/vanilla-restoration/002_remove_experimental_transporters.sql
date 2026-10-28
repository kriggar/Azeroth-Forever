-- Azeroth Forever | verified optional experimental teleporter spawns.
-- Source: src/server/coa/AscensionExperimentalTeleporter.cpp
-- This deletes only gameobjects using its explicitly named script.
-- Preserve any transport / portal required by a retained custom map or quest.
-- Requires a backup. Execute against acore_world only, when no players are online.
DELETE g FROM gameobject AS g
JOIN gameobject_template AS t ON t.entry = g.id
WHERE t.ScriptName = 'go_coa_experimental_teleporter'
  AND NOT EXISTS (SELECT 1 FROM gameobject_queststarter AS q WHERE q.id = g.id)
  AND NOT EXISTS (SELECT 1 FROM gameobject_questender AS q WHERE q.id = g.id);
