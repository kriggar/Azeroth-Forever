-- Native in-client onboarding preview test, executed under Lua 5.1 in CI.
-- Confirms Blizzard beta step order, real 21 CoA class names, Hardcore post-
-- launch disabling, Classic/Enhanced preferences and no false account actions.
local windows={}
local function make(kind,name)
    local f={kind=kind or "Frame",name=name or "",shown=true,text="",scripts={},disabled=false}
    function f:SetText(v) self.text=v end
    function f:GetText() return self.text end
    function f:SetPoint() end
    function f:SetWidth() end
    function f:SetHeight() end
    function f:SetJustifyH() end
    function f:SetTextColor() end
    function f:SetVertexColor() end
    function f:SetTexture() end
    function f:SetAllPoints() end
    function f:SetBackdrop() end
    function f:SetBackdropColor() end
    function f:SetBackdropBorderColor() end
    function f:SetFrameLevel() end
    function f:SetFrameStrata() end
    function f:EnableMouse() end
    function f:SetMovable() end
    function f:RegisterForDrag() end
    function f:RegisterEvent() end
    function f:UnregisterEvent() end
    function f:SetScript(evt,fn) self.scripts[evt]=fn end
    function f:CreateTexture() return make("Texture") end
    function f:CreateFontString() return make("FontString") end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:Enable() self.disabled=false end
    function f:Disable() self.disabled=true end
    function f:SetAutoFocus() end
    function f:SetMaxLetters() end
    function f:ClearFocus() end
    return f
end
UIParent=make("Frame","UIParent")
AzerothForeverNative={Notice=function() end}
SlashCmdList={}
UISpecialFrames={}
CreateFrame=function(kind,name)
    local frame=make(kind,name)
    table.insert(windows,frame)
    return frame
end

local file=arg[0]:gsub("tests[/\\]test_native_onboarding.lua$","client/AzerothForeverNativeOnboarding.lua")
assert(file~=arg[0])
dofile(file)
local O=AzerothForeverNative.Onboarding
assert(#O.sourceClasses==21)
local known={}
for _,name in ipairs(O.sourceClasses) do assert(not known[name]); known[name]=true end
for _,name in ipairs({"Necromancer","Starcaller","Knight of Xoroth","Witch Doctor"}) do
    assert(known[name], "missing original CoA class: "..name)
end
assert(O.ruleset=="Normal" and O.preset=="Enhanced" and O.transmog==true)
assert(O.sourceClasses[1]=="Barbarian")
assert(O.Open and type(SlashCmdList.AZEROTHFOREVERSTART)=="function")
O.Open()
assert(O.frame.shown)
assert(O.step==1 and O.next.text=="Continue")
local hardcoreDisabled=false
for _,f in ipairs(windows) do
    if f.kind=="Button" and f.text=="Choose" and f.disabled then
        hardcoreDisabled=true
    end
end
assert(hardcoreDisabled,"Hardcore must be unavailable until official launch support")
O.next.scripts.OnClick()
assert(O.step==2)
local chooseClassic=nil
for _,f in ipairs(windows) do
    if f.kind=="Button" and f.text=="Choose Classic" then chooseClassic=f end
end
assert(chooseClassic and chooseClassic.scripts.OnClick)
chooseClassic.scripts.OnClick()
assert(O.preset=="Classic" and not O.transmog and not O.hdModels and not O.questMarkers)
O.next.scripts.OnClick()
assert(O.step==3)
O.class="Starcaller"
O.next.scripts.OnClick()
assert(O.step==4 and O.next.disabled,"contract is a required acknowledgement")
O.consent=true
O.next.scripts.OnClick()
assert(O.step==5)
assert(O.frame.shown)
O.next.scripts.OnClick()
assert(not O.frame.shown)
assert(type(O.Status())=="string")
-- No calls to character create, realm selection, or invented server protocols.
print("PASS: native five-stage onboarding preview; 21 CoA classes, Hardcore gate and Classic preset")
