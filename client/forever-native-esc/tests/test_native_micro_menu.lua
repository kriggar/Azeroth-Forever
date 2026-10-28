-- Lua 5.1 micro menu filter: preserve native WoW buttons, remove only
-- nonstandard Ascension UI actions from the system strip. No action bars.
local function b(name)
    local f={name=name,shown=true,scripts={},hooks={},objectType="Button"}
    function f:GetName() return self.name end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:GetObjectType() return self.objectType end
    function f:ClearAllPoints() end
    function f:SetPoint() end
    function f:SetWidth(x) self.width=x end
    function f:HookScript(n,fn) self.hooks[n]=fn end
    function f:SetScript(n,fn) self.scripts[n]=fn end
    function f:RegisterEvent() end
    return f
end

AzerothForeverNative={}
InCombatLockdown=function() return false end
local character=b("CharacterMicroButton")
local talent=b("TalentMicroButton")
local quest=b("QuestLogMicroButton")
local shop=b("AscensionPrestigeMicroButton")
local trial=b("AscensionTrialMicroButton")
local bag=b("BackpackActionButton")
local action=b("ActionButton1")
ForeverUIMicroMenu=b("ForeverUIMicroMenu")
ForeverUIMicroMenu.objectType="Frame"
ForeverUIMicroMenu:GetName()
ForeverUIMicroMenu.GetChildren=function() return trial end
ForeverUI={
    MicroButtons={
        {button=character},{button=shop},{button=talent},
        {button=trial},{button=quest}
    }
}
CreateFrame=function() return b("watcher") end
local file=arg[0]:gsub("tests[/\\]test_native_micro_menu.lua$",
                       "client/AzerothForeverNativeMicroMenu.lua")
assert(file~=arg[0])
dofile(file)
local M=AzerothForeverNative.MicroMenu
assert(M.Clean())
assert(#ForeverUI.MicroButtons==3)
assert(not trial:IsShown() and not shop:IsShown())
assert(character:IsShown() and talent:IsShown() and quest:IsShown())
assert(bag:IsShown() and action:IsShown(), "bags and combat action slots must stay intact")
assert(ForeverUIMicroMenu.width==3*32+2*(-5))
assert(M.lastCount==3)
assert(M.removed["AscensionPrestigeMicroButton"] and M.removed["AscensionTrialMicroButton"])
print("PASS: native micro bar removes Trial/prestige, retains core and CoA talents")
