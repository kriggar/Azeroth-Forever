import ctypes
import ctypes.util
import unittest
from pathlib import Path


SOURCE = Path(__file__).resolve().parent / 'Interface' / 'FrameXML' / 'ForeverTalents.lua'


class ForeverTalentContractTests(unittest.TestCase):
    def test_native_integration_contract(self):
        content = SOURCE.read_text(encoding='utf-8')
        self.assertIn('for index = 1, 3 do', content)
        self.assertIn('self.view.SpecTree', content)
        self.assertIn('self.view.ClassTree', content)
        self.assertIn('self.root:ChangeSpecID(target.ID)', content)
        self.assertIn('C_CharacterAdvancement.IsPending()', content)
        self.assertIn('self.alternativeClick:SetScript("OnClick"', content)
        self.assertIn('UI:ChangeAlternative()', content)
        self.assertIn('bar.SaveChanges:SetText("Apply Changes")', content)
        self.assertNotIn('Not active', content)
        self.assertNotIn('(Preview)', content)

    def test_lua_switch_and_syntax_smoke(self):
        name = ctypes.util.find_library('lua5.4')
        if not name:
            self.skipTest('No Lua runtime available for optional embedded smoke test')
        lib = ctypes.CDLL(name)
        lib.luaL_newstate.restype = ctypes.c_void_p
        lib.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t,
                                          ctypes.c_char_p, ctypes.c_char_p]
        lib.luaL_loadbufferx.restype = ctypes.c_int
        lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int,
                                   ctypes.c_longlong, ctypes.c_void_p]
        lib.lua_pcallk.restype = ctypes.c_int
        lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
        lib.lua_tolstring.restype = ctypes.c_char_p
        lib.lua_close.argtypes = [ctypes.c_void_p]
        state = lib.luaL_newstate()
        lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
        lib.luaL_openlibs(state)

        def execute(program):
            data = program.encode('utf-8')
            status = lib.luaL_loadbufferx(state, data, len(data), b'forever-test', None)
            if status == 0:
                status = lib.lua_pcallk(state, 0, 0, 0, 0, None)
            if status:
                error = lib.lua_tolstring(state, -1, None)
                self.fail((error or b'unknown Lua error').decode('utf-8', 'replace'))

        try:
            execute('CreateFrame=function() return {RegisterEvent=function() end, SetScript=function() end} end')
            execute(SOURCE.read_text(encoding='utf-8'))
            execute('''
                local ui=AzerothForeverTalents
                ui.root={ChangeSpecID=function(self, id) self.last=id end}
                ui.panelSpecs={[3]={ID=22}}
                C_CharacterAdvancement={
                    GetActiveChrSpec=function() return 11 end,
                    IsPending=function() return false end,
                    CanSwitchActiveChrSpec=function(id) return id==22 end,
                }
                ui:ActivatePanel(3)
                assert(ui.root.last==22 and ui.requestedPanelIndex==3)
                local errors=0
                UIErrorsFrame={AddMessage=function() errors=errors+1 end}
                C_CharacterAdvancement.IsPending=function() return true end
                ui.root.last=nil
                ui:ActivatePanel(3)
                assert(ui.root.last==nil and errors==1)
                C_CharacterAdvancement.IsPending=function() return false end
                UnitClass=function() return 'Starcaller','STARCALLER' end
                C_ClassInfo={
                    GetAllSpecs=function() return {'A','B','C','D'} end,
                    GetSpecInfo=function(_, key)
                        local ids={A=11,B=12,C=13,D=14}
                        return {ID=ids[key],Spec=key,Name=key}
                    end,
                }
                ui.alternativeID=12
                ui.Refresh=function() end
                ui:ChangeAlternative()
                assert(ui.alternativeID==13)
                ui:ChangeAlternative()
                assert(ui.alternativeID==14)
            ''')
        finally:
            lib.lua_close(state)


if __name__ == '__main__':
    unittest.main()
