#!/usr/bin/env python3
"""Static regression checks only. Not a substitute for building/running the realm."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[3]

def read(path):
    return (root / path).read_text(encoding="utf-8")

cmake = read("modules/CMakeLists.txt")
assert "option(AZEROTH_FOREVER_VANILLA" in cmake
assert "AZEROTH_FOREVER_ALLOWED_MODULES" in cmake
assert "list(REMOVE_ITEM MODULES_MODULE_LIST" in cmake

loader = read("src/server/coa/CoAScriptLoader.cpp")
after = loader.split("void AddCoAScripts()", 1)[1]
assert 'AzerothForever.VanillaMode' in after
assert "AddAzerothForeverVanillaCleanupScripts();" in after
for name in [
    "AddSC_AscensionHighRisk",
    "AddSC_AscensionMercenary", "AddSC_AscensionQuestScaling",
    "AddSC_AscensionBloodforged", "AddSC_AscensionClosestResurrection",
]:
    if name != "AddSC_AscensionClosestResurrection":
        assert f"if (!vanilla) {name}();" in after, name
    else:
        # Native corpse flow must remain and the custom town/city spells are
        # rejected/removed by the existing resurrection handler in vanilla mode.
        assert f"{name}();" in after
assert re.search(r"(?m)^\s*AddSC_AscensionHighRisk\(\);$", after) is None

cleanup = read("src/server/coa/AzerothForeverVanillaCleanup.cpp")
assert "1004019" in cleanup and "84433" in cleanup
assert "RemoveAurasDueToSpell" in cleanup and "removeSpell" in cleanup

achievements = read("src/server/coa/AscensionAchievementConditions.cpp")
assert 'if (!sConfigMgr->GetOption<bool>("AzerothForever.VanillaMode", true))' in achievements
assert "new RealmFirstAchievementPermission();" in achievements

ui = read("tools/forever-ui/AzerothForeverUI/AzerothForeverUI.lua")
assert "Achievements()" in ui and "ToggleGameMenu" in ui
assert "systemBar" in ui and "ToggleQuestLog" in ui
assert "RegisterForClicks" in ui
assert "AzerothForeverUISettings" in ui

sql1 = read("tools/vanilla-restoration/001_remove_call_boards.sql")
sql2 = read("tools/vanilla-restoration/002_remove_experimental_transporters.sql")
assert "402000" in sql1 and "402001" in sql1
assert "go_coa_experimental_teleporter" in sql2
for sql in (sql1, sql2):
    assert not re.search(r"(?im)^\s*DELETE\s+(?:FROM\s+)?(?:creature|quest_template|playercreateinfo|character)",sql)

print("PASS: static CoA class-safe Forever profile, achievement, UI and SQL checks")
