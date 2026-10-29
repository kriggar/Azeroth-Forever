local root = assert(arg[0]:match("^(.*)[/\\]tests[/\\][^/\\]+$"))
local E = dofile(root .. "/tests/ui_test_env.lua")
E.setup()
local menu=E.frame("GameMenuFrame", UIParent)
local calls, handlers={},{}
for _, name in ipairs({"Keybindings", "Macros", "AddOns", "Help", "Logout", "Quit", "Continue"}) do
    local button=E.frame("GameMenuButton" .. name, menu)
    local native=function() calls[#calls+1]=name end
    handlers[name]=native
    button:SetScript("OnClick", native)
end
for _, name in ipairs({"Options", "UIOptions", "SoundOptions"}) do E.frame("GameMenuButton" .. name, menu) end
local trial=E.frame("AscensionCustomButton", menu); trial:SetText("Trial")
E.frame("TrialMicroButton", UIParent)
local ordinary=E.frame("UnrelatedAction", UIParent); ordinary:SetText("Trial of Strength")
AzerothForeverNative.OpenSettings=function() calls[#calls+1]="options" end
ForeverUI.CustomizeUI={Open=function() calls[#calls+1]="editmode" end}
dofile(root .. "/client/AzerothForeverNativeGameMenu.lua")
local M=AzerothForeverNative.GameMenu
E.check(M.Install() and M.Refresh() and M.buttonCount==9, "all available native actions must be laid out")
E.check(not TrialMicroButton:IsShown() and not trial:IsShown() and ordinary:IsShown(), "only exact Trial UI is removed")
E.check(not GameMenuButtonOptions:IsShown() and not GameMenuButtonUIOptions:IsShown(), "duplicate settings are hidden")
local previousBottom=0
for _, row in ipairs(M.buttons) do
    local b=row.button
    local top=-b.points.TOP.y
    E.check(top>=previousBottom and top+b:GetHeight()<=menu:GetHeight(), "menu rows cannot overlap or overflow")
    E.check(b.atlas=="128-redbutton" and b.skinCount==1, "all buttons share one idempotent native skin")
    previousBottom=top+b:GetHeight()
end
for name, original in pairs(handlers) do E.check(_G["GameMenuButton" .. name]:GetScript("OnClick")==original) end
M.options:GetScript("OnClick")()
M.edit:GetScript("OnClick")()
GameMenuButtonLogout:GetScript("OnClick")()
GameMenuButtonQuit:GetScript("OnClick")()
GameMenuButtonContinue:GetScript("OnClick")()
E.check(table.concat(calls, ",")=="options,editmode,Logout,Quit,Continue", "original secure operations are preserved")
menu:Show()
E.check(M.heading:IsShown(), "fallback heading is present without native title art")
ForeverUI.GameMenu={header=E.frame(nil, menu)}
M.Refresh()
E.check(not M.heading:IsShown(), "late native header must not overlap a duplicate title")
ForeverUI.CustomizeUI=nil; M.Refresh()
E.check(not M.edit:IsEnabled(), "unavailable Edit Mode must not look functional")
GameMenuButtonMacros=nil; GameMenuButtonHelp=nil; M.Refresh()
E.check(M.buttonCount==7 and GameMenuButtonLogout:IsShown(), "optional missing buttons do not hide secure actions")
UIParent:SetHeight(260); M.Refresh()
E.check(menu:GetHeight()*menu:GetScale()<=220.001, "menu fits a short viewport")
UIParent:SetHeight(1080); M.Refresh()
E.check(math.abs(menu:GetScale()-1)<0.0001, "menu scale recovers on a larger viewport")
E.combat=true
local height=menu:GetHeight()
E.check(not M.Refresh() and M.pending and menu:GetHeight()==height, "combat must defer protected menu layout")
TrialMicroButton:Show()
E.check(TrialMicroButton:IsShown(), "combat does not force protected control visibility")
E.combat=false; E.event("PLAYER_REGEN_ENABLED")
E.check(not TrialMicroButton:IsShown() and not M.pending, "deferred suppression is applied after combat")
local setHeight=menu.SetHeight
menu.SetHeight=function() error("simulated layout exception") end
E.check(not M.Refresh() and not M.locked and M.lastError, "layout exception releases refresh lock")
menu.SetHeight=setHeight
E.check(M.Refresh() and not M.lastError, "menu recovers from an earlier layout exception")
for _, f in ipairs(E.frames) do
    if f.events.PLAYER_LOGIN and f.scripts.OnUpdate then f:Fire("OnUpdate", 1.1); E.check(not f.scripts.OnUpdate) end
end
print("PASS: menu geometry, original secure handlers, optional capabilities and combat recovery; " .. E.checks .. " checks")
