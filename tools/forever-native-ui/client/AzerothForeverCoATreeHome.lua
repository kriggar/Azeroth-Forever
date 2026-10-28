-- Azeroth Forever — real CoA Class/Spec talent tree home.
-- CLIENT FrameXML, not an added addon. The rejected four-card/side-rail
-- replacement is removed. We never render faux talent nodes or copy any
-- vanilla/WotLK talent IDs into the Conquest of Azeroth class systems.
--
-- Uses the original CoA:
--   CoATalentFrame.TreeView.ClassTree / .SpecTree (actual node links, ranks)
--   CoATreeViewMixin:SetSpecID (real class/spec client DBC talent graph)
--   CoASpecChoiceMixin:OnSelected (original specialization action)
--   C_CharacterAdvancement (validation, points and pending talents)
-- The only new control is a thin specialization tab row above both trees.

local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
local R = {}
AF.CoATreeHome = R
R.version = 4
R.specs = {}
R.buttons = {}
R.treesOpened = false
R.lastError = nil

local function explain(text)
    if AF.Notice then AF.Notice("CoA talent trees: " .. tostring(text)) end
end

local function isCoA()
    return type(IsCustomClass) == "function" and IsCustomClass()
end

local function readActiveSpec()
    local api = _G.C_CharacterAdvancement
    if api and type(api.GetActiveChrSpec) == "function" then
        local ok, id = pcall(api.GetActiveChrSpec)
        if ok then return id end
    end
end

local function choicesForClass()
    local cls = select(2, UnitClass("player"))
    local api = _G.C_ClassInfo
    local result = {}
    if not cls or not api or type(api.GetAllSpecs) ~= "function" or
        type(api.GetSpecInfo) ~= "function" then return result end
    local ok, names = pcall(api.GetAllSpecs, cls)
    if not ok or type(names) ~= "table" then return result end
    for _, value in ipairs(names) do
        local success, info = pcall(api.GetSpecInfo, cls, value)
        if success and type(info) == "table" and info.ID then
            table.insert(result, {
                id=info.ID,
                name=tostring(info.Name or info.Spec or value),
                info=info
            })
        end
    end
    return result
end
R.GetSpecs = choicesForClass

local function pickFirst(specs)
    if #specs == 0 then return nil end
    local active = readActiveSpec()
    if active then
        for _, spec in ipairs(specs) do
            if spec.id == active then return spec end
        end
    end
    if R.previewSpecID then
        for _, spec in ipairs(specs) do
            if spec.id == R.previewSpecID then return spec end
        end
    end
    return specs[1]
end

local function originalChoice(root, specId)
    local pool = root.SpecView and root.SpecView.SpecChoicePool
    if not pool or type(pool.EnumerateActive) ~= "function" then return nil end
    for original in pool:EnumerateActive() do
        if original and original.specInfo and original.specInfo.ID == specId then
            return original
        end
    end
end

local function applyOriginalSelection(root, spec)
    if not spec then return false end
    local chosen = originalChoice(root, spec.id)
    if not chosen or type(chosen.OnSelected) ~= "function" then
        explain("Original CoA specialization selection is unavailable; no talent change sent.")
        return false
    end
    local active = readActiveSpec()
    if not active and _G.C_CharacterAdvancement and
        type(C_CharacterAdvancement.CanSwitchActiveChrSpec) == "function" then
        local allowed, can = pcall(C_CharacterAdvancement.CanSwitchActiveChrSpec, spec.id)
        if not allowed or can == false then
            explain("This specialization is locked by the CoA server.")
            return false
        end
    end
    -- The original client method handles the real server message.
    local ok, err = pcall(chosen.OnSelected, chosen)
    if not ok then
        R.lastError = err
        explain(err)
        return false
    end
    return true
end

function R.Select(specId)
    local root = _G.CoATalentFrame
    if not root or not root.TreeView then return false end
    for _, s in ipairs(R.specs) do
        if s.id == specId then
            R.previewSpecID = specId
            R.UpdateTabs()
            -- Previewing updates only the visible client class/spec node map.
            -- It never commits, buys, resets or changes a CoA specialization.
            if root.TreeView.SetSpecID then
                local ok, err = pcall(root.TreeView.SetSpecID, root.TreeView, specId)
                if not ok then
                    R.lastError = err
                    explain("Could not display CoA talent graph: " .. tostring(err))
                    return false
                end
            end
            R.OpenTrees()
            -- Use a second click on an unchosen tab to commit? No: clicking
            -- a tab must preserve the exact old "Choose Talents" semantics.
            if readActiveSpec() ~= specId then
                return applyOriginalSelection(root, s)
            end
            return true
        end
    end
    return false
end

local function makeTab(parent, id, index)
    local btn = CreateFrame("Button","AzerothForeverCoASpecTab" .. index,
                            parent,"UIPanelButtonTemplate")
    btn:SetHeight(27)
    btn:SetWidth(160)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 20+(index-1)*169,-2)
    btn:SetScript("OnClick", function() R.Select(id) end)
    return btn
end

function R.CreateTabStrip(root)
    if R.tabStrip then return R.tabStrip end
    local tree = root.TreeView
    local strip = CreateFrame("Frame","AzerothForeverCoATreeTabs",tree)
    strip:SetHeight(33)
    strip:SetPoint("TOPLEFT",tree,"TOPLEFT",3,-2)
    strip:SetPoint("TOPRIGHT",tree,"TOPRIGHT",-4,-2)
    strip:SetFrameLevel(tree:GetFrameLevel()+30)
    strip:EnableMouse(false)
    R.tabStrip = strip

    local bg=strip:CreateTexture(nil,"BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetAllPoints(strip)
    bg:SetVertexColor(.028,.037,.05,.97)
    for index=1,7 do
        -- CoA class roster has different numbers of specializations.
        local tab=makeTab(strip,0,index)
        tab:Hide()
        R.buttons[index]=tab
    end
    R.info=strip:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    R.info:SetPoint("BOTTOMRIGHT",strip,"TOPRIGHT",-14,3)
    R.info:SetWidth(530)
    R.info:SetJustifyH("RIGHT")
    return strip
end

function R.UpdateTabs()
    if not R.tabStrip then return end
    local active = readActiveSpec()
    for i,button in ipairs(R.buttons) do
        local spec=R.specs[i]
        if spec then
            button:SetText((spec.id == active and "|cff88dd88" or "|cffdfc081")
                           .. spec.name .. "|r")
            -- A button labelled as a tab, not a giant spec preview card.
            button:SetScript("OnClick",function() R.Select(spec.id) end)
            button:Show()
        else
            button:Hide()
        end
    end
    if R.info then
        if active then
            R.info:SetText("CoA CLASS + SPECIALIZATION TALENTS | Original ranks and rules")
        else
            R.info:SetText("|cffffcc66Preview CoA talents | Choose a specialization above to activate|r")
        end
    end
end

local function safePreview(root, id)
    local tree=root.TreeView
    if not tree or type(tree.SetSpecID) ~= "function" then return false end
    local success, err=pcall(tree.SetSpecID,tree,id)
    if not success then
        R.lastError=err
        explain("The original CoA talent data could not load: "..tostring(err))
    end
    return success
end

-- This is the critical change: bring the actual CoA node-and-arrow tree
-- window directly to the foreground on N/Talents, never the old card chooser.
function R.OpenTrees()
    if not isCoA() then return false end
    local root=_G.CoATalentFrame
    if not root or not root.TreeView or not root.SpecView then return false end
    if not _G.C_CharacterAdvancement then return false end
    if not R.tabStrip then R.CreateTabStrip(root) end
    if #R.specs==0 then R.specs=choicesForClass() end
    local spec=pickFirst(R.specs)
    if not spec then return false end
    if not safePreview(root,spec.id) then return false end

    -- CoA TreeView contains live TalentTreeBase nodes, prerequisite links,
    -- ranks and original pending-build handlers. It is not a fake redrawn
    -- talent tree. This is the ONLY view player opens for CoA talents.
    if root.SpecView:IsShown() then root.SpecView:Hide() end
    if not root.TreeView:IsShown() then
        local ok, err=pcall(root.TreeView.Show,root.TreeView)
        if not ok then
            R.lastError=err
            explain("The original CoA talent panel reported: "..tostring(err))
            return false
        end
    end
    R.treesOpened=true
    R.UpdateTabs()
    if not readActiveSpec() then
        -- The backend has not selected a specialization yet; we show the
        -- actual node graph as a PREVIEW but do not allow fake spending.
        local bottom=root.TreeView.BottomBar
        if bottom and bottom.SaveChanges then bottom.SaveChanges:Disable() end
    end
    local skin=AF.CoATalents
    if skin then
        if type(skin.Style)=="function" then pcall(skin.Style) end
        if type(skin.Fit)=="function" then pcall(skin.Fit) end
    end
    return true
end

function R.Attach()
    if not isCoA() then return false end
    local root=_G.CoATalentFrame
    if not root or not root.TreeView or not root.SpecView then return false end
    if R.attached == root then return true end
    R.attached=root
    R.specs=choicesForClass()
    R.CreateTabStrip(root)
    root:HookScript("OnShow",function()
        local ok,err=pcall(R.OpenTrees)
        if not ok then R.lastError=err; explain(err) end
    end)
    root.SpecView:HookScript("OnShow",function()
        local ok,err=pcall(R.OpenTrees)
        if not ok then R.lastError=err; explain(err) end
    end)
    if root:IsShown() then
        local ok,err=pcall(R.OpenTrees)
        if not ok then R.lastError=err; explain(err) end
    end
    return true
end

local watcher=CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
watcher:SetScript("OnEvent",function(self,event,name)
    if event=="ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED" then
        R.UpdateTabs()
        return
    end
    if event=="PLAYER_LOGIN" or (event=="ADDON_LOADED" and
        (name=="Ascension_CoATalents" or name=="Ascension_Collections")) then
        R.Attach()
    end
end)
watcher.elapsed=0
watcher:SetScript("OnUpdate",function(self,elapsed)
    if R.attached then self:SetScript("OnUpdate",nil); return end
    self.elapsed=self.elapsed+(elapsed or 0)
    if self.elapsed>=0.8 then
        self.elapsed=0
        R.Attach()
    end
end)
