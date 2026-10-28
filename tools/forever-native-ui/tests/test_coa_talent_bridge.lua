-- Lightweight Lua 5.1 regression for Azeroth Forever's CoA talent adapter.
-- No WoW game executable or fake talent spending is involved.
local events = {}
local function mockFrame()
    local f = {}
    function f:RegisterEvent(name) events[name] = true end
    function f:SetScript(name, cb) self[name] = cb end
    return f
end

AzerothForeverNative = { Notice = function() end }
CreateFrame = function() return mockFrame() end
IsCustomClass = function() return true end
C_CharacterAdvancement = {
    GetActiveChrSpec = function() return 123 end,
    CanApplyPendingBuild = function() return true end,
}
-- This frame shape is from the real CoA source
-- Ascension_CoATalents/CoATalentFrame.xml.
CoATalentFrame = {
    SpecView = {},
    TreeView = {
        ClassTree = { Label={}, Points={} },
        SpecTree = { Label={}, Points={} },
        BottomBar = {
            SaveChanges = { OnClick = function() end },
            UndoButton = { OnClick = function() end },
            ChangeSpec = { OnClick = function() end },
            Search = { OnTextChanged = function() end },
        },
    },
}
local this = arg and arg[0] or "tools/forever-native-ui/tests/test_coa_talent_bridge.lua"
local root = string.gsub(this, "[/\\]tests[/\\]test_coa_talent_bridge.lua$", "")
assert(root ~= this, "test must run from its recorded filename")
dofile(root .. "/client/AzerothForeverCoATalents.lua")
local t = AzerothForeverNative.CoATalents
assert(type(t) == "table" and type(t.HasOriginalHandlers) == "function")
assert(t.HasOriginalHandlers(CoATalentFrame), "real CoA frames must be accepted")
local originalSave = CoATalentFrame.TreeView.BottomBar.SaveChanges.OnClick
local originalUndo = CoATalentFrame.TreeView.BottomBar.UndoButton.OnClick
assert(type(originalSave) == "function" and type(originalUndo) == "function")
assert(not t.HasOriginalHandlers({ TreeView = {}, SpecView = {} }), "invalid frame is rejected")
local original = C_CharacterAdvancement.CanApplyPendingBuild
C_CharacterAdvancement.CanApplyPendingBuild = nil
assert(not t.HasOriginalHandlers(CoATalentFrame), "unavailable backend fails closed")
C_CharacterAdvancement.CanApplyPendingBuild = original
assert(events.ADDON_LOADED and events.PLAYER_LOGIN, "must handle CoA UI load-on-demand")
assert(CoATalentFrame.TreeView.BottomBar.SaveChanges.OnClick == originalSave,
       "CoA Save Changes handler must not be altered")
assert(CoATalentFrame.TreeView.BottomBar.UndoButton.OnClick == originalUndo,
       "CoA Undo handler must not be altered")
print("PASS: Native Forever CoA talent adapter preserves original CoA controls")
