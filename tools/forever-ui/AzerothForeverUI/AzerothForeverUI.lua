-- Azeroth Forever UI (WoW 3.3.5-compatible Lua 5.1)
-- Inspired by WoW: Forever's modern interface principles, not a copy of
-- Blizzard's proprietary 2026 client UI. Uses textures bundled with the client.
-- Never overrides class resource frames, spell casting, achievements or talents.

local ADDON_NAME = "AzerothForeverUI"
local settings
local systemBar
local nativeHidden = false
local buttons = {}

local function Say(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffd9b76d[Azeroth Forever UI]|r " .. tostring(message))
    end
end

local function SafeToggle(name, ...)
    local fn = _G[name]
    if type(fn) == "function" then
        return fn(...)
    end
    Say(name .. " is not available in this client build.")
end

local function Achievements()
    if type(IsAddOnLoaded) == "function"
        and not IsAddOnLoaded("Blizzard_AchievementUI")
        and type(LoadAddOn) == "function" then
        pcall(LoadAddOn, "Blizzard_AchievementUI")
    end

    if type(ToggleAchievementFrame) == "function" then
        ToggleAchievementFrame()
    elseif type(AchievementFrame_ToggleAchievementFrame) == "function" then
        AchievementFrame_ToggleAchievementFrame()
    elseif AchievementFrame then
        if AchievementFrame:IsShown() then
            AchievementFrame:Hide()
        else
            AchievementFrame:Show()
        end
    else
        Say("The native achievement window is unavailable; check Blizzard_AchievementUI.")
    end
end

local function ShowGuild()
    if type(ToggleGuildFrame) == "function" then
        ToggleGuildFrame()
    elseif type(ToggleFriendsFrame) == "function" then
        ToggleFriendsFrame(3)
    else
        Say("The guild window is unavailable in this client build.")
    end
end

local function ShowMenu()
    if type(ToggleGameMenu) == "function" then
        ToggleGameMenu()
    elseif GameMenuFrame then
        if GameMenuFrame:IsShown() then
            GameMenuFrame:Hide()
        else
            GameMenuFrame:Show()
        end
    end
end

-- Buttons provide actual client actions; custom class UI is kept intact.
local menuItems = {
    { id="character", title="Character", icon="Interface\\Icons\\INV_Misc_Head_Human_01", action=function() SafeToggle("ToggleCharacter", "PaperDollFrame") end },
    { id="spells", title="Spellbook", icon="Interface\\Icons\\INV_Misc_Book_08", action=function() SafeToggle("ToggleSpellBook", BOOKTYPE_SPELL) end },
    { id="talents", title="Talents", icon="Interface\\Icons\\Ability_Marksmanship", action=function() SafeToggle("ToggleTalentFrame") end },
    { id="achievements", title="Achievements", icon="Interface\\Icons\\Achievement_General", action=Achievements },
    { id="quests", title="Quest Log", icon="Interface\\Icons\\INV_Misc_Book_11", action=function() SafeToggle("ToggleQuestLog") end },
    { id="social", title="Social", icon="Interface\\Icons\\Spell_Holy_PrayerOfSpirit", action=function() SafeToggle("ToggleFriendsFrame") end },
    { id="guild", title="Guild", icon="Interface\\Icons\\INV_BannerPVP_01", action=ShowGuild },
    { id="pvp", title="PvP", icon="Interface\\Icons\\Achievement_PVP_A_01", action=function() SafeToggle("TogglePVPFrame") end },
    { id="bags", title="Backpack", icon="Interface\\Icons\\INV_Misc_Bag_08", action=function() SafeToggle("ToggleBackpack") end },
    { id="system", title="System / Game Menu", icon="Interface\\Icons\\INV_Misc_Gear_01", action=ShowMenu }
}

local nativeMicroNames = {
    "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
    "AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
    "GuildMicroButton", "PVPMicroButton", "LFDMicroButton",
    "MainMenuMicroButton", "HelpMicroButton"
}

local function UpdateNativeUI()
    if not systemBar then return end
    local enabled = settings and settings.enabled
    if enabled then systemBar:Show() else systemBar:Hide() end

    if enabled then
        -- Only the standard micro menu is replaced. Action bars, spell UI,
        -- Blizzard achievement state, class HUD, minimap and quest frames
        -- remain fully functional.
        for _, name in ipairs(nativeMicroNames) do
            local original = _G[name]
            if original and original.Hide then original:Hide() end
        end
        nativeHidden = true
    elseif nativeHidden then
        for _, name in ipairs(nativeMicroNames) do
            local original = _G[name]
            if original and original.Show then original:Show() end
        end
        nativeHidden = false
    end
end

local function CreateMenuButton(parent, item, index)
    local button = CreateFrame("Button", "AFUI_" .. item.id, parent)
    button:SetWidth(33)
    button:SetHeight(33)
    button:RegisterForClicks("LeftButtonUp")
    button:SetPoint("LEFT", parent, "LEFT", 11 + (index - 1) * 37, 0)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.07, 0.09, 0.13, 0.95)

    local border = CreateFrame("Frame", nil, button)
    border:SetAllPoints(button)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    border:SetBackdropBorderColor(0.37, 0.32, 0.23, 0.85)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(item.icon)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
    icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(button)

    button:SetScript("OnClick", function()
        local ok, err = pcall(item.action)
        if not ok then Say("Could not open " .. item.title .. ": " .. tostring(err)) end
    end)
    button:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(item.title, 1, 0.86, 0.55)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return button
end

local function BuildUI()
    if systemBar then return end
    systemBar = CreateFrame("Frame", "AzerothForeverSystemBar", UIParent)
    systemBar:SetWidth(#menuItems * 37 + 18)
    systemBar:SetHeight(49)
    systemBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -22, 8)
    systemBar:SetFrameStrata("HIGH")
    systemBar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left=4, right=4, top=4, bottom=4 }
    })
    systemBar:SetBackdropColor(0.035, 0.055, 0.085, 0.93)
    systemBar:SetBackdropBorderColor(0.41, 0.33, 0.19, 0.95)

    for i, item in ipairs(menuItems) do
        buttons[i] = CreateMenuButton(systemBar, item, i)
    end

    -- Retain the native action bars and CoA class-specific action mechanisms.
    UpdateNativeUI()
end

SLASH_AZEROTHFOREVERUI1 = "/afui"
SlashCmdList["AZEROTHFOREVERUI"] = function(message)
    message = string.lower(message or "")
    if message == "off" then
        settings.enabled = false
    elseif message == "on" then
        settings.enabled = true
    elseif message == "toggle" then
        settings.enabled = not settings.enabled
    elseif message == "reset" then
        AzerothForeverUISettings = { enabled = true }
        settings = AzerothForeverUISettings
    elseif message == "achievements" then
        Achievements()
        return
    else
        Say("Commands: /afui on, /afui off, /afui toggle, /afui achievements, /afui reset")
        return
    end
    UpdateNativeUI()
    Say(settings.enabled and "Forever-style system bar enabled." or "Native system menu restored.")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        AzerothForeverUISettings = AzerothForeverUISettings or {}
        settings = AzerothForeverUISettings
        if settings.enabled == nil then settings.enabled = true end
    elseif event == "PLAYER_LOGIN" then
        if not settings then
            AzerothForeverUISettings = AzerothForeverUISettings or { enabled = true }
            settings = AzerothForeverUISettings
        end
        BuildUI()
        if type(hooksecurefunc) == "function" and type(UpdateMicroButtons) == "function" then
            hooksecurefunc("UpdateMicroButtons", function()
                if settings and settings.enabled and not (InCombatLockdown and InCombatLockdown()) then
                    UpdateNativeUI()
                end
            end)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateNativeUI()
    end
end)
