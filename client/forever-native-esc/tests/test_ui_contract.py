#!/usr/bin/env python3
"""Enforce the native Forever UI contract without claiming in-game parity."""
import json
from pathlib import Path
import unittest

HERE = Path(__file__).resolve().parents[1]
TOOL = HERE if (HERE / "build_native_patch.py").is_file() else HERE.parents[1] / "tools" / "forever-native-ui"
ROOT = TOOL.parents[1] if TOOL.name == "forever-native-ui" else TOOL
NATIVE = TOOL / "client"


class ForeverUIContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((TOOL / "ui_contract.json").read_text(encoding="utf-8"))
        cls.panels = cls.manifest["panels"]
        cls.builder = (TOOL / "build_native_patch.py").read_text(encoding="utf-8")
        cls.menu = (NATIVE / "AzerothForeverNativeGameMenu.lua").read_text(encoding="utf-8")

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
            if status in ("not_implemented", "original_coa_client_untouched"):
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

    def test_only_one_esc_layout_owner_and_original_talents(self):
        self.assertIn('NATIVE_REPLACED_UPSTREAM', self.builder)
        self.assertIn('"GameMenu.lua"', self.builder)
        self.assertIn('"Talents.lua"', self.builder)
        self.assertIn('COA_UNSAFE_TALENT_CONTROLLERS', self.builder)
        self.assertIn('if f.name not in (COA_UNSAFE_TALENT_CONTROLLERS | NATIVE_REPLACED_UPSTREAM)', self.builder)
        self.assertIn('"AzerothForeverNativeGameMenu.lua"', self.builder)
        post = self.builder.split('NATIVE_POST_FILES = (',1)[1].split(')',1)[0]
        for name in ('AzerothForeverCoATalents.lua', 'AzerothForeverCoATreeHome.lua',
                     'AzerothForeverCoATalentVisuals.lua'):
            self.assertNotIn(name, post)
        self.assertIn('GameMenuButtonLogout', self.menu)
        self.assertIn('GameMenuButtonQuit', self.menu)
        self.assertIn('GameMenuButtonContinue', self.menu)
        self.assertIn('M.HideTrialControls()', self.menu)
        self.assertIn('frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)', self.menu)

    def test_entire_interface_is_native_not_new_toolbar(self):
        for name in ("AzerothForeverNativeBegin.lua", "AzerothForeverNativeEnd.lua",
                     "AzerothForeverNativePolish.lua",
                     "AzerothForeverNativeSettings.lua",
                     "AzerothForeverNativeTransmog.lua",
                     "AzerothForeverNativeMicroMenu.lua",
                     "AzerothForeverNativeGameMenu.lua"):
            self.assertIn(name, self.builder)
            self.assertTrue((NATIVE / name).exists())
        self.assertIn('NATIVE_FOLDER = "Interface/FrameXML/AzerothForeverNative"',
                      self.builder)

    def test_remaining_not_done_is_not_misrepresented(self):
        self.assertEqual(
            self.panels["transmog"]["status"], "native_extension_backend_pending")
        self.assertEqual(
            self.panels["talent_panel"]["status"], "original_coa_client_untouched")
        self.assertEqual(
            self.panels["settings"]["status"], "native_extension_unverified_in_game")
        self.assertIn("No in-game screenshot", self.manifest["validation"])
        self.assertIn("AzerothForeverNativeOnboarding.lua",self.builder)
        self.assertIn("UNSHIPPED_PROTOTYPES",self.builder)
        self.assertEqual(self.panels["talent_panel"]["source"], [])
        self.assertIn("AzerothForeverNativeMicroMenu.lua",
                      self.panels["game_menu"]["source"])


if __name__ == "__main__":
    unittest.main()
