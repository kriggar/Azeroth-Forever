AzerothForeverCoATalents = AzerothForeverCoATalents or {}
local UI = AzerothForeverCoATalents

local WIDTH, HEIGHT = 916, 684
local GUTTER, COLUMN_WIDTH = 17, 433
local COLUMN_TOP, COLUMN_HEIGHT = -35, 573
local GOLD = { 0.78, 0.57, 0.21 }
local PORTRAITS = {
    ["Moon Priest"] = "moon_priest",
    ["Sentinel"] = "sentinel",
    ["Warden"] = "warden",
    ["Moon Guard"] = "moon_guard",
}
local ART_PATH = "Interface\\AzerothForever\\Talents\\"

local function Backdrop(frame, r, g, b)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 13,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    frame:SetBackdropColor(0.025, 0.028, 0.035, 0.97)
    frame:SetBackdropBorderColor(r or GOLD[1], g or GOLD[2], b or GOLD[3], 1)
end

local function Text(frame, value, style, anchor, x, y)
    local label = frame:CreateFontString(nil, "OVERLAY", style or "GameFontNormal")
    label:SetPoint(anchor or "CENTER", frame, anchor or "CENTER", x or 0, y or 0)
    label:SetText(value or "")
    return label
end

local function SetArt(texture, classToken, specToken, fallback)
    if not texture then return end
    local art = fallback
    if CharacterAdvancementUtil and CharacterAdvancementUtil.GetBackgroundAtlas then
        art = CharacterAdvancementUtil.GetBackgroundAtlas(classToken, specToken) or fallback
    end
    if art and texture.SetAtlas then
        texture:SetAtlas(art)
    elseif texture.SetTexture then
        texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    end
end

local function CreatePane(parent, offset)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", offset, COLUMN_TOP)
    panel:SetSize(COLUMN_WIDTH, COLUMN_HEIGHT)
    Backdrop(panel)
    panel:SetFrameLevel(parent:GetFrameLevel() + 1)

    panel.art = panel:CreateTexture(nil, "BACKGROUND")
    panel.art:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -43)
    panel.art:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
    panel.art:SetAlpha(0.69)

    panel.shadow = panel:CreateTexture(nil, "BORDER")
    panel.shadow:SetTexture("Interface\\Buttons\\WHITE8X8")
    panel.shadow:SetVertexColor(0.015, 0.017, 0.03, 0.42)
    panel.shadow:SetPoint("TOPLEFT", panel.art)
    panel.shadow:SetPoint("BOTTOMRIGHT", panel.art)

    panel.header = CreateFrame("Frame", nil, panel)
    panel.header:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -3)
    panel.header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3)
    panel.header:SetHeight(37)
    Backdrop(panel.header, 0.45, 0.32, 0.13)
    panel.header:SetBackdropColor(0.035, 0.027, 0.016, 0.97)
    panel.name = Text(panel.header, "", "GameFontNormalLarge", "LEFT", 12, 0)
    panel.points = Text(panel.header, "", "GameFontHighlight", "RIGHT", -12, 0)
    return panel
end

local function PositionTree(tree, panel)
    tree:ClearAllPoints()
    tree:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -82)
    tree:SetSize(COLUMN_WIDTH - 40, COLUMN_HEIGHT - 102)
    tree:SetFrameLevel(panel:GetFrameLevel() + 8)
    tree:SetAttribute("buttonWidth", 33)
    tree:SetAttribute("buttonHeight", 33)
    tree:SetAttribute("buttonSpacingX", 13)
    tree:SetAttribute("buttonSpacingY", 8)
    if tree.Label then tree.Label:Hide() end
    if tree.Points then tree.Points:Hide() end
    if tree.MarkDirty and TalentTreeBaseMixin then
        tree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Nodes)
    end
end

local function ApplyCardArtwork(card)
    if not card.specInfo or card.specInfo.Class ~= "STARCALLER" then return end
    local asset = PORTRAITS[card.specInfo.Name]
    if asset and card.Banner and card.Banner.Image then
        card.Banner.Image:SetTexture(ART_PATH .. asset)
        if card.Banner.ImageHover then
            card.Banner.ImageHover:SetTexture(ART_PATH .. asset)
        end
    end
end

function UI:ArrangeSpecCards()
    local root = self.root
    if not root or not root.SpecView or not root.SpecView.SpecChoicePool then return end

    local view = root.SpecView
    local choices = {}
    local classToken = select(2, UnitClass("player"))
    local specTokens = C_ClassInfo.GetAllSpecs(classToken) or {}
    for card in view.SpecChoicePool:EnumerateActive() do
        if card and card.specInfo then
            choices[card.specInfo.Spec] = card
        end
    end
    local count = #specTokens
    if count == 0 then return end
    local gap = count > 4 and 6 or 10
    local available = WIDTH - 36
    local columnWidth = (available - gap * (count - 1)) / count
    local cardHeight = HEIGHT - 125
    for index, token in ipairs(specTokens) do
        local card = choices[token]
        local info = C_ClassInfo.GetSpecInfo(classToken, token)
        if card and info then
            if not card.afLayoutConfigured then
                card:ClearAllPoints()
                card:SetPoint("TOPLEFT", view, "TOPLEFT", 17 + (index - 1) * (columnWidth + gap), -52)
                card:SetSpecInfo(info, columnWidth, cardHeight, index == 1, index == count)
                Backdrop(card, 0.59, 0.43, 0.17)
                if card.ColumnDivider then card.ColumnDivider:Hide() end
                if card.Banner then
                    card.Banner:ClearAllPoints()
                    card.Banner:SetPoint("TOP", card, "TOP", 0, -20)
                    card.Banner:SetSize(math.max(90, columnWidth - 22), 171)
                    ApplyCardArtwork(card)
                end
                if card.SpecInfo then
                    card.SpecInfo:SetWidth(columnWidth - 18)
                    card.SpecInfo:SetAttribute("fixedWidth", columnWidth - 18)
                    if card.SpecInfo.Name and card.SpecInfo.Name.SetFont then
                        card.SpecInfo.Name:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
                    end
                    if card.SpecInfo.Description then
                        card.SpecInfo.Description:SetWidth(columnWidth - 28)
                    end
                    card.SpecInfo:MarkDirty()
                end
                if card.SampleAbilities then card.SampleAbilities:SetScale(0.81) end
                if card.SelectButton then
                    card.SelectButton:SetSize(columnWidth - 22, 27)
                    card.SelectButton:ClearAllPoints()
                    card.SelectButton:SetPoint("BOTTOM", card, "BOTTOM", 0, 19)
                end
                card.afLayoutConfigured = true
            end
            if card.UpdateVisualState then
                card:UpdateVisualState(card:GetSpecID() == C_CharacterAdvancement.GetActiveChrSpec())
            end
        end
    end
end

function UI:Refresh()
    local root, view = self.root, self.view
    if not root or not view or not root:IsShown() then return end
    local specID = C_CharacterAdvancement.GetActiveChrSpec()
    local specInfo = specID and C_ClassInfo.GetSpecInfoByID(specID)
    if not specInfo then return end

    if self.lastSpecID ~= specID then
        self.lastSpecID = specID
        SetArt(self.left.art, specInfo.Class, specInfo.Spec)
        SetArt(self.right.art, specInfo.Class, specInfo.Spec)
        self.left.art:SetVertexColor(0.62, 0.82, 1.0, 1)
        self.right.art:SetVertexColor(0.95, 0.68, 1.0, 1)
    end

    local spentClass = C_CharacterAdvancement.GetPendingTabAEInvestment() or 0
    local spentSpec = C_CharacterAdvancement.GetPendingTabTEInvestment() or 0
    local remainClass = C_CharacterAdvancement.GetPendingRemainingAE() or 0
    local remainSpec = C_CharacterAdvancement.GetPendingRemainingTE() or 0
    self.left.name:SetText(specInfo.Name)
    self.right.name:SetText(specInfo.Name .. " Talents")
    self.left.points:SetText(spentClass .. " / " .. (spentClass + remainClass))
    self.right.points:SetText(spentSpec .. " / " .. (spentSpec + remainSpec))
    self.pointsRemaining:SetText("Points remaining: " .. (remainClass + remainSpec))
    if C_CharacterAdvancement.IsPending() then
        self.pendingNotice:SetText("Unapplied changes")
    else
        self.pendingNotice:SetText("")
    end
end

function UI:DisplaySpecializations()
    if not self.root then return end
    self.root:ShowSpecView()
    self:ArrangeSpecCards()
end

function UI:Install()
    if self.root then return true end
    local root = CoATalentFrame
    if not root or not root.SpecView or not root.TreeView or not root.TreeView.ClassTree
        or not root.TreeView.SpecTree or not root.TreeView.BottomBar
        or not CharacterAdvancementUtil or not C_CharacterAdvancement or not C_ClassInfo then
        return false
    end
    self.root, self.view = root, root.TreeView
    local view = root.TreeView
    root:SetSize(WIDTH, HEIGHT)
    root:ClearAllPoints()
    root:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if UIParent and UIParent.GetWidth and UIParent.GetHeight then
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        if width and height and width > 0 and height > 0 then
            root:SetScale(math.min(1, width / (WIDTH + 30), height / (HEIGHT + 30)))
        end
    end
    if PortraitFrame_SetTitle then PortraitFrame_SetTitle(root, "Talents") end

    root.SpecView:ClearAllPoints()
    root.SpecView:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -24)
    root.SpecView:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0)
    view:ClearAllPoints()
    view:SetPoint("TOPLEFT", root, "TOPLEFT", 2, -24)
    view:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -2, 2)
    for _, name in ipairs({"Background1", "Background2", "Background3", "FXFrame", "ShadowOverlay"}) do
        if view[name] then view[name]:SetAlpha(0) end
    end

    self.left = CreatePane(view, GUTTER)
    self.right = CreatePane(view, GUTTER + COLUMN_WIDTH + 12)
    PositionTree(view.ClassTree, self.left)
    PositionTree(view.SpecTree, self.right)

    self.selectionTitle = Text(root.SpecView, "Choose a Conquest of Azeroth specialization",
        "GameFontHighlightLarge", "TOP", 0, -15)
    local bar = view.BottomBar
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    bar:SetHeight(54)

    if bar.SaveChanges then
        bar.SaveChanges:ClearAllPoints()
        bar.SaveChanges:SetPoint("RIGHT", bar, "RIGHT", -15, 0)
        bar.SaveChanges:SetSize(139, 24)
        bar.SaveChanges:SetText("Save Changes")
    end
    if bar.Search then
        bar.Search:ClearAllPoints()
        bar.Search:SetPoint("LEFT", bar, "LEFT", 118, 0)
        bar.Search:SetSize(162, 22)
    end
    if bar.UndoButton then
        bar.UndoButton:ClearAllPoints()
        bar.UndoButton:SetPoint("RIGHT", bar.SaveChanges, "LEFT", -8, 0)
    end
    if bar.ResetButton then
        bar.ResetButton:ClearAllPoints()
        bar.ResetButton:SetPoint("LEFT", bar, "LEFT", 15, 0)
        bar.ResetButton:SetAlpha(0)
        bar.ResetButton:EnableMouse(false)
    end
    self.resetText = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    self.resetText:SetPoint("LEFT", bar, "LEFT", 15, 0)
    self.resetText:SetSize(84, 24)
    self.resetText:SetText("Reset")
    self.resetText:SetScript("OnClick", function()
        if C_CharacterAdvancement.IsPending() then
            if UIErrorsFrame then
                UIErrorsFrame:AddMessage("Save or discard pending changes before resetting", 1, 0.4, 0.3)
            end
        else
            view:ShowResetDropDown()
        end
    end)
    self.pointsRemaining = Text(bar, "Points remaining: 0", "GameFontNormal", "CENTER", 42, 0)
    self.pendingNotice = Text(bar, "", "GameFontHighlightSmall", "CENTER", 52, 17)
    self.pendingNotice:SetTextColor(1, 0.52, 0.22)

    if bar.ChangeSpec then
        bar.ChangeSpec:ClearAllPoints()
        bar.ChangeSpec:SetPoint("TOPRIGHT", root, "TOPRIGHT", -45, -34)
        bar.ChangeSpec:SetSize(148, 22)
        bar.ChangeSpec:SetText("Change Talents")
    end
    for _, key in ipairs({"SpecDropDown", "BuildDropDown", "ShareBuildButton", "ImportBuildButton"}) do
        if bar[key] then
            bar[key]:Hide()
            bar[key]:EnableMouse(false)
        end
    end

    root:HookScript("OnShow", function()
        UI:ArrangeSpecCards()
        UI:Refresh()
    end)
    root.SpecView:HookScript("OnShow", function() UI:ArrangeSpecCards() end)
    view:HookScript("OnShow", function() UI:Refresh() end)
    return true
end

local driver = CreateFrame("Frame")
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP",
    "CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED", "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED",
    "ASCENSION_KNOWN_ENTRY_UPDATED", "ASCENSION_KNOWN_ENTRY_REMOVED",
    "CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT",
}) do
    driver:RegisterEvent(event)
end
driver:SetScript("OnEvent", function(_, event)
    if not UI.root then UI:Install() end
    if UI.root and event ~= "ADDON_LOADED" then UI:Refresh() end
end)
