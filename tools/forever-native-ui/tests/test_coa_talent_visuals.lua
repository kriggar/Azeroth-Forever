-- Static runtime smoke test: actual CoA nodes get Forever-style square frames.
-- Does not emulate client rendering or pixel parity, but prevents hooks from
-- changing class talents/Save/Undo or adding a fake spell.
local function frame(typeName)
    local f = {objectType=typeName or "Frame", children={}, events={}, scripts={}, hooks={}, frameLevel=4}
    function f:RegisterEvent(name) self.events[name]=true end
    function f:SetScript(name,fn) self.scripts[name]=fn end
    function f:HookScript(name,fn) self.hooks[name]=fn end
    function f:GetObjectType() return self.objectType end
    function f:GetChildren() return unpack(self.children) end
    function f:CreateTexture()
        local t=frame("Texture")
        t:SetParent(self)
        return t
    end
    function f:SetParent(x) self.parent=x end
    function f:GetFrameLevel() return self.frameLevel end
    function f:SetFrameLevel(n) self.frameLevel=n end
    function f:SetPoint() end
    function f:SetAllPoints() end
    function f:SetTexture(path) self.texture=path end
    function f:SetTexCoord() end
    function f:SetVertexColor() end
    function f:SetAlpha(a) self.alpha=a end
    function f:SetWidth() end
    function f:SetHeight() end
    function f:IsEnabled() return true end
    function f:EnableMouse() end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    return f
end
local created={}
CreateFrame=function(_,name,parent)
    local f=frame("Frame")
    if parent then table.insert(parent.children,f) end
    table.insert(created,f)
    return f
end
IsCustomClass=function() return true end
AzerothForeverNative={}
local atlasLookup={}
ForeverUI={
    AtlasEntry=function(name)
        atlasLookup[name]=(atlasLookup[name] or 0)+1
        return {"Interface\\ForeverUI\\TalentFrame\\Talents",0,1,0,1,80,80}
    end
}
local button=frame("Button")
button.SetEntry=function() end
button.Icon=frame("Frame")
button.Icon.SetRounded=function(self,b) self.rounded=b end
local fakeOriginal=function() return 771 end
button:SetScript("OnClick",fakeOriginal)
local classTree=frame("Frame")
classTree.children={button}
local specTree=frame("Frame")
local view=frame("Frame")
view.ClassTree=classTree
view.SpecTree=specTree
-- Test idempotent node decoration independently of CoA loader.
local main=arg[0]:gsub("tests[/\\]test_coa_talent_visuals.lua$",
                       "client/AzerothForeverCoATalentVisuals.lua")
assert(main~=arg[0])
dofile(main)
local V=AzerothForeverNative.CoATreeVisuals
assert(V and V.StyleNode)
assert(V.StyleNode(button))
assert(button.afForeverNodeStyled)
assert(button.Icon.rounded==false)
assert(button.afForeverTrim.texture)
assert(button:GetScript("OnClick")==nil or button.scripts.OnClick==fakeOriginal)
local count=V.nodeCount
V.StyleNode(button)
assert(V.nodeCount==count,"style must be idempotent")
assert(atlasLookup[V.atlas.nodeYellow])
-- CoA retains actual node ID and original click/point routines.
assert(button.SetEntry and type(button.SetEntry)=="function")
print("PASS: actual CoA talent node restyled with Forever atlas; original handlers preserved")
