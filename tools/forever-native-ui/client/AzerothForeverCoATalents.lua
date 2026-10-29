local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
local R = {version=6}
AF.CoATalents = R

local function isCoA()
    return type(IsCustomClass) == "function" and IsCustomClass()
end

local function fail(text)
    R.lastError = tostring(text)
    if AF.Notice then AF.Notice("CoA talents: " .. R.lastError) end
end

function R.HasOriginalHandlers(root)
    if not root or not root.TreeView or not root.SpecView then return false end
    local view = root.TreeView
    local bar = view.BottomBar
    if not view.ClassTree or not view.SpecTree or not bar then return false end
    if not bar.SaveChanges or not bar.UndoButton or not bar.ChangeSpec or not bar.Search then return false end
    local api = _G.C_CharacterAdvancement
    return api and type(api.GetActiveChrSpec) == "function" and type(api.CanApplyPendingBuild) == "function"
end

local function textStyle(tree)
    local label, points = tree.Label, tree.Points
    if label then
        label:SetAlpha(1)
        label:SetFontObject(GameFontNormalLarge)
        label:SetTextColor(1, 0.85, 0.53)
        label:ClearAllPoints()
        label:SetPoint("BOTTOM", tree, "TOP", 0, 60)
    end
    if points then
        points:SetAlpha(1)
        points:SetFontObject(GameFontHighlightSmall)
        points:SetTextColor(0.88, 0.74, 0.37)
        points:ClearAllPoints()
        points:SetPoint("TOP", label or tree, "BOTTOM", 0, -4)
    end
end

local function headerLine(view, fraction)
    local line = view:CreateTexture(nil, "OVERLAY")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(0.6, 0.5, 0.32, 0.75)
    line:SetHeight(1)
    return {texture=line, fraction=fraction}
end

local function place(widget, width, height, point, parent, relativePoint, x, y)
    if not widget then return end
    widget:ClearAllPoints()
    widget:SetWidth(width)
    widget:SetHeight(height)
    widget:SetPoint(point, parent, relativePoint, x, y)
end

function R.LayoutBottomBar(view)
    local bar = view and view.BottomBar
    if not bar or not bar.SaveChanges or not bar.UndoButton or not bar.ChangeSpec or not bar.Search then return end
    local width = bar:GetWidth()
    if not width or width <= 0 then width = view:GetWidth() end
    if not width or width <= 0 then return end
    local twoRows = width < 900
    bar:SetHeight(twoRows and 66 or 54)
    place(bar.SaveChanges, 148, 29, "BOTTOMRIGHT", bar, "BOTTOMRIGHT", -20, 10)
    place(bar.UndoButton, 30, 29, "RIGHT", bar.SaveChanges, "LEFT", -8, 0)
    local left = 20
    if bar.ResetButton then
        place(bar.ResetButton, 30, 29, "BOTTOMLEFT", bar, "BOTTOMLEFT", left, 10)
        left = left + 42
    end
    if bar.SpecDropDown then
        local dropWidth = math.min(178, math.max(60, width-314))
        place(bar.SpecDropDown, dropWidth, 27, "BOTTOMLEFT", bar, "BOTTOMLEFT", left, 11)
        left = left + dropWidth + 16
    end
    if twoRows then
        place(bar.ChangeSpec, 154, 23, "TOPRIGHT", bar, "TOPRIGHT", -20, -2)
        place(bar.Search, math.min(300, math.max(80, width-214)), 22, "TOPLEFT", bar, "TOPLEFT", 20, -3)
    else
        place(bar.ChangeSpec, 154, 27, "RIGHT", bar.UndoButton, "LEFT", -14, 0)
        local searchWidth = math.min(260, math.max(100, width-left-404))
        place(bar.Search, searchWidth, 22, "RIGHT", bar.ChangeSpec, "LEFT", -22, 0)
    end
    if not bar.afForeverDecorated then
        local background = bar:CreateTexture(nil, "BACKGROUND")
        background:SetTexture("Interface\\Buttons\\WHITE8X8")
        background:SetAllPoints(bar)
        background:SetVertexColor(0.021, 0.028, 0.038, 0.96)
        local line = bar:CreateTexture(nil, "OVERLAY")
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetVertexColor(0.48, 0.42, 0.31, 0.8)
        line:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        line:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
        line:SetHeight(1)
        if bar.Texture then bar.Texture:SetAlpha(0.08) end
        bar.afForeverDecorated = true
    end
    for _, name in ipairs({"BuildDropDown", "ShareBuildButton", "ImportBuildButton"}) do
        if bar[name] then bar[name]:Hide() end
    end
    R.footerRows = twoRows and 2 or 1
end

function R.Layout(view)
    if not view then return end
    R.LayoutBottomBar(view)
    local width = view:GetWidth()
    if not width or width <= 0 then return end
    for _, entry in ipairs(view.afForeverHeaderLines or {}) do
        entry.texture:ClearAllPoints()
        entry.texture:SetPoint("TOP", view, "TOP", width*entry.fraction, -76)
        entry.texture:SetWidth(math.max(1, width/2-72))
    end
end

function R.Style()
    if not isCoA() then return false end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then R.needsFit=true; return false end
    local root = _G.CoATalentFrame
    if not R.HasOriginalHandlers(root) then return false end
    local view = root.TreeView
    if not view.afForeverTreeStyled then
        textStyle(view.ClassTree)
        textStyle(view.SpecTree)
        view.afForeverHeaderLines = {headerLine(view, -0.25), headerLine(view, 0.25)}
        view:HookScript("OnSizeChanged", function(self) R.Layout(self) end)
        view.afForeverTreeStyled = true
    end
    R.Layout(view)
    local visual = AF.CoATreeVisuals
    if visual and type(visual.Apply) == "function" then
        local ok, err = pcall(visual.Apply)
        if not ok then fail(err) end
    end
    return true
end

function R.RemoveAscensionCollectionTabs()
    if not isCoA() then return end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
    local c = _G.Collections
    if not c or not c.Tabs or not c.Tabs.CharacterAdvancement or type(c.HideTabID) ~= "function" then return end
    if R.tabsPruned == c then return end
    for _, name in ipairs({"Vanity", "Wardrobe", "SeasonalCollection", "MysticEnchants", "SkillCards"}) do
        if c.Tabs[name] then pcall(c.HideTabID, c, c.Tabs[name]) end
    end
    R.tabsPruned = c
end

function R.Fit()
    local c = _G.Collections
    if not c or not UIParent or R.fitting then return end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then R.needsFit=true; return end
    local width, height = c:GetWidth(), c:GetHeight()
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    if not width or not height or width <= 0 or height <= 0 or
       not screenWidth or not screenHeight or screenWidth <= 64 or screenHeight <= 64 then return end
    local current = c:GetScale() or 1
    if current <= 0 then return end
    if R.scaleOwner ~= c then
        R.scaleOwner, R.preferredScale, R.lastFitScale = c, current, nil
    elseif not R.lastFitScale or math.abs(current-R.lastFitScale) > 0.0001 then
        R.preferredScale = current
    end
    local parent = c.GetParent and c:GetParent()
    local parentScale = parent and parent.GetEffectiveScale and parent:GetEffectiveScale() or 1
    local uiScale = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    if parentScale <= 0 or uiScale <= 0 then return end
    local fit = math.min((screenWidth-64)*uiScale/(width*parentScale),
                         (screenHeight-64)*uiScale/(height*parentScale))
    local selected = math.min(R.preferredScale, fit)
    if selected <= 0 then return end
    R.fitting = true
    c:SetScale(selected)
    if c.SetClampedToScreen then c:SetClampedToScreen(true) end
    R.fitting = nil
    R.lastFitScale, R.needsFit = selected, false
    return selected
end

function R.Open()
    if not isCoA() then return false end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then return false end
    if type(_G.CharacterAdvancement_LoadUI) == "function" then pcall(CharacterAdvancement_LoadUI) end
    local c = _G.Collections
    if not c or not c.Tabs or not c.Tabs.CharacterAdvancement then fail("CoA talents not yet loaded"); return false end
    if type(c.GoToTab) ~= "function" then return false end
    c:GoToTab(c.Tabs.CharacterAdvancement)
    R.Style()
    if AF.CoATreeHome and type(AF.CoATreeHome.OpenTrees) == "function" then AF.CoATreeHome.OpenTrees() end
    R.Fit()
    return true
end
AF.OpenTalents = R.Open

local function attach()
    if not isCoA() then return false end
    local root = _G.CoATalentFrame
    if not root then return false end
    if R.attached ~= root then
        R.attached = root
        root:HookScript("OnShow", function()
            local ok, err = pcall(R.Style)
            if not ok then fail(err) end
            R.RemoveAscensionCollectionTabs()
            R.Fit()
        end)
    end
    R.Style()
    R.RemoveAscensionCollectionTabs()
    return true
end

local events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "ADDON_LOADED", "PLAYER_REGEN_ENABLED",
                        "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name ~= "Ascension_CoATalents" and name ~= "Ascension_Collections" then return end
    local ok, err = pcall(attach)
    if not ok then fail(err) end
    R.Fit()
end)
events.elapsed = 0
events:SetScript("OnUpdate", function(self, elapsed)
    if R.attached then self:SetScript("OnUpdate", nil); return end
    if not isCoA() then return end
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed >= 1 then
        self.elapsed = 0
        local ok, err = pcall(attach)
        if not ok then fail(err) end
    end
end)
