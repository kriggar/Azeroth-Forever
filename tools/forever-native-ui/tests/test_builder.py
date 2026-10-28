#!/usr/bin/env python3
"""Fast tests for the native MPQ staging logic; no game files needed."""
from pathlib import Path
import importlib.util
import tempfile
import unittest

MODULE = Path(__file__).resolve().parents[1] / "build_native_patch.py"
spec = importlib.util.spec_from_file_location("build_native_patch", MODULE)
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)

class FrameXMLTests(unittest.TestCase):
    def test_preserve_existing_client_loader(self):
        old = b"Bindings.xml\r\nUIParent.lua\r\nAscensionClientCompat.lua\r\n"
        new = native.extend_framexml(old, [
            "AzerothForeverNativeBegin.lua",
            "AzerothForeverNative/UIAtlas.lua",
            "AzerothForeverNativeEnd.lua",
        ])
        self.assertTrue(new.startswith(old))
        self.assertIn(b"AzerothForeverNative\\UIAtlas.lua\r\n", new)
        self.assertNotIn(b"Interface\\AddOns", new)

    def test_refuse_unknown_client_loader(self):
        with self.assertRaisesRegex(ValueError, "Unrecognized"):
            native.extend_framexml(b"SomeOtherUI.lua\n", ["Foo.lua"])

    def test_refuse_existing_native_patch(self):
        with self.assertRaisesRegex(ValueError, "Already native-patched"):
            native.extend_framexml(b"UIParent.lua\nAzerothForeverNativeBegin.lua\n", ["Foo.lua"])

    def test_require_full_mod_not_a_toolbar(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            folder = root / native.SOURCE_FOLDER
            folder.mkdir(parents=True)
            (folder / "ForeverUI.toc").write_text("ActionBar.lua\n")
            (folder / "ActionBar.lua").write_text("-- one bar")
            with self.assertRaisesRegex(ValueError, "Incomplete full-interface"):
                native.read_upstream_toc(root)

    def test_complete_staging_is_native_not_an_addon(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            src = root / "source"
            addon = src / native.SOURCE_FOLDER
            art = src / "data/art/interface/foreverui"
            addon.mkdir(parents=True)
            art.mkdir(parents=True)
            (src / "LICENSE").write_text("GPL-2.0 fixture")
            (art / "ui-test.blp").write_bytes(b"fixture-art")
            names = list(native.UPSTREAM_UI_FILES)
            names.extend("Generated%03d.lua" % i for i in range(92))
            for name in names:
                (addon / name).write_text("-- test file")
            (addon / "ForeverUI.toc").write_text("\n".join(names) + "\n")
            stage = root / "output"
            got = native.stage(src, b"UIParent.lua\nAscensionClassClient.lua\n", stage)
            self.assertEqual(got["ui_modules"], len(names))
            self.assertFalse((stage / "Interface/AddOns").exists())
            self.assertFalse((stage / "Interface/GlueXML").exists())
            toc = (stage / "Interface/FrameXML/FrameXML.toc").read_text()
            self.assertIn("AscensionClassClient.lua", toc)
            self.assertIn("AzerothForeverNative\\QuestLog.lua", toc)
            self.assertIn("AzerothForeverNativeEnd.lua", toc)

if __name__ == "__main__":
    unittest.main()
