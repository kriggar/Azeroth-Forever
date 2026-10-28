import ctypes
import ctypes.util
from pathlib import Path
import unittest


SOURCE = Path(__file__).resolve().parent / "Interface" / "FrameXML" / "ForeverCoATalents.lua"


class ApprovedCoATalentUI(unittest.TestCase):
    def test_faithful_two_tree_contract(self):
        lua = SOURCE.read_text(encoding="utf-8")
        self.assertIn("function UI:ArrangeSpecCards()", lua)
        self.assertIn("function UI:Refresh()", lua)
        self.assertIn("view.ClassTree", lua)
        self.assertIn("view.SpecTree", lua)
        self.assertIn("PositionTree(view.ClassTree, self.left)", lua)
        self.assertIn("PositionTree(view.SpecTree, self.right)", lua)
        self.assertIn('self.left.name:SetText(specInfo.Name)', lua)
        self.assertIn('self.right.name:SetText(specInfo.Name .. " Talents")', lua)
        self.assertIn('bar.SaveChanges:SetText("Save Changes")', lua)
        self.assertIn('view:ShowResetDropDown()', lua)
        self.assertIn('self.root:ShowSpecView()', lua)
        self.assertNotIn("self.alternativeTree", lua)
        self.assertNotIn("PANEL_START", lua)
        self.assertNotIn("Protection", lua)

    def test_lua_parse_when_runtime_available(self):
        name = ctypes.util.find_library("lua5.4") or ctypes.util.find_library("lua5.3")
        if not name:
            self.skipTest("Lua shared library unavailable; syntax checked in local test environment")
        lib = ctypes.CDLL(name)
        lib.luaL_newstate.restype = ctypes.c_void_p
        lib.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t,
                                         ctypes.c_char_p, ctypes.c_char_p]
        lib.luaL_loadbufferx.restype = ctypes.c_int
        lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
        lib.lua_tolstring.restype = ctypes.c_char_p
        lib.lua_close.argtypes = [ctypes.c_void_p]
        state = lib.luaL_newstate()
        try:
            data = SOURCE.read_bytes()
            result = lib.luaL_loadbufferx(state, data, len(data), b"ForeverCoATalents.lua", None)
            if result:
                error = lib.lua_tolstring(state, -1, None)
                self.fail((error or b"Lua parser error").decode("utf-8", "replace"))
        finally:
            lib.lua_close(state)


if __name__ == "__main__":
    unittest.main()
