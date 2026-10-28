-- Azeroth Forever — built-in client settings, loaded by FrameXML (not AddOns).
-- Provides working 3.3.5 client CVars with a modern interface and UI scale.
-- Modern WoW: Forever option sets which need new engine APIs are not faked.

local AF = AzerothForeverNative
if not AF then return end

local frame
local activeTab = "Interface"
local controls = {}
local banner = "|cffffd080Azeroth Forever|r"

local function CVar(name)
    local ok, result = pcall(GetCVar, name)
    return ok and result or nil
end
local function UpdateCVar(name, value)
    if not name or CVar(name) == nil then return false end
    local ok = pcall(SetCVar, name, tostring(value))
    return ok
end
local function clear()
    for _, widget in ipairs(controls) do
        widget:Hide()
        widget:SetParent(nil)
    end
    controls = {}
end

local function track(f)
    table.insert(controls, f)
    return f
end

local function text(parent, value, size, x, y, width, color)
    local f = track(parent:CreateFontString(nil, "ARTWORK", size or "GameFontHighlight"))
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    f:SetWidth(width or 450)
    f:SetJustifyH("LEFT")
    f:SetText(value or "")
    if color then f:SetTextColor(color[1],color[2],color[3]) end
    return f
end

local function button(parent, label, x, y, w, h, handler)
    local b = track(CreateFrame("Button", nil, parent, "UIPanelButtonTemplate"))
    b:SetWidth(w or 160)
    b:SetHeight(h or 26)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetText(label)
    b:SetScript("OnClick", handler)
    return b
end

local function check(parent, label, x, y, name, description)
    local box = track(CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate"))
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local c = CVar(name)
    box:SetChecked(c == "1")
    box:SetScript("OnClick", function(self)
        if not UpdateCVar(name, self:GetChecked() and "1" or "0") then
            self:SetChecked(not self:GetChecked())
            AF.Notice("This setting is unavailable in the CoA client.")
        end
    end)
    text(parent, label, "GameFontNormal", x+34, y-7, 430)
    if description then text(parent, description, "GameFontHighlightSmall", x+34, y-28, 430, {0.72,0.73,0.74}) end
    if c == nil then box:Disable() end
    return box
end

local function sectionTitle(parent, label, y)
    text(parent, label, "GameFontNormalLarge", 185, y, 470, {1,0.82,0.33})
end

local function buildScaleSlider(panel)
    sectionTitle(panel, "User Interface Scale", -75)
    text(panel, "Change the whole interface size without replacing CoA class controls.", "GameFontHighlightSmall", 185, -110, 470)
    local slider = track(CreateFrame("Slider", nil, panel, "OptionsSliderTemplate"))
    slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 204, -165)
    slider:SetWidth(385)
    slider:SetHeight(18)
    slider:SetMinMaxValues(0.64, 1.00)
    slider:SetValueStep(0.01)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local lo = track(slider:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"))
    lo:SetPoint("TOPLEFT",slider,"BOTTOMLEFT",-4,-6)
    lo:SetText("64%")
    local hi = track(slider:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"))
    hi:SetPoint("TOPRIGHT",slider,"BOTTOMRIGHT",4,-6)
    hi:SetText("100%")
    local value = text(panel, "82%", "GameFontNormalLarge", 595, -146, 80)
    slider:SetScript("OnValueChanged", function(self, n)
        n = math.floor((n or .82)*100+.5)/100
        value:SetText(tostring(math.floor(n*100+.5)).."%")
        if not self.initializing then
            AF.SetScale(n, false)
        end
    end)
    slider.initializing = true
    slider:SetValue(AF.CurrentScale())
    slider.initializing = nil
    button(panel, "Recommended 82%", 190, -251, 180, 29, function()
        AF.SetScale(0.82)
        slider.initializing = true
        slider:SetValue(0.82)
        slider.initializing = nil
    end)
    button(panel, "Original 100%", 388, -251, 180, 29, function()
        AF.SetScale(1)
        slider.initializing = true
        slider:SetValue(1)
        slider.initializing = nil
    end)
    text(panel, "For per-element placement, select Customize UI in the game menu or use /fui.", "GameFontHighlightSmall", 185, -317, 500)
end

local function showTab(tab)
    activeTab = tab
    if not frame then return end
    clear()
    if tab == "Interface" then
        buildScaleSlider(frame)
    elseif tab == "Gameplay" then
        sectionTitle(frame, "Gameplay", -75)
        check(frame, "Auto Loot", 190, -114, "autoLootDefault",
              "Automatically loot eligible items when interacting with corpses.")
        check(frame, "Show quest objectives on the map", 190, -183, "questPOI",
              "Use the native 3.3.5 quest POI setting if supported.")
        check(frame, "Show tutorials", 190, -252, "showTutorials",
              "Displays the game's supported tutorial prompts.")
        text(frame, "Combat, class skills, quests and talent handling remain on the CoA server.", "GameFontHighlightSmall", 190, -338, 470)
    elseif tab == "Display" then
        sectionTitle(frame, "Display and Audio", -75)
        check(frame, "Show Lua script errors", 190, -116, "scriptErrors",
              "Useful when investigating overlapping or broken client frames.")
        check(frame, "Sound enabled", 190, -183, "Sound_EnableAllSound",
              "Controls the native WoW audio system.")
        button(frame, "Advanced Video", 190, -274, 170, 29, function()
            frame:Hide()
            if VideoOptionsFrame then VideoOptionsFrame:Show()
            elseif GameMenuButtonOptions and GameMenuButtonOptions.Click then GameMenuButtonOptions:Click() end
        end)
        button(frame, "Advanced Sound", 386, -274, 170, 29, function()
            frame:Hide()
            if SoundOptionsFrame then SoundOptionsFrame:Show()
            elseif GameMenuButtonSoundOptions then GameMenuButtonSoundOptions:Click() end
        end)
    elseif tab == "Accessibility" then
        sectionTitle(frame, "Accessibility", -75)
        check(frame, "Show chat bubbles", 190, -115, "chatBubbles",
              "Shows dialogue bubbles above players when supported by the client.")
        check(frame, "Sticky targeting", 190, -183, "stickyTargeting",
              "Keep your current target when clicking away.")
        button(frame, "Key Bindings", 190, -284, 170, 29, function()
            frame:Hide()
            if KeyBindingFrame and KeyBindingFrame.Show then KeyBindingFrame:Show()
            elseif GameMenuButtonKeybindings then GameMenuButtonKeybindings:Click() end
        end)
    end
end

local function create()
    frame = CreateFrame("Frame", "AzerothForeverNativeSettingsFrame", UIParent)
    frame:SetWidth(740)
    frame:SetHeight(477)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 25)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true, tileSize=32, edgeSize=30,
        insets={left=8,right=8,top=8,bottom=8}
    })
    frame:SetBackdropColor(0.03,0.04,0.055,0.97)
    local title = frame:CreateFontString(nil, "OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -22)
    title:SetText("Settings")
    local sub = frame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    sub:SetPoint("TOP",title,"BOTTOM",0,-8)
    sub:SetText("Azeroth Forever — Native Client Settings")
    local close = CreateFrame("Button",nil,frame,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-7,-7)
    close:SetScript("OnClick",function() frame:Hide() end)
    local left = frame:CreateTexture(nil,"BACKGROUND")
    left:SetTexture("Interface\\Buttons\\WHITE8X8")
    left:SetVertexColor(.06,.07,.10,.94)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 15,-64)
    left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 167,18)
    for i,tab in ipairs({"Interface","Gameplay","Display","Accessibility"}) do
        local b = CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        b:SetWidth(135)
        b:SetHeight(29)
        b:SetPoint("TOPLEFT",frame,"TOPLEFT",21,-88-(i-1)*43)
        b:SetText(tab)
        b:SetScript("OnClick",function() showTab(tab) end)
    end
    local footer = frame:CreateFontString(nil, "OVERLAY","GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",187,20)
    footer:SetText("Built into the patched game client. No additional add-on is required.")
    frame:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames,"AzerothForeverNativeSettingsFrame") end
end

function AF.OpenSettings()
    if not frame then create() end
    if frame:IsShown() then frame:Hide() return end
    showTab(activeTab)
    frame:Show()
end

-- Route the existing Escape > Interface/Options button to the native settings
-- panel without adding another overlapping menu button.
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    create()
    local existing = _G.GameMenuButtonUIOptions or _G.GameMenuButtonOptions
    if existing then
        existing:SetText("Settings")
        existing:SetScript("OnClick",function()
            if GameMenuFrame then GameMenuFrame:Hide() end
            AF.OpenSettings()
        end)
    end
end)
