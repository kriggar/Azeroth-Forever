#!/usr/bin/env python3
"""Fast, dependency-free regression checks for the Azeroth Forever vanilla preset.

Runs against source files only. A passing result does NOT prove that the
compiled realm starts or that the game client can log in.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]

def source(path):
    return (ROOT / path).read_text(encoding="utf-8")

def parse_config(path):
    result = {}
    for line in source(path).splitlines():
        match = re.match(r"^([A-Za-z][\w.]*)\s*=\s*(.*?)\s*$", line)
        if match:
            result[match.group(1)] = match.group(2)
    return result

def check(condition, message):
    if not condition:
        raise AssertionError(message)

def main():
    conf = parse_config("src/server/coa/conf/coa.conf.dist")
    keep_on = ["CoA.Enable", "CoA.CharacterSelectionEnable", "CoA.SendDisplayPatches",
               "AzerothForever.VanillaMode"]
    for key in keep_on:
        check(conf.get(key) == "1", f"Required CoA compatibility setting {key} must be 1")
    check(conf["CoA.ClassModel"].strip().strip(chr(34)).lower() == "coa",
          "Only Conquest of Azeroth classes should be exposed")
    check(conf.get("CoA.GameModeMask") == "0",
          "Alternate Ascension game modes must be disabled")
    for key in [
        "CoA.RotationAssist.Enable", "CoA.CreatureScaling.Enable",
        "CoA.MonsterResistance.Enable", "CoA.QuestLevelScaling", "CoA.ItemScaling",
        "CoA.ItemScaling.Native", "CoA.EquippedGearLoot", "CoA.MaxRidingFromStart",
        "HighRisk.Losses", "HighRisk.FelCommutation.Enable", "PvpPower.Enable",
        "PvePower.Enable", "Bloodforged.Enable", "CoA.DungeonTuning.Enable",
    ]:
        check(conf.get(key) == "0", f"{key} must be disabled for vanilla")
    check(conf.get("CoA.Crafting.MaxUpgradeSteps") == "0",
          "Convenience equipment upgrading should not be enabled")

    world = parse_config("src/server/apps/worldserver/worldserver.conf.dist")
    check(world.get("StartPlayerLevel") == "1", "Start at level 1")
    check(world.get("MaxPlayerLevel") == "60", "Vanilla cap is level 60")
    for key in ("Rate.XP.Global", "Rate.XP.Kill", "Rate.XP.Kill.TBC",
                "Rate.XP.Kill.WotLK", "Rate.XP.Quest", "Rate.XP.Quest.TBC",
                "Rate.XP.Quest.WotLK", "Rate.XP.Explore"):
        check(world.get(key) == "1", f"Vanilla 1x XP required for {key}")
    check(world.get("Rate.XP.Profession") == "0",
          "Gathering and crafting must not grant character experience")
    for key in ("Rate.XP.Elite", "Rate.XP.DungeonElite"):
        check(world.get(key) == "2", f"Classic elite XP expected for {key}")

    checks = {
        "src/server/coa/AscensionRulesets.cpp": [
            "AzerothForever.VanillaMode", "SPELL_SELECT_HIGH_RISK",
            "SPELL_SELECT_WAR_MODE", "SPELL_SELECT_PVE",
            "player->removeSpell(id, 0xFF, false)",
            "SPELL_SELECT_WAR_MODE, SPELL_SELECT_HIGH_RISK, SPELL_SELECT_PVE"
        ],
        "src/server/coa/AscensionClosestResurrection.cpp": [
            "AzerothForever.VanillaMode", "SPELL_FAILED_NOT_HERE",
            "player->removeSpell(spellId, 0xFF, false)"
        ],
        "src/server/coa/AscensionHighRisk.cpp": [
            "AzerothForever.VanillaMode", "High-Risk chests disabled"
        ],
        "src/server/coa/AscensionVoidPortal.cpp": ["AzerothForever.VanillaMode"],
        "src/server/coa/AscensionExperimentalTeleporter.cpp": ["AzerothForever.VanillaMode"]
    }
    for path, required in checks.items():
        text = source(path)
        for marker in required:
            check(marker in text, f"Missing {marker} in {path}")

    migration = source("data/sql/updates/pending_db_world/"
                       "rev_20261028_00_azeroth_forever_vanilla_remove_shortcut_spawns.sql")
    for marker in ["323232", "239828", "402000", "402001", "worldforged_pickup"]:
        check(marker in migration, f"Missing spawn cleanup for {marker}")
    for unsafe in ("DELETE FROM `creature_template`", "DELETE FROM `gameobject_template`",
                   "DELETE FROM `quest_template`", "TRUNCATE"):
        check(unsafe.lower() not in migration.lower(),
              f"Cleanup must not destroy templates / quests: {unsafe}")
    for name in ("northshire", "coldridge", "valley_of_trials", "deathknell",
                 "camp_narache", "shadowglen", "ammen_vale", "sunstrider"):
        trainer = ROOT / ("data/sql/updates/pending_db_world/"
                          "rev_20260923_" +
                          {"northshire":"06", "coldridge":"07", "valley_of_trials":"08",
                           "deathknell":"09", "camp_narache":"10", "shadowglen":"11",
                           "ammen_vale":"12", "sunstrider":"13"}[name] +
                          "_coa_class_trainers_" + name + ".sql")
        check(trainer.is_file(), f"Missing protected trainer migration {trainer.name}")

    loader = source("src/server/coa/CoAScriptLoader.cpp")
    for disabled in ("AddSC_AscensionConvenienceItems", "AddSC_AscensionPersonalBank",
                     "AddSC_AscensionWisdomball", "AddSC_AscensionExperimentalTeleporter",
                     "AddSC_AscensionVoidPortal", "AddSC_AscensionWelcomeWarchest",
                     "AddSC_AscensionAdventurerCache", "AddSC_AscensionHeirloomWeaponStore",
                     "AddSC_AscensionBushcraft", "AddSC_AscensionCallboardCache"):
        check("if (!vanilla) " + disabled + "();" in loader,
              f"Unwanted convenience script {disabled} must be off by default")
    for preserved in ("AddSC_AscensionRulesets();", "AddSC_AscensionClosestResurrection();",
                      "AddAscensionBarbarianAbilityScripts();",
                      "AddAscensionNecromancerAbilityScripts();",
                      "AddSC_AscensionRunemasterTalents();",
                      "AddSC_AscensionPrimalistTalents();"):
        check("    " + preserved in loader, f"Protected class/cleanup script missing: {preserved}")

    windows = source(".github/workflows/build-windows-exe.yml")
    check("-DMODULES=disabled" in windows,
          "Optional CoA modules must be excluded from the vanilla Windows build")
    check("-DSCRIPTS=static" in windows, "Stock Azeroth / CoA core scripts must remain enabled")
    check((ROOT / "modules/mod-ascension/data/sql/db-world/"
           "2026_08_27_00_ascension_custom_classes.sql").is_file(),
          "CoA class SQL must not be removed")

    print("PASS: vanilla gameplay preset disables unwanted systems")
    print("PASS: base CoA compatibility, custom classes and eight regional trainer packs retained")
    print("PASS: cleanup is targeted at optional clutter, not map or quest templates")
    print("NOTE: This does not test live server startup or 3D client assets")

if __name__ == "__main__":
    try:
        main()
    except (AssertionError, OSError, ValueError, KeyError) as e:
        sys.exit("FAIL: " + str(e))
