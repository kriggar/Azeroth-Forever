local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
local R = {version=5, specs={}, buttons={}, treesOpened=false}
AF.CoATreeHome = R

local function explain(text)
    R.lastError = tostring(text)
    if AF.Notice then AF.Notice("CoA talent trees: " .. R.lastError) end
end

local function isCoA()
    return type(IsCustomClass) == "function" and IsCustomClass()
end

local function inCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown()
end

local function readActiveSpec()
    local api = _G.C_CharacterAdvancement
    if api and type(api.GetActiveChrSpec) == "function" then
        local ok, id = pcall(api.GetActiveChrSpec)
        if ok and type(id) == "number" and id > 0 then return id end
    end
end

local function choicesForClass()
    if type(UnitClass) ~= "function" then return {} end
    local cls = select(2, UnitClass("player"))
    local api = _G.C_ClassInfo
    local result, seen = {}, {}
    if not cls or not api or type(api.GetAllSpecs) ~= "function" or
       type(api.GetSpecInfo) ~= "function" then return result end
    local ok, names = pcall(api.GetAllSpecs, cls)
    if not ok or type(names) ~= "table" then return result end
    for _, value in ipairs(names) do
        local success, info = pcall(api.GetSpecInfo, cls, value)
        if success and type(info) == "table" and type(info.ID) == "number" and
           info.ID > 0 and not seen[info.ID] then
            seen[info.ID] = true
            result[#result+1] = {id=info.ID, name=tostring(info.Name or info.Spec or value), info=info}
        end
    end
    return result
end
R.GetSpecs = choicesForClass

local function findSpec(id)
    for _, spec in ipairs(R.specs) do
        if spec.id == id then return spec end
    end
end

local function pickFirst()
    return findSpec(R.previewSpecID) or findSpec(readActiveSpec()) or R.specs[1]
end

local function originalChoice(root, specId)
    local pool = root.SpecView and root.SpecView.SpecChoicePool
    if not pool or type(pool.EnumerateActive) ~= "function" then return end
    for original in pool:EnumerateActive() do
        if original and original.specInfo and original.specInfo.ID == specId then return original end
    end
end

local function tooltip(button)
    if not GameTooltip or not button.spec then return end
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(button.spec.name)
    GameTooltip:AddLine(button.spec.id == readActiveSpec() and "Active specialization" or
                        "Click to preview. Choose specialization to edit this tree.", 0.85, 0.8, 0.65, true)
    GameTooltip:Show()
end

local function skinButton(button)
    local templates = _G.ForeverUI and ForeverUI.Templates
    if templates and type(templates.ThreeSliceButton) == "function" then
        pcall(templates.ThreeSliceButton, button, "128-redbutton",
              {GameFontNormal, GameFontHighlight, GameFontDisable})
    end
end

local function makeTab(strip)
    local button = CreateFrame("Button", nil, strip, "UIPanelButtonTemplate")
    button:SetHeight(27)
    skinButton(button)
    button:SetScript("OnClick", function(self) if self.spec then R.Select(self.spec.id) end end)
    button:SetScript("OnEnter", tooltip)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    local selected = button:CreateTexture(nil, "OVERLAY")
    selected:SetTexture("Interface\\Buttons\\WHITE8X8")
    selected:SetVertexColor(0.95, 0.76, 0.34, 1)
    selected:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 6, 2)
    selected:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 2)
    selected:SetHeight(2)
    button.selected = selected
    return button
end

function R.LayoutTabs()
    if not R.tabStrip then return end
    local width = R.tabStrip:GetWidth()
    if not width or width <= 0 then width = CoATalentFrame.TreeView:GetWidth() end
    if not width or width <= 0 then return end
    local count = #R.specs
    local gap, left, actionWidth = 6, 12, math.min(176, width * 0.24)
    local available = width - left * 2 - actionWidth - 12
    local tabWidth = count > 0 and math.min(190, (available - gap * (count-1)) / count) or 0
    R.tabWidth = math.max(1, tabWidth)
    for i, button in ipairs(R.buttons) do
        button:ClearAllPoints()
        button:SetWidth(R.tabWidth)
        button:SetPoint("TOPLEFT", R.tabStrip, "TOPLEFT", left + (i-1)*(R.tabWidth+gap), -3)
        local font = button.GetFontString and button:GetFontString()
        if font then
            font:SetWidth(math.max(1, R.tabWidth-16))
            if font.SetWordWrap then font:SetWordWrap(false) end
        end
    end
    R.choose:SetWidth(actionWidth)
    R.choose:ClearAllPoints()
    R.choose:SetPoint("TOPRIGHT", R.tabStrip, "TOPRIGHT", -left, -3)
end

local function ensurePreviewGuard(tree)
    if not tree then return end
    if tree.afForeverPreviewGuard then return tree.afForeverPreviewGuard end
    local guard = CreateFrame("Frame", nil, tree)
    guard:SetAllPoints(tree)
    guard:SetFrameLevel(tree:GetFrameLevel()+50)
    guard:EnableMouse(true)
    guard:SetScript("OnMouseDown", function()
        explain("This is a read-only preview. Use Choose specialization before editing talents.")
    end)
    guard:Hide()
    tree.afForeverPreviewGuard = guard
    return guard
end

function R.UpdatePreviewState()
    local root = _G.CoATalentFrame
    local view = root and root.TreeView
    if not view then return end
    local active = readActiveSpec()
    local editable = R.stagedSpecID or active
    local readOnly = not editable or (R.previewSpecID and R.previewSpecID ~= editable)
    R.readOnly = not not readOnly
    for _, tree in ipairs({view.ClassTree, view.SpecTree}) do
        local guard = ensurePreviewGuard(tree)
        if guard then
            if readOnly then guard:Show() else guard:Hide() end
        end
    end
    local bar = view.BottomBar
    local undo = bar and bar.UndoButton
    if undo and not undo.afForeverPreviewHook then
        undo.afForeverPreviewHook = true
        undo:HookScript("OnClick", function()
            R.stagedSpecID = nil
            R.previewSpecID = readActiveSpec()
            R.renderedSpecID = nil
            R.OpenTrees()
        end)
    end
    local save = bar and bar.SaveChanges
    if not save then return end
    if not save.afForeverPreviewHook then
        save.afForeverPreviewHook = true
        save:HookScript("OnEnable", function(self) if R.readOnly then self:Disable() end end)
    end
    if readOnly then
        R.saveGated = true
        save:Disable()
    elseif R.saveGated then
        R.saveGated = false
        local api = _G.C_CharacterAdvancement
        if api and type(api.CanApplyPendingBuild) == "function" then
            local ok, allowed = pcall(api.CanApplyPendingBuild)
            if ok and (allowed == true or allowed == 1) then save:Enable() end
        end
    end
end

function R.UpdateTabs()
    if not R.tabStrip then return end
    local active = readActiveSpec()
    local selected = pickFirst()
    for i, spec in ipairs(R.specs) do
        if not R.buttons[i] then R.buttons[i] = makeTab(R.tabStrip) end
        local button = R.buttons[i]
        button.spec = spec
        button:SetText((spec.id == active and "|cff88dd88" or "|cffdfc081") .. spec.name .. "|r")
        if selected and spec.id == selected.id then button.selected:Show() else button.selected:Hide() end
        button:Show()
    end
    for i=#R.specs+1,#R.buttons do R.buttons[i].spec=nil; R.buttons[i]:Hide() end
    local current = selected and selected.id == active
    local staged = selected and selected.id == R.stagedSpecID
    R.choose:SetText(current and "Active specialization" or (staged and "Selection staged" or "Choose specialization"))
    if not selected or current or staged or inCombat() then R.choose:Disable() else R.choose:Enable() end
    R.LayoutTabs()
    R.UpdatePreviewState()
end

function R.CreateTabStrip(root)
    if R.tabStrip then return R.tabStrip end
    local tree = root.TreeView
    local strip = CreateFrame("Frame", "AzerothForeverCoATreeTabs", tree)
    strip:SetHeight(33)
    strip:SetPoint("TOPLEFT", tree, "TOPLEFT", 3, -2)
    strip:SetPoint("TOPRIGHT", tree, "TOPRIGHT", -4, -2)
    strip:SetFrameLevel(tree:GetFrameLevel()+30)
    strip:EnableMouse(false)
    local bg = strip:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetAllPoints(strip)
    bg:SetVertexColor(0.028, 0.037, 0.05, 0.97)
    R.tabStrip = strip
    R.choose = CreateFrame("Button", "AzerothForeverChooseSpec", strip, "UIPanelButtonTemplate")
    R.choose:SetHeight(27)
    skinButton(R.choose)
    R.choose:SetScript("OnClick", function() R.ConfirmSelection(R.previewSpecID) end)
    strip:HookScript("OnSizeChanged", function() R.LayoutTabs() end)
    return strip
end

local function safePreview(root, id)
    if R.renderedSpecID == id then return true end
    if type(root.TreeView.SetSpecID) ~= "function" then return false end
    local ok, err = pcall(root.TreeView.SetSpecID, root.TreeView, id)
    if not ok then explain("Could not display CoA talent graph: " .. tostring(err)); return false end
    R.renderedSpecID = id
    return true
end

function R.OpenTrees()
    if R.opening or R.selecting or not isCoA() or inCombat() then return false end
    local root = _G.CoATalentFrame
    if not root or not root.TreeView or not root.SpecView or not _G.C_CharacterAdvancement then return false end
    R.opening = true
    local ok, result = pcall(function()
        if #R.specs == 0 then R.specs = choicesForClass() end
        local spec = pickFirst()
        if not spec or not safePreview(root, spec.id) then return false end
        R.previewSpecID = spec.id
        R.CreateTabStrip(root)
        if root.SpecView:IsShown() then root.SpecView:Hide() end
        if not root.TreeView:IsShown() then root.TreeView:Show() end
        R.treesOpened = true
        R.UpdateTabs()
        local skin = AF.CoATalents
        if skin then
            if type(skin.Style) == "function" then
                local styled, err = pcall(skin.Style)
                if not styled then explain(err) end
            end
            if type(skin.Fit) == "function" then
                local fitted, err = pcall(skin.Fit)
                if not fitted then explain(err) end
            end
        end
        return true
    end)
    R.opening = nil
    if not ok then explain(result); return false end
    return result
end

function R.Select(specId)
    if R.opening or R.selecting then return false end
    if inCombat() then explain("Specialization previews are unavailable during combat."); return false end
    if not findSpec(specId) then return false end
    local previous = R.previewSpecID
    R.previewSpecID = specId
    if R.OpenTrees() then return true end
    R.previewSpecID = previous
    return false
end

function R.ConfirmSelection(specId)
    if R.selecting or inCombat() then return false end
    local root = _G.CoATalentFrame
    local spec = findSpec(specId)
    if not root or not spec or specId ~= R.previewSpecID then return false end
    if specId == (R.stagedSpecID or readActiveSpec()) then return true end
    local api = _G.C_CharacterAdvancement
    if not api or type(api.CanSwitchActiveChrSpec) ~= "function" then
        explain("Specialization validation is unavailable. No change was made."); return false
    end
    local valid, allowed = pcall(api.CanSwitchActiveChrSpec, specId)
    if not valid or not (allowed == true or allowed == 1) then
        explain("The original CoA rules do not allow this specialization change."); return false
    end
    local chosen = originalChoice(root, specId)
    if not chosen or type(chosen.OnSelected) ~= "function" then
        explain("Original specialization selection is unavailable. No change was made."); return false
    end
    R.selecting = true
    local ok, err = pcall(chosen.OnSelected, chosen)
    R.selecting = nil
    R.renderedSpecID = nil
    if not ok or err == false then explain(err or "The native selection was refused."); return false end
    R.stagedSpecID = specId
    R.OpenTrees()
    return true
end

function R.Attach()
    if not isCoA() or inCombat() then return false end
    local root = _G.CoATalentFrame
    if not root or not root.TreeView or not root.SpecView then return false end
    if R.attached == root then return true end
    R.attached = root
    R.specs = choicesForClass()
    R.CreateTabStrip(root)
    root:HookScript("OnShow", function() R.OpenTrees() end)
    root.SpecView:HookScript("OnShow", function() R.OpenTrees() end)
    if root:IsShown() then R.OpenTrees() end
    return true
end

local watcher = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "ADDON_LOADED", "PLAYER_REGEN_ENABLED",
                        "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED"}) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(self, event, name)
    if event == "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED" then
        R.stagedSpecID = nil
        R.previewSpecID = readActiveSpec()
        R.renderedSpecID = nil
        R.specs = choicesForClass()
        if CoATalentFrame and CoATalentFrame:IsShown() then R.OpenTrees() end
    elseif event ~= "ADDON_LOADED" or name == "Ascension_CoATalents" or name == "Ascension_Collections" then
        R.Attach()
        if event == "PLAYER_REGEN_ENABLED" and R.attached and R.attached:IsShown() then R.OpenTrees() end
    end
end)
watcher.elapsed = 0
watcher:SetScript("OnUpdate", function(self, elapsed)
    if R.attached then self:SetScript("OnUpdate", nil); return end
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed >= 0.8 then self.elapsed=0; R.Attach() end
end)
