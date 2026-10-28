-- Azeroth Forever native CoA first-screen talent tree behavior smoke test.
-- Lua 5.1 mock: verifies real CoA TreeView is opened first, its original
-- ClassTree/SpecTree nodes untouched and specialization selection delegated.
local function frame(name, initiallyShown)
    local f={name=name, shown=initiallyShown ~= false, scripts={}, hooks={}, text="", level=3}
    function f:Show()
        self.shown=true
        if self.hooks.OnShow then self.hooks.OnShow(self) end
    end
    function f:Hide()
        self.shown=false
        if self.hooks.OnHide then self.hooks.OnHide(self) end
    end
    function f:IsShown() return self.shown end
    function f:RegisterEvent() end
    function f:SetScript(event,func) self.scripts[event]=func end
    function f:HookScript(event,func) self.hooks[event]=func end
    function f:SetText(text) self.text=text end
    function f:SetJustifyH() end
    function f:GetText() return self.text end
    function f:SetHeight() end
    function f:SetWidth() end
    function f:SetPoint() end
    function f:SetAllPoints() end
    function f:EnableMouse() end
    function f:SetVertexColor() end
    function f:SetTexture() end
    function f:SetFrameLevel(n) self.level=n end
    function f:GetFrameLevel() return self.level end
    function f:CreateTexture() return frame("texture") end
    function f:CreateFontString() return frame("text") end
    function f:Disable() self.disabled=true end
    return f
end
_G.AzerothForeverNative={Notice=function() end}
_G.IsCustomClass=function() return true end
_G.UnitClass=function() return "Starcaller","STARCALLER" end
_G.C_ClassInfo={
    GetAllSpecs=function(class) assert(class=="STARCALLER"); return {"MoonGuard","Sentinel"} end,
    GetSpecInfo=function(class,key)
        assert(class=="STARCALLER")
        local ids={MoonGuard=271,Sentinel=272}
        return {ID=ids[key],Name=key=="MoonGuard" and "Moon Guard" or "Sentinel"}
    end
}
local changed={}
local a={specInfo={ID=271},OnSelected=function(self) table.insert(changed,self.specInfo.ID) end}
local b={specInfo={ID=272},OnSelected=function(self) table.insert(changed,self.specInfo.ID) end}
local pool={
    EnumerateActive=function()
        local i=0
        return function()
            i=i+1
            return ({a,b})[i]
        end
    end
}
_G.C_CharacterAdvancement={
    GetActiveChrSpec=function() return nil end,
    CanSwitchActiveChrSpec=function(id) return id==271 or id==272 end
}
local tree=frame("real-CoA-tree",false)
tree.ClassTree=frame("original-coa-class-tree")
tree.SpecTree=frame("original-coa-spec-tree")
tree.BottomBar={SaveChanges=frame("real-original-save")}
tree.SetSpecID=function(self,id) self.lastSpecId=id end
local spec=frame("original-card-selector",true)
spec.SpecChoicePool=pool
_G.CoATalentFrame=frame("coa-window")
CoATalentFrame.TreeView=tree
CoATalentFrame.SpecView=spec

local created={}
_G.CreateFrame=function(_,name)
    local f=frame(name)
    table.insert(created,f)
    return f
end

local script=arg[0]:gsub("tests[/\\]test_coa_tree_home.lua$","client/AzerothForeverCoATreeHome.lua")
assert(script~=arg[0])
dofile(script)

local R=AzerothForeverNative.CoATreeHome
assert(R.GetSpecs and #R.GetSpecs()==2)
assert(R.OpenTrees(), "the authentic CoA talent graph must open")
assert(tree:IsShown() and not spec:IsShown(), "cards must not be the first screen")
assert(tree.lastSpecId==271,"client preview should use actual CoA specialization data")
assert(R.treesOpened and R.tabStrip and R.buttons[1].text:find("Moon Guard"))
assert(R.buttons[2].text:find("Sentinel"))
assert(R.Select(272), "selecting a real specialization should succeed")
assert(#changed==1 and changed[1]==272,
       "selection must pass to the original CoA handler, not an invented server API")
assert(tree.ClassTree.name=="original-coa-class-tree")
assert(tree.SpecTree.name=="original-coa-spec-tree")
assert(tree.BottomBar.SaveChanges.disabled,
       "while no spec is confirmed the client may preview but not fake a talent save")
-- Simulated data-shape matrix, not actual class IDs/skill DB validation:
-- the adapter must not assume Warrior/Mage or exactly three specializations.
for classId=12,32 do
    UnitClass=function() return "CoA Test", "COA_"..classId end
    for specCount=1,7 do
        C_ClassInfo.GetAllSpecs=function(cls)
            assert(cls=="COA_"..classId)
            local arr={}
            for i=1,specCount do arr[i]="Spec"..i end
            return arr
        end
        C_ClassInfo.GetSpecInfo=function(cls,key)
            return {ID=1000+classId*10+tonumber(key:match("%d+")),Name=key}
        end
        local actual=R.GetSpecs()
        assert(#actual==specCount,
            "classId "..classId.." with "..specCount.." specializations is not supported")
    end
end
print("PASS: Direct CoA talent trees, original selections and 147 class/spec shape variants")
