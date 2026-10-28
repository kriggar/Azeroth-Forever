-- Lua 5.1 native Escape menu contract: keep original secure game actions,
-- provide Options/Edit Mode, hide only explicit Trial UI controls.
local function frame(name, text, click)
    local f={ name=name, text=text, shown=true, scripts={}, hooks={} }
    function f:GetName() return self.name end
    function f:GetText() return self.text end
    function f:SetText(v) self.text=v end
    function f:RegisterEvent() end
    function f:SetScript(ev,fn) self.scripts[ev]=fn end
    function f:GetScript(ev) return self.scripts[ev] end
    function f:HookScript(ev,fn) self.hooks[ev]=fn end
    function f:IsShown() return self.shown end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:SetWidth(v) self.w=v end
    function f:SetHeight(v) self.h=v end
    function f:ClearAllPoints() end
    function f:SetPoint() end
    function f:SetBackdrop() end
    function f:SetBackdropColor() end
    function f:SetBackdropBorderColor() end
    function f:CreateFontString() return frame("heading") end
    function f:GetChildren() return unpack(self.children or {}) end
    if click then f.scripts.OnClick=click end
    return f
end
AzerothForeverNative={Notice=function() end}
local secureCalls={}
local logout=function() table.insert(secureCalls,"logout") end
local quit=function() table.insert(secureCalls,"quit") end
local resume=function() table.insert(secureCalls,"continue") end
GameMenuFrame=frame("GameMenuFrame")
GameMenuButtonLogout=frame("GameMenuButtonLogout","Log Out",logout)
GameMenuButtonQuit=frame("GameMenuButtonQuit","Exit Game",quit)
GameMenuButtonContinue=frame("GameMenuButtonContinue","Return to Game",resume)
GameMenuButtonOptions=frame("GameMenuButtonOptions","Video",function() end)
GameMenuButtonUIOptions=frame("GameMenuButtonUIOptions","Interface",function() end)
GameMenuButtonKeybindings=frame("GameMenuButtonKeybindings","Key Bindings",function() end)
-- The two buttons below are optional in this older CoA client.
GameMenuButtonMacros=nil
GameMenuButtonHelp=nil
TrialMicroButton=frame("TrialMicroButton","")
local trial=frame("AscensionCustomButton","Trial")
GameMenuFrame.children={trial,GameMenuButtonLogout,GameMenuButtonQuit,
    GameMenuButtonContinue,GameMenuButtonOptions,GameMenuButtonKeybindings}
local forms={}
CreateFrame=function(_,name,parent)
    local f=frame(name)
    table.insert(forms,f)
    return f
end
AzerothForeverNative.OpenSettings=function() table.insert(secureCalls,"options") end
ForeverUI={CustomizeUI={Open=function() table.insert(secureCalls,"editmode") end}}
local path=arg[0]:gsub("tests[/\\]test_native_game_menu.lua$","client/AzerothForeverNativeGameMenu.lua")
assert(path~=arg[0])
dofile(path)
local M=AzerothForeverNative.GameMenu
assert(M.Install())
assert(M.buttonCount>=5,"missing optional buttons must not hide secure Logout/Quit/Return")
assert(not TrialMicroButton:IsShown() and not trial:IsShown())
assert(not GameMenuButtonOptions:IsShown() and not GameMenuButtonUIOptions:IsShown(),
    "separate legacy options entries must be consolidated")
assert(M.options and M.edit and M.options:IsShown() and M.edit:IsShown())
assert(GameMenuButtonLogout:GetScript("OnClick")==logout)
assert(GameMenuButtonQuit:GetScript("OnClick")==quit)
assert(GameMenuButtonContinue:GetScript("OnClick")==resume)
M.options.scripts.OnClick()
M.edit.scripts.OnClick()
GameMenuButtonLogout.scripts.OnClick()
GameMenuButtonQuit.scripts.OnClick()
GameMenuButtonContinue.scripts.OnClick()
assert(table.concat(secureCalls,",")=="options,editmode,logout,quit,continue")
print("PASS: Forever-native Esc menu, safe existing secure actions and targeted Trial removal")
