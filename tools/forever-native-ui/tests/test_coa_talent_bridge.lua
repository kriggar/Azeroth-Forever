local root = assert(arg[0]:match("^(.*)[/\\]tests[/\\][^/\\]+$"))
local E = dofile(root .. "/tests/ui_test_env.lua")
local frame = E.setup()
local bar = frame.TreeView.BottomBar
local handlers={}
for _, name in ipairs({"SaveChanges", "UndoButton", "ChangeSpec", "ResetButton"}) do
    handlers[name]=bar[name]:GetScript("OnClick")
end
local searchHandler=bar.Search:GetScript("OnTextChanged")
dofile(root .. "/client/AzerothForeverCoATalents.lua")
local R=AzerothForeverNative.CoATalents
E.check(R.HasOriginalHandlers(frame) and R.Style(), "real CoA native controls remain authoritative")
E.check(not R.HasOriginalHandlers({TreeView={}, SpecView={}}), "invalid frame is rejected")
local canApply=C_CharacterAdvancement.CanApplyPendingBuild
C_CharacterAdvancement.CanApplyPendingBuild=nil
E.check(not R.HasOriginalHandlers(frame), "missing native API fails closed")
C_CharacterAdvancement.CanApplyPendingBuild=canApply
for _, width in ipairs({640, 800, 900, 1290}) do
    bar:SetWidth(width)
    R.LayoutBottomBar(frame.TreeView)
    E.check(R.footerRows == (width < 900 and 2 or 1), "footer adapts to available width")
    E.check(bar.SaveChanges:GetWidth() == 148 and bar.Search:GetWidth() >= 80, "save and search stay usable")
    for name, handler in pairs(handlers) do E.check(bar[name]:GetScript("OnClick") == handler, name .. " changed") end
    E.check(bar.Search:GetScript("OnTextChanged") == searchHandler, "search behavior is preserved")
end
local reset=bar.ResetButton
bar.ResetButton=nil
E.check(pcall(R.LayoutBottomBar, frame.TreeView), "optional reset control cannot crash the screen")
bar.ResetButton=reset
local sizes={{640,480},{1280,720},{1920,1080},{3440,1440},{3840,2160}}
for _, size in ipairs(sizes) do
    UIParent:SetWidth(size[1]); UIParent:SetHeight(size[2]); R.Fit()
    E.check(Collections:GetWidth()*Collections:GetScale() <= size[1]-64+0.001, "talents fit viewport width")
    E.check(Collections:GetHeight()*Collections:GetScale() <= size[2]-64+0.001, "talents fit viewport height")
end
E.check(math.abs(Collections:GetScale()-1)<0.0001, "screen enlargement restores preferred scale")
Collections:SetScale(0.72); R.Fit()
UIParent:SetWidth(640); UIParent:SetHeight(480); R.Fit()
E.check(Collections:GetScale()<0.65, "no minimum-scale clamp may force the window off-screen")
UIParent:SetWidth(1920); UIParent:SetHeight(1080); R.Fit()
E.check(math.abs(Collections:GetScale()-0.72)<0.0001, "explicit user scaling survives viewport changes")
local scaledParent=E.frame(nil, UIParent); scaledParent:SetScale(1.5)
Collections.parent=scaledParent
UIParent:SetScale(0.8); UIParent:SetWidth(800); UIParent:SetHeight(600); R.Fit()
E.check(Collections:GetWidth()*Collections:GetEffectiveScale() <= (800-64)*UIParent:GetEffectiveScale()+0.001,
        "nested parent scaling is included in fit")
E.check(Collections.clamped, "talent window is clamped to the screen")
E.combat=true
local scale=Collections:GetScale()
UIParent:SetWidth(640); UIParent:SetHeight(480)
R.Fit()
E.check(R.needsFit and Collections:GetScale()==scale and not R.Style(), "combat layout is deferred")
E.combat=false
E.event("PLAYER_REGEN_ENABLED")
E.check(not R.needsFit and Collections:GetScale()<scale, "deferred fit executes after combat")
E.check(R.Open() and Collections.currentTab==1, "talent launcher still uses native Collections tab")
E.event("PLAYER_LOGIN")
E.check(Collections.hiddenTabs[2] and Collections.hiddenTabs[3], "legacy collection tabs remain excluded")
for name, handler in pairs(handlers) do E.check(bar[name]:GetScript("OnClick") == handler, name .. " overwritten") end
print("PASS: native talent handlers, responsive footer, five viewport sizes and scale restoration; " .. E.checks .. " checks")
