-- Azeroth Forever | Additional VERIFIED standalone Ascension-only world clutter.
-- Provenance: data/sql/updates/pending_db_world/
-- rev_20261028_00_azeroth_forever_vanilla_remove_shortcut_spawns.sql
-- Keep all gameobject templates, creatures, trainers, maps and quest templates.
-- Any world objects whose IDs are linked to retained quests must be audited
-- before release. This file removes only specifically confirmed optional spawns.

-- First-class experimental teleporter, and optional Void Portal event GO.
DELETE FROM gameobject WHERE id IN (323232, 239828);

-- Worldforged optional pickup module placements, not regular loot or quest objects.
DELETE g FROM gameobject AS g
LEFT JOIN gameobject_template AS t ON t.entry = g.id
WHERE g.ScriptName = 'worldforged_pickup' OR t.ScriptName = 'worldforged_pickup';

-- Optional forestry nodes from the custom woodcutting placement migration.
DELETE FROM gameobject
WHERE id = 244614 AND guid BETWEEN 8000000 AND 8200000;
