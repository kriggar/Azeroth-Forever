-- Azeroth Forever: one owner for the native Escape menu (WoW Forever styling).
-- Loaded in FrameXML, not as a separate AddOn.
-- The old upstream GameMenu.lua is not executed: two separate reflow systems
-- were fighting each other and leaving gaps and misplaced menu buttons.
-- Keep the native Logout / Quit / Continue and other secure OnClick scripts.

local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
local M = { installed = false, suppressed = {}, ordered = {}, refreshes = 0 }
AF.GameMenu = M
ForeverUI = ForeverUI or {}
ForeverUI.GameMenu = M

-- Camelot / ForeverUI game-menu dimensions, reduced vertical waste.
local N = { width = 256, side = 28, top = 48, bottom = 29,
            buttonWidth = 200, buttonHeight = 33, gap = 3, sectionGap = 14 }
local REDUNDANT = {
    "GameMenuButtonOptions", "GameMenuButtonUIOptions", "GameMenuButtonSoundOptions",
    "GameMenuButtonMacOptions", "GameMenuButtonKeybindings", "GameMenuButtonRatings",
    "GameMenuButtonDiscord", "GameMenuButtonJoinDiscord", "GameMenuButtonReportBug",
}
local TRIAL_BUTTONS = {
    "AscensionTrialMicroButton", "AscensionTrialsMicroButton", "TrialMicroButton",
    "TrialsMicroButton", "AscensionTrialButton", "TrialModeMicroButton",
    "AscensionTrialMenuButton", "AscensionTrialsButton", "AscensionTrialFrameButton",
}
local function notice(message)
    if AF.Notice then AF.Notice(tostring(message)) end
end
local function original(name)
    return _G[name]
end
local function isButton(frame)
    return frame and type(frame.GetObjectType) == "function" and frame:GetObjectType() == "Button"
end
local function hasNativeAction(frame)
    return isButton(frame) and type(frame.GetScript) == "function"
        and type(frame:GetScript("OnClick")) == "function"
end
local function hide(frame)
    if frame and type(frame.Hide) == "function" and frame.IsShown and frame:IsShown() then
        frame:Hide()
    end
end
local function suppress(frame)
    if not frame then return end
    if not M.suppressed[frame] then
        M.suppressed[frame] = true
        if frame.HookScript then
            frame:HookScript("OnShow", function(self) hide(self) end)
        end
    end
    hide(frame)
end
local function trialLabel(label)
    if type(label) ~= "string" then return false end
    local normalized = string.lower(label):gsub("%s+", " ")
    return normalized == "trial" or normalized == "trials" or
        normalized == "trial mode" or normalized == "trial challenges" or
        normalized == "ascension trials" or normalized == "trial rewards" or
        normalized == "trial preview" or normalized == "trial account"
end
local function trialName(name)
    if type(name) ~= "string" then return false end
    local normalized = string.lower(name)
    return string.find(normalized, "trialmicro", 1, true) ~= nil or
        string.find(normalized, "trialmenu", 1, true) ~= nil or
        string.find(normalized, "trialbutton", 1, true) ~= nil or
        string.find(normalized, "trialsbutton", 1, true) ~= nil
end

function M.HideTrialControls()
    -- Only remove client UI. Never disable characters, progression, skills or quests.
    for _, name in ipairs(TRIAL_BUTTONS) do
        local frame = original(name)
        if frame then suppress(frame) end
    end
    local gameMenu = original("GameMenuFrame")
    if gameMenu and gameMenu.GetChildren then
        for _, child in ipairs({ gameMenu:GetChildren() }) do
            if isButton(child) then
                local name = child.GetName and child:GetName()
                local label = child.GetText and child:GetText()
                if trialName(name) or trialLabel(label) then
                    suppress(child)
                end
            end
        end
    end
end

local function headerFont()
    if type(CreateFont) ~= "function" then return GameFontNormal end
    local font = CreateFont("AzerothForeverGameMenuFont")
    if SystemFont_Med2 then font:SetFontObject(SystemFont_Med2)
    elseif GameFontNormal then font:SetFontObject(GameFontNormal) end
    font:SetShadowOffset(1, -1)
    font:SetShadowColor(0, 0, 0)
    font:SetTextColor(1, 0.82, 0)
    return font
end

local function styleFrame(frame)
    if M.frameStyled then return end
    local template = ForeverUI and ForeverUI.Templates
    if template and type(template.DialogFrame) == "function" then
        if frame.SetBackdrop then frame:SetBackdrop(nil) end
        if GameMenuFrameHeader then GameMenuFrameHeader:SetAlpha(0) end
        if frame.GetRegions and MAIN_MENU then
            for _, region in ipairs({ frame:GetRegions() }) do
                if region.GetObjectType and region:GetObjectType() == "FontString" and
                    region.GetText and region:GetText() == MAIN_MENU then
                    region:SetAlpha(0)
                end
            end
        end
        local ok = pcall(template.DialogFrame, frame)
        if ok and type(template.Header) == "function" then
            local good, header = pcall(template.Header, frame,
                MAINMENU_BUTTON or "Game Menu", headerFont())
            if good then M.heading = header end
        end
    else
        if frame.SetBackdrop then
            frame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 32, edgeSize = 20,
                insets = { left = 6, right = 6, top = 6, bottom = 6 },
            })
            frame:SetBackdropColor(0.034, 0.038, 0.048, 0.98)
            if frame.SetBackdropBorderColor then
                frame:SetBackdropBorderColor(0.6, 0.48, 0.25, 1)
            end
        end
        M.heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        M.heading:SetPoint("TOP", frame, "TOP", 0, -17)
        M.heading:SetText("GAME MENU")
    end
    M.frameStyled = true
end

local function skin(button)
    if not button or button.afGameMenuSkinned then return end
    local template = ForeverUI and ForeverUI.Templates
    if template and type(template.ThreeSliceButton) == "function" then
        -- ThreeSliceButton changes visual regions, NOT the native click script.
        pcall(template.ThreeSliceButton, button, "128-redbutton",
            { GameFontHighlightLarge, GameFontHighlightLarge, GameFontDisableLarge })
    end
    button.afGameMenuSkinned = true
end

local function createAction(frame, text, onClick)
    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function options()
    hide(original("GameMenuFrame"))
    if type(AF.OpenSettings) == "function" then
        AF.OpenSettings()
    elseif original("InterfaceOptionsFrame") then
        InterfaceOptionsFrame:Show()
    else
        notice("Options are unavailable in this client.")
    end
end
local function editMode()
    local editor = ForeverUI and ForeverUI.CustomizeUI
    if editor and type(editor.Open) == "function" then
        hide(original("GameMenuFrame"))
        editor.Open()
    else
        notice("Edit Mode needs the client-native ForeverUI editor.")
    end
end

local function put(rows, button, section)
    if button and button.IsShown then
        table.insert(rows, { frame = button, section = section })
    end
end

function M.Refresh()
    local frame = original("GameMenuFrame")
    if not frame or M.inRefresh then return end
    M.inRefresh = true
    M.HideTrialControls()
    styleFrame(frame)

    -- No duplicate 3.3.5 Sound / Video / Interface / Key Bindings columns.
    for _, name in ipairs(REDUNDANT) do
        hide(original(name))
    end

    local rows = {}
    put(rows, M.options)
    local editor = ForeverUI and ForeverUI.CustomizeUI
    if M.edit.SetEnabled then
        M.edit:SetEnabled(editor and type(editor.Open) == "function" or false)
    end
    put(rows, M.edit)
    put(rows, hasNativeAction(original("GameMenuButtonMacros")) and GameMenuButtonMacros)
    put(rows, hasNativeAction(original("GameMenuButtonAddOns")) and GameMenuButtonAddOns)
    put(rows, hasNativeAction(original("GameMenuButtonHelp")) and GameMenuButtonHelp)
    put(rows, hasNativeAction(original("GameMenuButtonLogout")) and GameMenuButtonLogout, true)
    put(rows, hasNativeAction(original("GameMenuButtonQuit")) and GameMenuButtonQuit)
    put(rows, hasNativeAction(original("GameMenuButtonContinue")) and GameMenuButtonContinue, true)

    -- Restore simple, modern-facing titles without modifying any secure action.
    if original("GameMenuButtonHelp") and GameMenuButtonHelp.SetText then
        GameMenuButtonHelp:SetText("Support")
    end
    if original("GameMenuButtonQuit") and GameMenuButtonQuit.SetText then
        GameMenuButtonQuit:SetText("Exit Game")
    end
    if original("GameMenuButtonLogout") and GameMenuButtonLogout.SetText then
        GameMenuButtonLogout:SetText("Log Out")
    end
    if original("GameMenuButtonContinue") and GameMenuButtonContinue.SetText then
        GameMenuButtonContinue:SetText("Return to Game")
    end

    local allowed = {}
    for _, e in ipairs(rows) do allowed[e.frame] = true end
    -- Do not leave unregistered Ascension buttons floating over the menu.
    -- Only affect labelled GameMenuFrame buttons: other frames remain untouched.
    if frame.GetChildren then
        for _, child in ipairs({frame:GetChildren()}) do
            if isButton(child) and not allowed[child] then
                local label = child.GetText and child:GetText()
                if type(label) == "string" and label ~= "" then
                    hide(child)
                end
            end
        end
    end

    local y = N.top
    for _, entry in ipairs(rows) do
        local button = entry.frame
        if entry.section then y = y + N.sectionGap end
        skin(button)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", N.side, -y)
        button:SetSize(N.buttonWidth, N.buttonHeight)
        button:Show()
        y = y + N.buttonHeight + N.gap
    end
    frame:SetWidth(N.width)
    frame:SetHeight(y + N.bottom - N.gap)
    if frame.ClearAllPoints and UIParent then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    M.ordered = rows
    M.buttonCount = #rows
    M.refreshes = M.refreshes + 1
    M.lastHeight = y + N.bottom - N.gap
    M.inRefresh = nil
end

function M.Install()
    if M.installed then return true end
    local frame = original("GameMenuFrame")
    if not frame then return false end
    M.options = createAction(frame, "Options", options)
    M.edit = createAction(frame, "Edit Mode", editMode)
    -- This is the ONLY layout driver. The upstream GameMenu.lua is excluded
    -- from the native FrameXML load list by build_native_patch.py.
    frame:HookScript("OnShow", function() M.Refresh() end)
    M.installed = true
    M.Refresh()
    return true
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:SetScript("OnEvent", function()
    if not M.installed then M.Install() end
end)
watcher.elapsed = 0
watcher:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed < 0.7 then return end
    self.elapsed = 0
    if not M.installed then M.Install() end
    M.HideTrialControls()
    if M.installed and original("GameMenuFrame") and GameMenuFrame.IsShown and
        GameMenuFrame:IsShown() then M.Refresh() end
end)
