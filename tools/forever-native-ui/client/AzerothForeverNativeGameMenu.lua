local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
local M = {installed=false, buttons={}, suppressed={}}
AF.GameMenu = M

local function inCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown()
end

local function notice(text)
    if AF.Notice then AF.Notice("Game menu: " .. tostring(text)) end
end

local function secureNative(name)
    local frame = _G[name]
    if frame and frame.GetScript and type(frame:GetScript("OnClick")) == "function" then return frame end
end

local function hasEditMode()
    return _G.ForeverUI and ForeverUI.CustomizeUI and type(ForeverUI.CustomizeUI.Open) == "function"
end

local function editMode()
    if not hasEditMode() then notice("The native Edit Mode is not available in this client build."); return end
    GameMenuFrame:Hide()
    ForeverUI.CustomizeUI.Open()
end

local function options()
    if type(AF.OpenSettings) == "function" then
        GameMenuFrame:Hide()
        AF.OpenSettings()
    elseif InterfaceOptionsFrame then
        GameMenuFrame:Hide()
        InterfaceOptionsFrame:Show()
    else
        notice("The Options panel is unavailable.")
    end
end

local function styleButton(button)
    local templates = _G.ForeverUI and ForeverUI.Templates
    if not button.afForeverMenuStyled and templates and type(templates.ThreeSliceButton) == "function" then
        local ok = pcall(templates.ThreeSliceButton, button, "128-redbutton",
                         {GameFontHighlightLarge, GameFontHighlightLarge, GameFontDisableLarge})
        if ok then button.afForeverMenuStyled = true end
    end
    button:SetWidth(222)
    button:SetHeight(30)
end

local function makeButton(parent, text, action)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetText(text)
    button:SetScript("OnClick", action)
    styleButton(button)
    return button
end

local trialNames = {
    "AscensionTrialMicroButton", "AscensionTrialsMicroButton", "TrialMicroButton", "TrialsMicroButton",
    "AscensionTrialButton", "TrialModeMicroButton", "AscensionTrialMenuButton"
}

local function suppress(name, frame)
    if not frame or not frame.Hide then return end
    frame:Hide()
    if M.suppressed[name] == frame then return end
    M.suppressed[name] = frame
    if frame.HookScript then
        frame:HookScript("OnShow", function(self)
            if not inCombat() then self:Hide() else M.pending=true end
        end)
    end
end

function M.HideTrialControls()
    if inCombat() then M.pending=true; return end
    for _, name in ipairs(trialNames) do suppress(name, _G[name]) end
    if not _G.GameMenuFrame then return end
    for _, button in ipairs({GameMenuFrame:GetChildren()}) do
        local label = button.GetText and button:GetText()
        local name = button.GetName and button:GetName()
        if name and (label == "Trial" or label == "Trials" or label == "Trial Mode" or label == "Trial Challenges") then
            suppress(name, button)
        end
    end
end

local function styleFrame(frame)
    frame:SetWidth(282)
    if not (_G.ForeverUI and ForeverUI.GameMenu) and frame.SetBackdrop then
        frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=32, edgeSize=22,
            insets={left=7, right=7, top=7, bottom=7}})
        frame:SetBackdropColor(0.028, 0.035, 0.047, 0.98)
        frame:SetBackdropBorderColor(0.46, 0.4, 0.28, 0.96)
    end
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    local nativeHeading = _G.ForeverUI and ForeverUI.GameMenu and ForeverUI.GameMenu.header
    if nativeHeading then
        if M.heading then M.heading:Hide() end
    else
        if not M.heading then
            M.heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            M.heading:SetPoint("TOP", frame, "TOP", 0, -25)
            M.heading:SetText("GAME MENU")
        end
        M.heading:Show()
    end
end

function M.Fit()
    local frame = _G.GameMenuFrame
    if not frame or not UIParent or inCombat() then return end
    local w, h = frame:GetWidth(), frame:GetHeight()
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    if not w or not h or not sw or not sh or w <= 0 or h <= 0 or sw <= 40 or sh <= 40 then return end
    local current = frame:GetScale() or 1
    if not M.lastFitScale or math.abs(current-M.lastFitScale) > 0.0001 then M.preferredScale=current end
    local parent = frame.GetParent and frame:GetParent()
    local ps = parent and parent.GetEffectiveScale and parent:GetEffectiveScale() or 1
    local us = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    if ps <= 0 or us <= 0 then return end
    local scale = math.min(M.preferredScale, (sw-40)*us/(w*ps), (sh-40)*us/(h*ps))
    if scale > 0 then frame:SetScale(scale); M.lastFitScale=scale end
end

local function refreshBody()
    local frame = GameMenuFrame
    M.HideTrialControls()
    styleFrame(frame)
    local rows = {{button=M.options}, {button=M.edit}}
    local function append(name, gap)
        local button = secureNative(name)
        if button then rows[#rows+1]={button=button, gap=gap or 0} end
    end
    append("GameMenuButtonKeybindings")
    append("GameMenuButtonMacros")
    append("GameMenuButtonAddOns")
    append("GameMenuButtonHelp")
    append("GameMenuButtonLogout", 10)
    append("GameMenuButtonQuit")
    append("GameMenuButtonContinue", 10)
    for _, name in ipairs({"GameMenuButtonOptions", "GameMenuButtonSoundOptions", "GameMenuButtonMacOptions",
        "GameMenuButtonUIOptions", "GameMenuButtonRatings", "GameMenuButtonDiscord",
        "GameMenuButtonJoinDiscord", "GameMenuButtonReportBug"}) do
        local old = _G[name]
        if old and old ~= M.options and old ~= M.edit then old:Hide() end
    end
    if hasEditMode() then M.edit:Enable() else M.edit:Disable() end
    if type(AF.OpenSettings) == "function" or InterfaceOptionsFrame then M.options:Enable() else M.options:Disable() end
    local y = 62
    for _, row in ipairs(rows) do
        y = y + (row.gap or 0)
        local button = row.button
        styleButton(button)
        button:ClearAllPoints()
        button:SetPoint("TOP", frame, "TOP", 0, -y)
        button:Show()
        y = y + 36
    end
    frame:SetHeight(y+18)
    M.buttonCount, M.buttons = #rows, rows
    M.Fit()
    M.pending = false
end

function M.Refresh()
    if not _G.GameMenuFrame or not M.installed or M.locked then return false end
    if inCombat() then M.pending=true; return false end
    M.locked = true
    local ok, err = pcall(refreshBody)
    M.locked = nil
    if not ok then
        if M.lastError ~= tostring(err) then notice(err) end
        M.lastError = tostring(err)
        return false
    end
    M.lastError = nil
    return true
end

function M.Install()
    if M.installed then return true end
    if not _G.GameMenuFrame or inCombat() then return false end
    M.options = makeButton(GameMenuFrame, "Options", options)
    M.edit = makeButton(GameMenuFrame, "Edit Mode", editMode)
    GameMenuFrame:HookScript("OnShow", function() M.Refresh() end)
    M.installed = true
    if GameMenuFrame:IsShown() then M.Refresh() end
    return true
end

local watcher = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "ADDON_LOADED", "PLAYER_REGEN_ENABLED",
                        "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED"}) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function()
    M.Install()
    if M.installed then
        M.HideTrialControls()
        if GameMenuFrame:IsShown() then M.Refresh() end
    end
end)
watcher.elapsed = 0
watcher:SetScript("OnUpdate", function(self, elapsed)
    if M.installed then self:SetScript("OnUpdate", nil); return end
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed >= 1 then self.elapsed=0; M.Install() end
end)
