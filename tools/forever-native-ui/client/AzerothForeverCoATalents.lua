-- Azeroth Forever: native layout adapter for actual CoA talent trees.
-- CoATalentFrame, C_CharacterAdvancement, the original node renderers and
-- dependency graph remain authoritative; this file only alters presentation.
-- The upstream three-tree WotLK Talent UI cannot run here: all 21 CoA classes
-- have one Class + one Specialization tree in the customized 3.3.5 client.

local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
local R = {}
AF.CoATalents = R
R.version=5
R.lastError=nil

local function isCoA()
    return type(IsCustomClass)=="function" and IsCustomClass()
end
local function fail(text)
    R.lastError=text
    if AF.Notice then AF.Notice("CoA talents: "..tostring(text)) end
end

function R.HasOriginalHandlers(root)
    if not root or not root.TreeView or not root.SpecView then return false end
    local view=root.TreeView
    local bar=view.BottomBar
    if not view.ClassTree or not view.SpecTree or not bar then return false end
    if not bar.SaveChanges or not bar.UndoButton or
       not bar.ChangeSpec or not bar.Search then return false end
    local api=_G.C_CharacterAdvancement
    if not api or type(api.GetActiveChrSpec)~="function" or
       type(api.CanApplyPendingBuild)~="function" then return false end
    return true
end

local function textStyle(tree,shift)
    local label=tree and tree.Label
    local points=tree and tree.Points
    if label then
        label:SetAlpha(1)
        label:SetFontObject(GameFontNormalLarge)
        label:SetTextColor(1,.85,.53)
        label:ClearAllPoints()
        label:SetPoint("BOTTOM",tree,"TOP",0,60)
    end
    if points then
        points:SetAlpha(1)
        points:SetFontObject(GameFontHighlightSmall)
        points:SetTextColor(.88,.74,.37)
        points:ClearAllPoints()
        points:SetPoint("TOP",label or tree, "BOTTOM",0,-4)
    end
end

local function headerLine(view,x)
    local line=view:CreateTexture(nil,"OVERLAY")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(.6,.5,.32,.75)
    line:SetPoint("TOP",view,"TOP",x,-76)
    line:SetWidth(475)
    line:SetHeight(1)
    return line
end

local function layoutBottomBar(view)
    local bar=view.BottomBar
    if bar.afForeverLaidOut then return end
    bar.afForeverLaidOut=true
    -- Modern Forever tree: Save/Undo to the right, Reset at left,
    -- spec picker near left, and a SINGLE native CoA Search input.
    local background=bar:CreateTexture(nil,"BACKGROUND")
    background:SetTexture("Interface\\Buttons\\WHITE8X8")
    background:SetAllPoints(bar)
    background:SetVertexColor(.021,.028,.038,.96)
    local line=bar:CreateTexture(nil,"OVERLAY")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(.48,.42,.31,.8)
    line:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0)
    line:SetPoint("TOPRIGHT",bar,"TOPRIGHT",0,0)
    line:SetHeight(1)
    if bar.Texture then bar.Texture:SetAlpha(.08) end

    local save=bar.SaveChanges
    save:SetWidth(170)
    save:SetHeight(29)
    save:ClearAllPoints()
    save:SetPoint("RIGHT",bar,"RIGHT",-23,-6)
    bar.UndoButton:ClearAllPoints()
    bar.UndoButton:SetPoint("RIGHT",save,"LEFT",-10,0)
    bar.ResetButton:ClearAllPoints()
    bar.ResetButton:SetPoint("LEFT",bar,"LEFT",20,-6)
    bar.ChangeSpec:SetWidth(159)
    bar.ChangeSpec:SetHeight(27)
    bar.ChangeSpec:ClearAllPoints()
    bar.ChangeSpec:SetPoint("RIGHT",bar.UndoButton,"LEFT",-14,0)

    local search=bar.Search
    search:SetWidth(200)
    search:SetHeight(22)
    search:ClearAllPoints()
    search:SetPoint("RIGHT",bar.ChangeSpec,"LEFT",-22,0)

    if bar.SpecDropDown then
        bar.SpecDropDown:ClearAllPoints()
        bar.SpecDropDown:SetPoint("LEFT",bar.ResetButton,"RIGHT",20,0)
    end
    -- Hero Architect / web-link widgets are not part of the Forever tree
    -- footer. Keep their original scripts in place for CoA compatibility,
    -- but do not leave their banners overlapping the actual talent controls.
    for _,name in ipairs({"BuildDropDown","ShareBuildButton","ImportBuildButton"}) do
        local widget=bar[name]
        if widget then widget:Hide() end
    end
end

function R.Style()
    if not isCoA() then return false end
    local root=_G.CoATalentFrame
    if not R.HasOriginalHandlers(root) then return false end
    local view=root.TreeView
    if view.afForeverTreeStyled then
        local visual=AF.CoATreeVisuals
        if visual and visual.Apply then pcall(visual.Apply) end
        return true
    end
    view.afForeverTreeStyled=true

    -- Preserve original clickable tree, node coordinates, branch connectors,
    -- rank counts, gameplay search, pending build state and skill costs.
    textStyle(view.ClassTree,-1)
    textStyle(view.SpecTree,1)
    headerLine(view,-307)
    headerLine(view,307)
    layoutBottomBar(view)

    local visual=AF.CoATreeVisuals
    if visual and type(visual.Apply)=="function" then
        local ok,err=pcall(visual.Apply)
        if not ok then fail(err) end
    end
    return true
end

function R.RemoveAscensionCollectionTabs()
    if not isCoA() then return end
    local c=_G.Collections
    if not c or not c.Tabs or not c.Tabs.CharacterAdvancement or
       type(c.HideTabID)~="function" then return end
    if R.tabsPruned then return end
    for _,name in ipairs({"Vanity","Wardrobe","SeasonalCollection",
                           "MysticEnchants","SkillCards"}) do
        local id=c.Tabs[name]
        if id then pcall(c.HideTabID,c,id) end
    end
    R.tabsPruned=true
end

function R.Fit()
    local c=_G.Collections
    if not c or not UIParent then return end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then return end
    local w,h=c:GetWidth(),c:GetHeight()
    if not w or not h or w<=0 or h<=0 then return end
    local screenW,screenH=UIParent:GetWidth(),UIParent:GetHeight()
    local fit=math.min(1,(screenW-74)/w,(screenH-74)/h)
    local current=c:GetScale() or 1
    -- Keep user's smaller UI scale, and fit large 1290px CoA talent windows.
    local selected=math.max(.65,math.min(current,.90,fit))
    c:SetScale(selected)
end

function R.Open()
    if not isCoA() then return false end
    if type(_G.CharacterAdvancement_LoadUI)=="function" then
        pcall(CharacterAdvancement_LoadUI)
    end
    local c=_G.Collections
    if not c or not c.Tabs or not c.Tabs.CharacterAdvancement then
        fail("CoA talents not yet loaded")
        return false
    end
    if type(c.GoToTab)~="function" then return false end
    c:GoToTab(c.Tabs.CharacterAdvancement)
    R.Style()
    local home=AF.CoATreeHome
    if home and type(home.OpenTrees)=="function" then
        pcall(home.OpenTrees)
    end
    R.Fit()
    return true
end
AF.OpenTalents=R.Open

local function attach()
    if not isCoA() then return false end
    local root=_G.CoATalentFrame
    if not root or R.attached==root then return R.attached==root end
    R.attached=root
    root:HookScript("OnShow",function()
        local ok,err=pcall(R.Style)
        if not ok then fail(err) end
        R.RemoveAscensionCollectionTabs()
        R.Fit()
    end)
    R.Style()
    R.RemoveAscensionCollectionTabs()
    return true
end

local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent",function(self,event,name)
    if event=="PLAYER_LOGIN" or event=="PLAYER_REGEN_ENABLED" or
       (event=="ADDON_LOADED" and
        (name=="Ascension_CoATalents" or name=="Ascension_Collections")) then
        local ok,err=pcall(attach)
        if not ok then fail(err) end
    end
end)
events.elapsed=0
events:SetScript("OnUpdate",function(self,dt)
    if R.attached or not isCoA() then return end
    self.elapsed=self.elapsed+(dt or 0)
    if self.elapsed>1 then
        self.elapsed=0
        local ok,err=pcall(attach)
        if not ok then fail(err) end
    end
end)
