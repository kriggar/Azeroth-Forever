-- Azeroth Forever — Forever-style CoA talent tree visuals, native FrameXML.
-- Not an addon and not a replacement talent system.
-- Applies actual ForeverUI atlas art to live CoA talent tree widgets.
-- CoA node ID, rank, prerequisites, Save/Undo, specialization RPC and events
-- remain entirely owned by its original C_CharacterAdvancement handlers.

local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
local V = {}
AF.CoATreeVisuals = V
V.version = 1
V.nodeCount = 0
V.treeCount = 0
V.lastError = nil
V.hooks = {}
V.atlas = {
    panel = "talents-background-c60",
    border = "talents-inner-frame-c60",
    leftHeader = "talents-divider-left-c60",
    rightHeader = "talents-divider-right-c60",
    vertical = "talents-divider-vertical-c60",
    nodeGreen = "talents-node-square-green",
    nodeGray = "talents-node-square-gray",
    nodeYellow = "talents-node-square-yellow"
}

local function findAtlas(name)
    local f = _G.ForeverUI
    if f and type(f.AtlasEntry)=="function" then
        return f.AtlasEntry(name)
    end
    return nil
end

local function art(texture,name)
    local atlas=findAtlas(name)
    if not atlas or not texture then return false end
    texture:SetTexture(atlas[1])
    texture:SetTexCoord(atlas[2],atlas[3],atlas[4],atlas[5])
    return true
end

local function isCoA()
    return type(IsCustomClass)=="function" and IsCustomClass()
end

local function note(text)
    if AF.Notice then AF.Notice("Talent visuals: "..tostring(text)) end
end

local function frameBg(parent,topLeft,bottomRight,atlasName)
    local frame=CreateFrame("Frame",nil,parent)
    frame:EnableMouse(false)
    frame:SetPoint("TOPLEFT",parent,topLeft[1],topLeft[2])
    frame:SetPoint("BOTTOMRIGHT",parent,bottomRight[1],bottomRight[2])
    frame:SetFrameLevel(math.max(0,parent:GetFrameLevel()-1))
    local t=frame:CreateTexture(nil,"BACKGROUND")
    t:SetAllPoints(frame)
    if art(t,atlasName) then
        t:SetVertexColor(.39,.42,.46,.94)
    else
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetVertexColor(.045,.05,.065,.92)
    end
    local edge=frame:CreateTexture(nil,"BORDER")
    edge:SetTexture("Interface\\Buttons\\WHITE8X8")
    edge:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
    edge:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
    edge:SetHeight(1)
    edge:SetVertexColor(.58,.50,.32,.80)
    local bottom=frame:CreateTexture(nil,"BORDER")
    bottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    bottom:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,0)
    bottom:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
    bottom:SetHeight(1)
    bottom:SetVertexColor(.30,.34,.38,.7)
    return frame
end

local function createPanels(view)
    if view.afForeverFullTreePanels then return end
    view.afForeverFullTreePanels=true
    -- The original CoA layout has TWO real graph frames (Class and Spec).
    -- Give those exact two halves Forever-style bordered panels. We do not
    -- create a third empty fake tab, nor remap actual nodes.
    local width=(view:GetWidth() or 1290)/2
    local panelLeft=CreateFrame("Frame","AzerothForeverClassTreePane",view)
    panelLeft:EnableMouse(false)
    panelLeft:SetPoint("TOPLEFT",view,"TOPLEFT",19,-43)
    panelLeft:SetPoint("BOTTOMRIGHT",view,"BOTTOM",-7,67)
    local panelRight=CreateFrame("Frame","AzerothForeverSpecTreePane",view)
    panelRight:EnableMouse(false)
    panelRight:SetPoint("TOPLEFT",view,"TOP",7,-43)
    panelRight:SetPoint("BOTTOMRIGHT",view,"BOTTOMRIGHT",-19,67)

    for _,pane in ipairs({panelLeft,panelRight}) do
        pane:SetFrameLevel(math.max(0,view:GetFrameLevel()-1))
        local stone=pane:CreateTexture(nil,"BACKGROUND")
        stone:SetAllPoints(pane)
        if not art(stone,V.atlas.panel) then
            stone:SetTexture("Interface\\Buttons\\WHITE8X8")
        end
        stone:SetVertexColor(.48,.48,.53,.96)
        local shade=pane:CreateTexture(nil,"BORDER")
        shade:SetTexture("Interface\\Buttons\\WHITE8X8")
        shade:SetPoint("TOPLEFT",pane,"TOPLEFT",0,0)
        shade:SetPoint("BOTTOMRIGHT",pane,"BOTTOMRIGHT",0,0)
        shade:SetVertexColor(.012,.020,.035,.56)

        local top=pane:CreateTexture(nil,"ARTWORK")
        top:SetPoint("TOPLEFT",pane,"TOPLEFT",1,0)
        top:SetPoint("TOPRIGHT",pane,"TOPRIGHT",-1,0)
        top:SetHeight(3)
        top:SetTexture("Interface\\Buttons\\WHITE8X8")
        top:SetVertexColor(.50,.48,.37,.9)
        local corner=pane:CreateTexture(nil,"OVERLAY")
        corner:SetPoint("TOPLEFT",pane,"TOPLEFT",1,4)
        corner:SetWidth(565)
        corner:SetHeight(46)
        art(corner,pane==panelLeft and V.atlas.leftHeader or V.atlas.rightHeader)
        corner:SetAlpha(.75)

        local edge=pane:CreateTexture(nil,"OVERLAY")
        edge:SetTexture("Interface\\Buttons\\WHITE8X8")
        edge:SetVertexColor(.35,.38,.37,.75)
        edge:SetPoint("TOPLEFT",pane,"TOPLEFT",0,0)
        edge:SetPoint("BOTTOMLEFT",pane,"BOTTOMLEFT",0,0)
        edge:SetWidth(1)
        local bottom=pane:CreateTexture(nil,"OVERLAY")
        bottom:SetTexture("Interface\\Buttons\\WHITE8X8")
        bottom:SetVertexColor(.35,.38,.37,.75)
        bottom:SetPoint("BOTTOMLEFT",pane,"BOTTOMLEFT",0,0)
        bottom:SetPoint("BOTTOMRIGHT",pane,"BOTTOMRIGHT",0,0)
        bottom:SetHeight(1)
    end

    local separator=view:CreateTexture(nil,"ARTWORK")
    separator:SetPoint("TOP",view,"TOP",0,-58)
    separator:SetPoint("BOTTOM",view,"BOTTOM",0,72)
    separator:SetWidth(8)
    if not art(separator,V.atlas.vertical) then
        separator:SetTexture("Interface\\Buttons\\WHITE8X8")
        separator:SetVertexColor(.4,.33,.2,.85)
    end
    separator:SetAlpha(.85)
    V.treeCount=V.treeCount+2
    V.classPane=panelLeft
    V.specPane=panelRight
end

local function isEnabled(btn)
    if btn.IsEnabled then
        local ok,v=pcall(btn.IsEnabled,btn)
        if ok and (v==false or v==0) then return false end
    end
    return true
end

function V.StyleNode(button)
    if not button or not button.Icon then return false end
    if button.afForeverNodeStyled then return true end
    button.afForeverNodeStyled=true
    local icon=button.Icon
    -- The CoA Icon object supports a rounded mask in this custom client.
    -- A square node matches the modern Forever talent-tree screenshot.
    if type(icon.SetRounded)=="function" then pcall(icon.SetRounded,icon,false) end

    local trim=button:CreateTexture(nil,"OVERLAY")
    trim:SetPoint("TOPLEFT",button,"TOPLEFT",-3,3)
    trim:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",3,-3)
    if not art(trim,isEnabled(button) and V.atlas.nodeYellow or V.atlas.nodeGray) then
        trim:SetTexture("Interface\\Buttons\\WHITE8X8")
        trim:SetVertexColor(.62,.54,.35,.30)
    end
    trim:SetAlpha(.93)
    button.afForeverTrim=trim
    if button.HookScript then
        button:HookScript("OnEnable",function(self)
            art(self.afForeverTrim,V.atlas.nodeYellow)
        end)
        button:HookScript("OnDisable",function(self)
            art(self.afForeverTrim,V.atlas.nodeGray)
        end)
    end
    V.nodeCount=V.nodeCount+1
    return true
end

local function styleTreeChildren(node,depth,seen)
    if not node or depth>5 or seen[node] then return end
    seen[node]=true
    if node.GetObjectType and node:GetObjectType()=="Button"
       and node.Icon and (node.SetEntry or node.entry or node.Entry) then
        V.StyleNode(node)
    end
    if node.GetChildren then
        for _,child in ipairs({node:GetChildren()}) do
            styleTreeChildren(child,depth+1,seen)
        end
    end
end

function V.StyleExistingNodes()
    local c=_G.CoATalentFrame
    local view=c and c.TreeView
    if not view then return end
    local seen={}
    styleTreeChildren(view.ClassTree,0,seen)
    styleTreeChildren(view.SpecTree,0,seen)
end

local function hookCoAMixins()
    if not isCoA() then return end
    if type(hooksecurefunc)~="function" then return end
    local names={
        "CoATalentButtonMixin", "CoATalentButtonSquareMixin",
        "CoATalentButtonCircleMixin", "CoATalentButtonHexMixin",
        "CoATalentButtonDiamondMixin", "CoATalentChoiceButtonMixin"
    }
    for _,name in ipairs(names) do
        local mixin=_G[name]
        if mixin and not V.hooks[name] and type(mixin.SetEntry)=="function" then
            local ok=pcall(hooksecurefunc,mixin,"SetEntry",function(btn)
                V.StyleNode(btn)
            end)
            if ok then V.hooks[name]=true end
        end
    end
end

function V.Apply()
    if not isCoA() then return false end
    local root=_G.CoATalentFrame
    if not root or not root.TreeView then return false end
    local view=root.TreeView
    if not view.ClassTree or not view.SpecTree then return false end
    if not view.afForeverFullTreePanels then createPanels(view) end
    if view.Background1 and view.Background1.SetAlpha then
        view.Background1:SetAlpha(.22)
    end
    if view.Background2 and view.Background2.SetAlpha then
        view.Background2:SetAlpha(.03)
    end
    if view.Background3 and view.Background3.SetAlpha then
        view.Background3:SetAlpha(.02)
    end
    if view.ShadowOverlay and view.ShadowOverlay.SetAlpha then
        view.ShadowOverlay:SetAlpha(.25)
    end
    hookCoAMixins()
    V.StyleExistingNodes()
    return true
end

local f=CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent",function(self,event,name)
    if event=="PLAYER_LOGIN" or (event=="ADDON_LOADED"
       and (name=="Ascension_CoATalents" or name=="Ascension_Collections")) then
        V.Apply()
    end
end)
f.time=0
f:SetScript("OnUpdate",function(self,elapsed)
    if not isCoA() then return end
    self.time=self.time+(elapsed or 0)
    if self.time<1.2 then return end
    self.time=0
    local ok,errorText=pcall(V.Apply)
    if not ok then
        if V.lastError~=errorText then
            V.lastError=errorText
            note(errorText)
        end
    end
end)
