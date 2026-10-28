-- Azeroth Forever — client-native 2026-style Escape / options menu.
-- Loaded from Interface/FrameXML/FrameXML.toc; NO AddOns entry.
-- Provides consolidated Options and Edit Mode buttons, retains the original
-- client's secure Logout/Quit/Return button handlers. Unsupported modern
-- client-only settings are never silently claimed as functional.
--
-- UI styling reference: WoW: Forever beta: Game Menu > Options / Edit Mode.
local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
local M = { installed=false, buttons={}, suppressed={} }
AF.GameMenu = M

local function present(frame)
    return frame and frame.IsShown and frame:IsShown()
end

local function notice(text)
    if AF.Notice then AF.Notice("Game menu: " .. tostring(text)) end
end

local function setVisible(frame, show)
    if frame then
        if show then frame:Show() else frame:Hide() end
    end
end

local function secureNative(name)
    local frame=_G[name]
    if not frame or not frame.GetScript or
       type(frame:GetScript("OnClick")) ~= "function" then return nil end
    return frame
end

local function editMode()
    if _G.ForeverUI and ForeverUI.CustomizeUI and
       type(ForeverUI.CustomizeUI.Open)=="function" then
        if GameMenuFrame then GameMenuFrame:Hide() end
        ForeverUI.CustomizeUI.Open()
    else
        notice("The native Edit Mode is not available in this client build.")
    end
end

local function options()
    if GameMenuFrame then GameMenuFrame:Hide() end
    if type(AF.OpenSettings)=="function" then
        AF.OpenSettings()
    elseif InterfaceOptionsFrame then
        InterfaceOptionsFrame:Show()
    else
        notice("The Options panel is unavailable.")
    end
end

local function makeButton(parent, text, action)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetWidth(222) b:SetHeight(30)
    b:SetText(text)
    b:SetScript("OnClick",action)
    return b
end

-- Do not remove a named gameplay element because its tooltip resembles a
-- Trial. Only remove unwanted Ascension trial / store menu buttons in the
-- non-combat Micro Menu. The player action bars and talent controls remain.
local TRIAL_UI_NAMES={
    "AscensionTrialMicroButton",
    "AscensionTrialsMicroButton",
    "TrialMicroButton",
    "TrialsMicroButton",
    "AscensionTrialButton",
    "TrialModeMicroButton",
    "AscensionTrialMenuButton",
}
function M.HideTrialControls()
    for _,name in ipairs(TRIAL_UI_NAMES) do
        local f=_G[name]
        if f and f.Hide and not M.suppressed[name] then
            M.suppressed[name]=true
            f:Hide()
            if f.HookScript then
                f:HookScript("OnShow",function(self) self:Hide() end)
            end
        end
    end
    if not _G.GameMenuFrame then return end
    -- Ascension-only game menu entries explicitly labelled Trial.
    -- Legitimate Story/Quest action buttons elsewhere are untouched.
    for _,button in ipairs({GameMenuFrame:GetChildren()}) do
        local label=button.GetText and button:GetText()
        local frameName=button.GetName and button:GetName()
        if type(label)=="string" and
           (label=="Trial" or label=="Trials" or label=="Trial Mode"
            or label=="Trial Challenges") and
           type(frameName)=="string" and
           not M.suppressed[frameName] then
            M.suppressed[frameName]=true
            button:Hide()
            button:HookScript("OnShow",function(self) self:Hide() end)
        end
    end
end

local function style(frame)
    if not frame then return end
    frame:SetWidth(282)
    frame:SetHeight(478)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true,tileSize=32,edgeSize=22,
            insets={left=7,right=7,top=7,bottom=7},
        })
        frame:SetBackdropColor(.028,.035,.047,.98)
        frame:SetBackdropBorderColor(.46,.4,.28,.96)
    end
end

local function keepOriginalClick(button)
    -- Do NOT assign any new OnClick script to Logout, Quit, Continue, or
    -- other secure game-client operations; just restyle & reposition them.
    return button
end

function M.Refresh()
    local frame=_G.GameMenuFrame
    if not frame then return end
    if M.locked then return end
    M.locked=true
    M.HideTrialControls()
    style(frame)

    local rows={
        M.options,
        M.edit,
        secureNative("GameMenuButtonKeybindings"),
        secureNative("GameMenuButtonMacros"),
        secureNative("GameMenuButtonAddOns"),
        secureNative("GameMenuButtonHelp"),
        secureNative("GameMenuButtonLogout"),
        secureNative("GameMenuButtonQuit"),
        secureNative("GameMenuButtonContinue"),
    }

    -- Retire fragmented 3.3.5 Ascension menus: Options provides consolidated
    -- Video/Sound/Interface tabs; do not leave a duplicate column of red
    -- custom Ascension settings buttons. Only hide our known redundant ones.
    for _,name in ipairs({
        "GameMenuButtonOptions", "GameMenuButtonSoundOptions",
        "GameMenuButtonMacOptions", "GameMenuButtonUIOptions",
        "GameMenuButtonRatings", "GameMenuButtonDiscord",
        "GameMenuButtonJoinDiscord", "GameMenuButtonReportBug"
    }) do
        local old=_G[name]
        if old and old ~= M.options and old ~= M.edit then old:Hide() end
    end

    local y=71
    local count=0
    for _,b in ipairs(rows) do
        if b then
            b:ClearAllPoints()
            b:SetPoint("TOP",frame,"TOP",0,-y)
            b:SetWidth(222)
            b:SetHeight(30)
            if b ~= M.options and b ~= M.edit then
                keepOriginalClick(b)
            end
            setVisible(b,true)
            y=y+36
            count=count+1
        end
    end
    frame:SetHeight(math.max(290, y+30))
    if M.heading then M.heading:SetText("GAME MENU") end
    M.buttonCount=count
    M.locked=nil
end

function M.Install()
    if M.installed or not GameMenuFrame then return M.installed end
    local f=GameMenuFrame
    M.options=makeButton(f,"Options",options)
    M.edit=makeButton(f,"Edit Mode",editMode)
    local heading=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    heading:SetPoint("TOP",f,"TOP",0,-25)
    heading:SetText("GAME MENU")
    M.heading=heading
    f:HookScript("OnShow",function()
        -- The ForeverUI port and stock menu might place its buttons during
        -- OnShow. Our late-loaded native integration runs after their hook.
        M.Refresh()
    end)
    M.installed=true
    if present(f) then M.Refresh() end
    return true
end

local watcher=CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent",function() M.Install() end)
watcher.elapsed=0
watcher:SetScript("OnUpdate",function(self,dt)
    self.elapsed=self.elapsed+(dt or 0)
    if self.elapsed<1 then return end
    self.elapsed=0
    if not M.installed then M.Install() end
    M.HideTrialControls()
end)
