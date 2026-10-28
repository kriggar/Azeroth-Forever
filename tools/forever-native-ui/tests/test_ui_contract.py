#!/usr/bin/env python3
"""Enforce native Forever UI panel coverage and preserve the CoA talent contract.

This is a STATIC test. A pass does not prove native client gameplay/visual parity.
"""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[3]
TOOL = ROOT / "tools" / "forever-native-ui"
NATIVE = TOOL / "client"


class ForeverUIContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((TOOL / "ui_contract.json").read_text(encoding="utf-8"))
        cls.panels = cls.manifest["panels"]
        cls.builder = (TOOL / "build_native_patch.py").read_text(encoding="utf-8")
        cls.coa = (NATIVE / "AzerothForeverCoATalents.lua").read_text(encoding="utf-8")

    def test_all_mandatory_panels_have_explicit_ownership(self):
        required = {
            "action_bars", "player_frames", "minimap", "chat", "game_menu",
            "bags", "character_sheet", "spellbook", "talent_panel", "quest_log",
            "world_map", "achievements", "settings", "ui_edit_mode", "professions",
            "guild_social", "group_finder", "trade_auction_mail",
            "npc_dialogs", "inspect", "transmog", "gamepad", "legacy_progression",
            "camping", "cooldown_manager", "appearance_preset"
        }
        self.assertEqual(required, set(self.panels))
        self.assertIn("no separate AzerothForeverUI addon",
                      self.manifest["implementation"])

    def test_sources_exist_or_are_explicitly_pending(self):
        native_names = {p.name for p in NATIVE.glob("*.lua")}
        for name, value in self.panels.items():
            status = value["status"]
            src = value["source"]
            if status == "not_implemented":
                self.assertEqual(src, [], "Pending must not claim working UI " + name)
                continue
            self.assertTrue(src, "Implemented UI must list source files: " + name)
            for file in src:
                if file.startswith("AzerothForever"):
                    self.assertIn(file, native_names, name)
                else:
                    self.assertTrue(file.endswith(".lua"), name)
                    upstream = ROOT / "ui-upstream" / "data/addon/ForeverUI" / file
                    if upstream.parent.exists():
                        self.assertTrue(upstream.is_file(), name + ": " + file)

    def test_stock_wotlk_talent_controller_cannot_override_coa(self):
        self.assertIn('"Talents.lua"', self.builder)
        self.assertIn('COA_UNSAFE_TALENT_CONTROLLERS', self.builder)
        self.assertIn('if f.name not in COA_UNSAFE_TALENT_CONTROLLERS', self.builder)
        self.assertIn('"AzerothForeverCoATalents.lua"', self.builder)
        self.assertIn('"AzerothForeverCoATreeHome.lua"', self.builder)
        self.assertIn('CoATalentFrame', self.coa)
        self.assertIn('C_CharacterAdvancement', self.coa)
        self.assertIn('GetActiveChrSpec', self.coa)
        self.assertIn('CanApplyPendingBuild', self.coa)
        self.assertIn('SaveChanges', self.coa)
        self.assertIn('UndoButton', self.coa)
        self.assertIn('SpecTree', self.coa)
        self.assertIn('ClassTree', self.coa)
        self.assertIn('HideTabID', self.coa)
        self.assertNotIn('LearnTalent(', self.coa)
        self.assertNotIn('SetActiveTalentGroup(', self.coa)
        self.assertNotIn('GetTalentInfo(', self.coa)
        self.assertNotIn('RegisterAddonMessagePrefix(', self.coa)

    def test_entire_interface_is_native_not_new_toolbar(self):
        for name in ("AzerothForeverNativeBegin.lua", "AzerothForeverNativeEnd.lua",
                     "AzerothForeverNativePolish.lua",
                     "AzerothForeverNativeSettings.lua",
                     "AzerothForeverNativeTransmog.lua",
                     "AzerothForeverCoATalents.lua",
                     "AzerothForeverCoATreeHome.lua",
                     "AzerothForeverNativeGameMenu.lua"):
            self.assertIn(name, self.builder)
            self.assertTrue((NATIVE / name).exists())
        self.assertIn('NATIVE_FOLDER = "Interface/FrameXML/AzerothForeverNative"',
                      self.builder)

    def test_remaining_not_done_is_not_misrepresented(self):
        self.assertEqual(
            self.panels["transmog"]["status"], "native_extension_backend_pending")
        self.assertEqual(
            self.panels["talent_panel"]["status"], "native_coa_adapter")
        self.assertEqual(
            self.panels["settings"]["status"], "native_extension")
        self.assertIn("not pixel-perfect", self.manifest["validation"])


if __name__ == "__main__":
    unittest.main()
