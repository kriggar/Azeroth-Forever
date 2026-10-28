AzerothForeverTalents = AzerothForeverTalents or {}

local UI = AzerothForeverTalents
local PANEL_WIDTH = 382
local PANEL_HEIGHT = 598
local PANEL_START = 209
local PANEL_GAP = 12
local PANEL_TOP = -28
local GOLD = { 0.96, 0.77, 0.28 }

local function Border(frame, r, g, b)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.025, 0.03, 0.04, 0.96)
    frame:SetBackdropBorderColor(r or 0.48, g or 0.35, b or 0.13, 1)
end

local function Label(parent, value, template, point, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    label:SetPoint(point or "CENTER", parent, point or "CENTER", x or 0, y or 0)
    label:SetText(value)
    return label
end

local function Place(parent, left, top, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
    frame:SetSize(width, height)
    return frame
end

local function SelectNavigation(button, selected)
    if selected then
        button:SetBackdropColor(0.30, 0.22, 0.025, 0.97)
        button:SetBackdropBorderColor(1, 0.78, 0.18, 1)
        button.text:SetTextColor(1, 0.85, 0.28)
    else
        button:SetBackdropColor(0.035, 0.04, 0.06, 0.97)
        button:SetBackdropBorderColor(0.46, 0.34, 0.14, 1)
        button.text:SetTextColor(0.93, 0.73, 0.23)
    end
end

local function NavigationButton(parent, title, row, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -74 - row * 47)
    button:SetSize(157, 42)
    Border(button)
    button.text = Label(button, title, "GameFontNormalLarge")
    button:SetScript("OnClick", callback)
    SelectNavigation(button, false)
    return button
end

local function PanelLeft(index)
    return PANEL_START + (index - 1) * (PANEL_WIDTH + PANEL_GAP)
end

local function TreePanel(parent, index)
    local panel = Place(parent, PanelLeft(index), PANEL_TOP, PANEL_WIDTH, PANEL_HEIGHT)
    Border(panel, 0.65, 0.49, 0.18)

    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -53)
    background:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3, 3)
    background:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    background:SetVertexColor(0.67, 0.6, 0.42, 1)
    panel.background = background

    local header = CreateFrame("Button", nil, panel)
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -3)
    header:SetSize(PANEL_WIDTH - 6, 46)
    Border(header, 0.41, 0.32, 0.16)
    panel.header = header
    panel.name = Label(header, "Talents", "GameFontNormalLarge", "LEFT", 12, 0)
    panel.points = Label(header, "0 / 51", "GameFontHighlight", "RIGHT", -14, 0)

    panel.active = Label(panel, "", "GameFontHighlightSmall", "TOP", 0, -60)
    panel.active:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    return panel
end

local function MoveTree(tree, view, index)
    tree:ClearAllPoints()
    tree:SetPoint("TOPLEFT", view, "TOPLEFT", PanelLeft(index) + 16, PANEL_TOP - 87)
    tree:SetSize(PANEL_WIDTH - 32, PANEL_HEIGHT - 126)
    tree:Show()
end

local function Background(panel, classToken, specToken)
    if panel and CharacterAdvancementUtil and type(CharacterAdvancementUtil.GetBackgroundAtlas) == "function" then
        local atlas = CharacterAdvancementUtil.GetBackgroundAtlas(classToken, specToken)
        if atlas then
            panel.background:SetAtlas(atlas)
            panel.background:SetAlpha(0.72)
        end
    end
end

local function AllSpecs(classToken)
    local result = {}
    local tokens = C_ClassInfo.GetAllSpecs(classToken) or {}
    for _, token in ipairs(tokens) do
        local info = C_ClassInfo.GetSpecInfo(classToken, token)
        if info and info.ID then
            table.insert(result, info)
        end
    end
    return result
end

local function OtherSpec(specs, activeID, preferredID, advance)
    local alternatives = {}
    for _, info in ipairs(specs) do
        if info.ID ~= activeID then
            table.insert(alternatives, info)
        end
    end
    if #alternatives == 0 then
        return nil
    end
    local selected = 1
    for i, info in ipairs(alternatives) do
        if info.ID == preferredID then
            selected = i
            break
        end
    end
    if advance then
        selected = (selected % #alternatives) + 1
    end
    return alternatives[selected]
end

local function ConfigureTree(tree)
    tree:SetAttribute("buttonWidth", 39)
    tree:SetAttribute("buttonHeight", 39)
    tree:SetAttribute("buttonSpacingX", 13)
    tree:SetAttribute("buttonSpacingY", 12)
    if tree.Label then tree.Label:Hide() end
    if tree.Points then tree.Points:Hide() end
    if tree.MarkDirty and TalentTreeBaseMixin then
        tree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Nodes)
    end
end

function UI:ChangeAlternative()
    if not self.root then return end
    local classToken = select(2, UnitClass("player"))
    local activeID = C_CharacterAdvancement.GetActiveChrSpec()
    local nextSpec = OtherSpec(AllSpecs(classToken), activeID, self.alternativeID, true)
    if nextSpec then
        self.alternativeID = nextSpec.ID
        self:Refresh()
    end
end

function UI:ActivatePanel(index)
    local target = self.panelSpecs[index]
    if not target or not self.root then return end
    if target.ID == C_CharacterAdvancement.GetActiveChrSpec() then return end

    if C_CharacterAdvancement.IsPending() then
        if UIErrorsFrame then
            UIErrorsFrame:AddMessage("Apply or undo your pending talents before changing specialization", 1, 0.35, 0.23)
        end
        return
    end
    if type(C_CharacterAdvancement.CanSwitchActiveChrSpec) == "function"
        and not C_CharacterAdvancement.CanSwitchActiveChrSpec(target.ID) then
        if UIErrorsFrame then
            UIErrorsFrame:AddMessage("This specialization is not available", 1, 0.35, 0.23)
        end
        return
    end

    self.previousSpecID = C_CharacterAdvancement.GetActiveChrSpec()
    self.requestedSpecID = target.ID
    self.requestedPanelIndex = index
    self.root:ChangeSpecID(target.ID)
end

function UI:ShowPage(page)
    if not self.root then return end
    self.page = page
    SelectNavigation(self.navigation.specialization, page == "specialization")
    SelectNavigation(self.navigation.talents, page == "talents")
    SelectNavigation(self.navigation.glyphs, page == "glyphs")
    if page == "specialization" then
        self.root:ShowSpecView()
    elseif page == "glyphs" then
        if type(IsAddOnLoaded) == "function" and not IsAddOnLoaded("Blizzard_GlyphUI")
            and type(LoadAddOn) == "function" then
            pcall(LoadAddOn, "Blizzard_GlyphUI")
        end
        if type(ToggleGlyphFrame) == "function" then
            ToggleGlyphFrame()
        elseif GlyphFrame and type(ShowUIPanel) == "function" then
            ShowUIPanel(GlyphFrame)
        elseif UIErrorsFrame then
            UIErrorsFrame:AddMessage("Glyphs are unavailable on this client", 1, 0.35, 0.23)
        end
        self.root:ShowTreeView()
    else
        self.root:ShowTreeView()
    end
end

function UI:Refresh()
    if not self.root or not self.root:IsShown() then return end
    local classToken = select(2, UnitClass("player"))
    local activeID = C_CharacterAdvancement.GetActiveChrSpec()
    local active = activeID and C_ClassInfo.GetSpecInfoByID(activeID)
    if not classToken or not active then return end

    if self.requestedSpecID and active.ID == self.requestedSpecID then
        self.activePanelIndex = self.requestedPanelIndex
        self.alternativeID = self.previousSpecID
        self.requestedSpecID = nil
        self.requestedPanelIndex = nil
        self.previousSpecID = nil
    elseif self.lastActiveSpecID and activeID ~= self.lastActiveSpecID then
        self.activePanelIndex = 2
        self.alternativeID = self.lastActiveSpecID
    end
    self.lastActiveSpecID = activeID

    local specs = AllSpecs(classToken)
    local other = OtherSpec(specs, activeID, self.alternativeID, false)
    if other then self.alternativeID = other.ID end
    local currentIndex = self.activePanelIndex or 2
    local otherIndex = currentIndex == 2 and 3 or 2
    self.panelSpecs = { [currentIndex] = active, [otherIndex] = other }

    local classSpent = C_CharacterAdvancement.GetPendingTabAEInvestment() or 0
    local specSpent = C_CharacterAdvancement.GetPendingTabTEInvestment() or 0
    local classRemaining = C_CharacterAdvancement.GetPendingRemainingAE() or 0
    local specRemaining = C_CharacterAdvancement.GetPendingRemainingTE() or 0

    local className = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken] or classToken
    self.panels[1].name:SetText(className)
    self.panels[1].points:SetText(classSpent .. " / " .. (classSpent + classRemaining))
    self.panels[1].active:SetText("CLASS TALENTS")
    Background(self.panels[1], classToken, active.Spec)

    local activePanel = self.panels[currentIndex]
    activePanel.name:SetText(active.Name)
    activePanel.points:SetText(specSpent .. " / " .. (specSpent + specRemaining))
    activePanel.active:SetText("ACTIVE SPECIALIZATION")
    Background(activePanel, classToken, active.Spec)
    activePanel.header:SetScript("OnClick", nil)
    activePanel.header:SetBackdropBorderColor(1, 0.78, 0.18, 1)
    MoveTree(self.view.SpecTree, self.view, currentIndex)

    local otherPanel = self.panels[otherIndex]
    if other then
        otherPanel.name:SetText(other.Name)
        otherPanel.points:SetText("Select")
        otherPanel.active:SetText("CLICK TO SWITCH AND EDIT")
        Background(otherPanel, classToken, other.Spec)
        otherPanel.header:SetScript("OnClick", function() UI:ActivatePanel(otherIndex) end)
        otherPanel.header:SetBackdropBorderColor(0.52, 0.38, 0.14, 1)
        MoveTree(self.alternativeTree, self.view, otherIndex)
        local classDBC = CharacterAdvancementUtil.GetClassDBCByFile(classToken)
        local specDBC = CharacterAdvancementUtil.GetSpecDBCByFile(other.Spec)
        if classDBC and specDBC and self.alternativeTreeSpec ~= other.Spec then
            self.alternativeTree:SetClassTab(classDBC, specDBC)
            self.alternativeTreeSpec = other.Spec
        end
        self.alternativeTree:Show()
        self.alternativeClick:ClearAllPoints()
        self.alternativeClick:SetPoint("TOPLEFT", otherPanel, "TOPLEFT", 3, -50)
        self.alternativeClick:SetPoint("BOTTOMRIGHT", otherPanel, "BOTTOMRIGHT", -3, 3)
        self.alternativeClick:Show()
        self.nextButton:ClearAllPoints()
        self.nextButton:SetPoint("BOTTOMRIGHT", otherPanel, "BOTTOMRIGHT", -9, 9)
        self.nextButton:SetShown(#specs > 2)
    else
        otherPanel.name:SetText("No Other Specialization")
        otherPanel.points:SetText("")
        otherPanel.active:SetText("")
        otherPanel.header:SetScript("OnClick", nil)
        self.alternativeTree:Hide()
        self.alternativeClick:Hide()
        self.nextButton:Hide()
    end
    MoveTree(self.view.ClassTree, self.view, 1)

    if self.pointsText then
        self.pointsText:SetText("Talent Points: " .. tostring(classRemaining + specRemaining))
    end
end

function UI:Install()
    if self.root then return true end
    if not CoATalentFrame or not CoATalentFrame.TreeView or
        not CoATalentFrame.TreeView.ClassTree or not CoATalentFrame.TreeView.SpecTree or
        not CoATalentFrame.TreeView.BottomBar or not CharacterAdvancementUtil or
        not C_CharacterAdvancement or not C_ClassInfo then
        return false
    end

    self.root = CoATalentFrame
    self.view = self.root.TreeView
    self.panels = {}
    self.navigation = {}
    self.panelSpecs = {}
    self.page = "talents"
    self.activePanelIndex = 2
    local root, view, bar = self.root, self.view, self.view.BottomBar

    root:SetSize(1437, 728)
    root:ClearAllPoints()
    root:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if UIParent:GetWidth() and UIParent:GetHeight() then
        root:SetScale(math.min(1, UIParent:GetWidth() / 1480, UIParent:GetHeight() / 765))
    end
    if PortraitFrame_SetTitle then PortraitFrame_SetTitle(root, "Talents") end

    view:ClearAllPoints()
    view:SetPoint("TOPLEFT", root, "TOPLEFT", 1, -24)
    view:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -1, 1)
    for _, key in ipairs({ "Background1", "Background2", "Background3", "FXFrame", "ShadowOverlay" }) do
        if view[key] then
            view[key]:Hide()
            if view[key].SetAlpha then view[key]:SetAlpha(0) end
        end
    end

    local sidebar = Place(root, 5, -55, 186, 594)
    Border(sidebar, 0.68, 0.49, 0.15)
    self.sidebar = sidebar
    self.navigation.specialization = NavigationButton(sidebar, "Specialization", 0, function()
        UI:ShowPage("specialization")
    end)
    self.navigation.talents = NavigationButton(sidebar, "Talents", 1, function()
        UI:ShowPage("talents")
    end)
    self.navigation.glyphs = NavigationButton(sidebar, "Glyphs", 2, function()
        UI:ShowPage("glyphs")
    end)
    Label(sidebar, "CHARACTER ADVANCEMENT", "GameFontNormalSmall", "TOP", 0, -22)
    Label(sidebar, "Select a specialization\nto spend its talents.", "GameFontHighlightSmall", "TOP", 0, -286)

    for index = 1, 3 do
        self.panels[index] = TreePanel(view, index)
    end
    self.panels[1].header:SetScript("OnClick", function() UI:ShowPage("talents") end)

    for _, tree in ipairs({ view.ClassTree, view.SpecTree }) do
        ConfigureTree(tree)
    end
    self.alternativeTree = CreateFrame("Frame", nil, view, "TalentTreeBase")
    for _, attribute in ipairs({
        "getNodeTemplate", "getChoiceNodeTemplate", "getConnectionTemplate", "useGates", "onlyOneGate",
        "getGateTemplate", "getGateAttachmentPoint", "gateCurrency", "gateCurrencyCount", "getEntryGateRequirement",
    }) do
        local value = view.SpecTree:GetAttribute(attribute)
        if value ~= nil then
            self.alternativeTree:SetAttribute(attribute, value)
        end
    end
    ConfigureTree(self.alternativeTree)
    self.alternativeClick = CreateFrame("Button", nil, view)
    self.alternativeClick:SetFrameLevel(self.alternativeTree:GetFrameLevel() + 15)
    self.alternativeClick:SetScript("OnClick", function()
        local index = UI.activePanelIndex == 2 and 3 or 2
        UI:ActivatePanel(index)
    end)
    self.alternativeClick:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_CURSOR")
        GameTooltip:SetText("Activate this specialization", GOLD[1], GOLD[2], GOLD[3])
        GameTooltip:AddLine("Click to switch here and spend real talent points.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    self.alternativeClick:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.nextButton = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
    self.nextButton:SetSize(89, 20)
    self.nextButton:SetText("Next Spec")
    self.nextButton:SetFrameLevel(self.alternativeClick:GetFrameLevel() + 2)
    self.nextButton:SetScript("OnClick", function() UI:ChangeAlternative() end)

    bar:ClearAllPoints()
    bar:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    bar:SetHeight(53)
    if bar.SaveChanges then
        bar.SaveChanges:ClearAllPoints()
        bar.SaveChanges:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -27, 16)
        bar.SaveChanges:SetText("Apply Changes")
    end
    for _, key in ipairs({ "UndoButton", "ResetButton" }) do
        if bar[key] then
            bar[key]:ClearAllPoints()
            bar[key]:SetPoint("RIGHT", bar.SaveChanges, "LEFT", -14, 0)
        end
    end
    if bar.Search then
        bar.Search:ClearAllPoints()
        bar.Search:SetPoint("CENTER", bar, "CENTER", -30, -8)
    end
    if bar.ChangeSpec then bar.ChangeSpec:Hide() end
    if bar.SpecDropDown then
        bar.SpecDropDown:ClearAllPoints()
        bar.SpecDropDown:SetPoint("TOPLEFT", sidebar, "TOPLEFT", -9, -350)
        bar.SpecDropDown:SetFrameLevel(sidebar:GetFrameLevel() + 4)
    end
    if bar.BuildDropDown then
        bar.BuildDropDown:ClearAllPoints()
        bar.BuildDropDown:SetPoint("TOPLEFT", sidebar, "TOPLEFT", -9, -407)
        bar.BuildDropDown:SetFrameLevel(sidebar:GetFrameLevel() + 4)
    end
    for key, offset in pairs({ ShareBuildButton = -476, ImportBuildButton = -508 }) do
        if bar[key] then
            bar[key]:SetParent(sidebar)
            bar[key]:ClearAllPoints()
            bar[key]:SetPoint("TOP", sidebar, "TOP", 0, offset)
            bar[key]:SetWidth(160)
        end
    end
    self.pointsText = Label(bar, "Talent Points: 0", "GameFontHighlight", "LEFT", 20, 0)
    self.resetAll = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    self.resetAll:SetSize(106, 24)
    self.resetAll:SetPoint("LEFT", bar, "LEFT", 260, 0)
    self.resetAll:SetText("Reset All")
    self.resetAll:SetScript("OnClick", function()
        if C_CharacterAdvancement and type(C_CharacterAdvancement.ClearPendingBuild) == "function"
            and Const and Const.CharacterAdvancement then
            C_CharacterAdvancement.ClearPendingBuild(Const.CharacterAdvancement.OnlyClearAllowed)
            UI:Refresh()
        end
    end)
    SelectNavigation(self.navigation.talents, true)

    root:HookScript("OnShow", function() UI:Refresh() end)
    view:HookScript("OnShow", function()
        UI.page = "talents"
        for name, button in pairs(UI.navigation) do
            SelectNavigation(button, name == "talents")
        end
        UI:Refresh()
    end)
    return true
end

local driver = CreateFrame("Frame")
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_LOGIN", "CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED",
    "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED", "ASCENSION_KNOWN_ENTRY_UPDATED",
    "ASCENSION_KNOWN_ENTRY_REMOVED", "CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT",
}) do
    driver:RegisterEvent(event)
end
driver:SetScript("OnEvent", function(_, event)
    if not UI.root then UI:Install() end
    if UI.root and event ~= "ADDON_LOADED" then UI:Refresh() end
end)
