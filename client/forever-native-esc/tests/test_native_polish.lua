-- Compact scaling: upgrade old 82% default, preserve custom sizes and CoA talents.
local cvars={uiScale='0.82',useUiScale='1'}
local frames={}
local watcher
local function rect(name,left,right,top,bottom,visible)
    local f={name=name,left=left,right=right,top=top,bottom=bottom,shown=visible}
    function f:IsShown() return self.shown end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:GetLeft() return self.left end
    function f:GetRight() return self.right end
    function f:GetTop() return self.top end
    function f:GetBottom() return self.bottom end
    function f:GetName() return self.name end
    function f:GetObjectType() return 'EditBox' end
    table.insert(frames,f)
    return f
end
local modern=rect('ForeverUISpellBookSearchBox',0,100,100,50,true)
local distant=rect('SpellBookOtherSearch',130,210,100,50,true)
local overlapping=rect('SpellBookLegacySearch',10,90,95,55,true)
local talent=rect('CoATalentsSearch',10,90,95,55,true)
ForeverUISpellBookSearchBox=modern
GetCVar=function(key) return cvars[key] end
SetCVar=function(key,value) cvars[key]=tostring(value) end
InCombatLockdown=function() return false end
UIParent={ SetScale=function(self,x) self.scale=x end }
DEFAULT_CHAT_FRAME={AddMessage=function() end}
EnumerateFrames=function(prev)
    if not prev then return frames[1] end
    for i,x in ipairs(frames) do
        if x==prev then return frames[i+1] end
    end
end
SlashCmdList={}
CreateFrame=function()
    local f={scripts={}}
    function f:RegisterEvent() end
    function f:SetScript(name,callback) self.scripts[name]=callback end
    watcher=f
    return f
end
local path=arg[0]:gsub('tests[/\\]test_native_polish.lua$',
                        'client/AzerothForeverNativePolish.lua')
assert(path~=arg[0])
dofile(path)
local AF=AzerothForeverNative
assert(AF.defaultScale==0.76)
watcher.scripts.OnEvent(watcher,'PLAYER_LOGIN')
assert(cvars.uiScale=='0.76' and UIParent.scale==0.76)
assert(distant:IsShown() and overlapping:IsShown())
AF.FixDuplicateSearches()
assert(distant:IsShown(), 'non-overlapping search must remain visible')
assert(not overlapping:IsShown(), 'overlapping duplicate should be hidden')
assert(talent:IsShown(), 'CoA native talent search must not be hidden')
AF.RestoreLegacySearches()
assert(overlapping:IsShown(), 'restoration command should work')
AF.SetScale(0.70)
assert(cvars.uiScale=='0.7')
watcher.scripts.OnEvent(watcher,'PLAYER_LOGIN')
assert(UIParent.scale==0.7, 'manual compact scale must not be overridden')
cvars.uiScale='1'
watcher.scripts.OnEvent(watcher,'PLAYER_LOGIN')
assert(UIParent.scale==0.76, 'full-size legacy layout should shrink')
print('PASS: 76% initial UI scale, user override, overlap-only search fix, talents untouched')
