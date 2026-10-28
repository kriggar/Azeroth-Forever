-- Native 3.3.5 Game Menu regression: one column, secure actions, trial suppression.
local frames = {}
local function frame(name, text, click, objectType)
    local f = { name=name, text=text, shown=true, scripts={}, hooks={},
                kind=objectType or "Button", children={}, attributes={} }
    function f:GetName() return self.name end
    function f:GetObjectType() return self.kind end
    function f:GetText() return self.text end
    function f:SetText(v) self.text=v end
    function f:RegisterEvent(event) self.event=event end
    function f:SetScript(event, fn) self.scripts[event]=fn end
    function f:GetScript(event) return self.scripts[event] end
    function f:HookScript(event, fn) self.hooks[event]=fn end
    function f:IsShown() return self.shown end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:SetWidth(v) self.w=v end
    function f:SetHeight(v) self.h=v end
    function f:SetSize(w,h) self.w=w; self.h=h end
    function f:SetEnabled(v) self.enabled=v end
    function f:ClearAllPoints() self.point=nil end
    function f:SetPoint(point, relative, relativePoint, x, y)
        self.point={point,relative,relativePoint,x,y}
    end
    function f:SetBackdrop(v) self.backdrop=v end
    function f:SetBackdropColor() end
    function f:SetBackdropBorderColor() end
    function f:SetAlpha(v) self.alpha=v end
    function f:GetChildren() return unpack(self.children) end
    function f:GetRegions() return end
    function f:CreateFontString() return frame("menu heading",nil,nil,"FontString") end
    if click then f.scripts.OnClick=click end
    table.insert(frames,f)
    return f
end
local calls={}
local secure={
    logout=function() table.insert(calls,'logout') end,
    quit=function() table.insert(calls,'quit') end,
    resume=function() table.insert(calls,'continue') end,
    macros=function() table.insert(calls,'macros') end,
    addons=function() table.insert(calls,'addons') end,
    help=function() table.insert(calls,'support') end,
}
GameMenuFrame=frame('GameMenuFrame', nil, nil, 'Frame')
UIParent=frame('UIParent',nil,nil,'Frame')
local natives={
    {'GameMenuButtonLogout','Log Out',secure.logout},
    {'GameMenuButtonQuit','Quit',secure.quit},
    {'GameMenuButtonContinue','Continue',secure.resume},
    {'GameMenuButtonMacros','Macros',secure.macros},
    {'GameMenuButtonAddOns','AddOns',secure.addons},
    {'GameMenuButtonHelp','Help',secure.help},
    {'GameMenuButtonOptions','Video',function() end},
    {'GameMenuButtonUIOptions','Interface',function() end},
    {'GameMenuButtonSoundOptions','Sound',function() end},
    {'GameMenuButtonKeybindings','Key Bindings',function() end},
}
for _, item in ipairs(natives) do
    local child=frame(item[1],item[2],item[3]); _G[item[1]]=child
    table.insert(GameMenuFrame.children,child)
end
local extra=frame('AscensionUnknownOtherButton','Prestige')
table.insert(GameMenuFrame.children,extra)
local trial=frame('AscensionSpecialTrials','Ascension Trials')
table.insert(GameMenuFrame.children,trial)
TrialMicroButton=frame('TrialMicroButton','')
local actionBarTrialSkill=frame('CombatTrialSkill','Example ability')
-- This is NOT a menu child and must remain untouched by UI cleanup.
MAIN_MENU='Main Menu'
MAINMENU_BUTTON='Game Menu'
AzerothForeverNative={Notice=function() end,OpenSettings=function() table.insert(calls,'options') end}
ForeverUI={CustomizeUI={Open=function() table.insert(calls,'editmode') end}}
local skinned={}
ForeverUI.Templates={
    DialogFrame=function(f) f.styled=true end,
    Header=function(f,title) f.heading=title;return frame('new header',title,nil,'FontString') end,
    ThreeSliceButton=function(b) skinned[b]=true end,
}
CreateFont=function()
    return {
        SetFontObject=function() end, SetShadowOffset=function() end,
        SetShadowColor=function() end, SetTextColor=function() end,
    }
end
SystemFont_Med2={}
GameFontNormal={}
GameFontHighlightLarge={}
GameFontDisableLarge={}
CreateFrame=function(_,name,parent,template)
    local f=frame(name,nil,nil,name and 'Frame' or (template and 'Button' or 'Frame'))
    if parent then table.insert(parent.children,f) end
    return f
end
local path=arg[0]:gsub('tests[/\\]test_native_game_menu.lua$',
                        'client/AzerothForeverNativeGameMenu.lua')
assert(path~=arg[0])
dofile(path)
local M=AzerothForeverNative.GameMenu
assert(M.Install())
assert(M.buttonCount==8, 'expected eight functional menu actions')
assert(GameMenuFrame.styled, 'missing Forever black/gold menu styling')
assert(GameMenuFrame.w==256 and GameMenuFrame.h>200 and GameMenuFrame.h<430)
assert(not trial:IsShown() and not TrialMicroButton:IsShown())
assert(actionBarTrialSkill:IsShown(), 'gameplay outside game menu must stay intact')
assert(not extra:IsShown(), 'extra Ascension buttons must not overlap game menu')
assert(not GameMenuButtonUIOptions:IsShown() and not GameMenuButtonOptions:IsShown())
assert(GameMenuButtonLogout:GetScript('OnClick')==secure.logout)
assert(GameMenuButtonQuit:GetScript('OnClick')==secure.quit)
assert(GameMenuButtonContinue:GetScript('OnClick')==secure.resume)
local positions={}
for i, entry in ipairs(M.ordered) do
    local b=entry.frame
    assert(b.point[1]=='TOPLEFT' and b.point[2]==GameMenuFrame)
    assert(b.point[4]==28, 'horizontal misalignment: '..i)
    assert(b.w==200 and b.h==33, 'nonuniform button sizing')
    if i>1 then assert(b.point[5]<positions[i-1], 'menu rows overlap') end
    positions[i]=b.point[5]
    assert(skinned[b], 'missing native red button treatment')
end
M.Refresh()
assert(M.buttonCount==8)
assert(M.ordered[1].frame==M.options and M.ordered[2].frame==M.edit)
M.options:GetScript('OnClick')()
M.edit:GetScript('OnClick')()
GameMenuButtonLogout:GetScript('OnClick')()
GameMenuButtonQuit:GetScript('OnClick')()
GameMenuButtonContinue:GetScript('OnClick')()
assert(table.concat(calls,',')=='options,editmode,logout,quit,continue')
-- The editor is optional and must not be a fake clickable action if absent.
ForeverUI.CustomizeUI=nil
M.Refresh()
assert(M.edit.enabled==false)
print('PASS: compact Escape menu, one layout owner, 8 functional rows, trial removal, secure clicks')
