-- Azeroth Forever native UI — 3.3.5 frame collision and scaling corrections.
-- Loaded from FrameXML.toc, NOT Interface/AddOns.
-- All CoA class abilities, resource bars and custom class menus remain intact.

AzerothForeverNative = AzerothForeverNative or {}
local AF = AzerothForeverNative
AF.version = "native-ui-0.3"
AF.overlapFixes = 0
AF.searchSuppressed = {}
AF.defaultScale = 0.82

local function notice(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffc2a768Azeroth Forever UI:|r " .. tostring(msg))
    end
end
AF.Notice = notice

local function readCVar(key)
    if type(GetCVar) ~= "function" then return nil end
    local ok, value = pcall(GetCVar, key)
    if ok and value ~= "" then return value end
end

function AF.SetScale(scale, save)
    scale = tonumber(scale)
    if not scale then return false end
    scale = math.max(0.64, math.min(1, math.floor(scale * 100 + 0.5) / 100))
    if InCombatLockdown and InCombatLockdown() then
        notice("Change the UI scale after combat.")
        return false
    end
    if type(SetCVar) == "function" then
        pcall(SetCVar, "useUiScale", "1")
        pcall(SetCVar, "uiScale", tostring(scale))
    end
    if UIParent and UIParent.SetScale then
        UIParent:SetScale(scale)
    end
    AF.scale = scale
    if save ~= false then
        notice("UI scale: " .. tostring(math.floor(scale * 100 + 0.5)) .. "%")
    end
    return true
end

function AF.CurrentScale()
    return tonumber(readCVar("uiScale")) or AF.scale or 1
end

local function overlaps(a, b)
    if not a or not b or not a:IsShown() or not b:IsShown() or a == b then return false end
    local aL, aR, aT, aB = a:GetLeft(), a:GetRight(), a:GetTop(), a:GetBottom()
    local bL, bR, bT, bB = b:GetLeft(), b:GetRight(), b:GetTop(), b:GetBottom()
    if not (aL and aR and aT and aB and bL and bR and bT and bB) then return false end
    local x = math.max(0, math.min(aR, bR) - math.max(aL, bL))
    local y = math.max(0, math.min(aT, bT) - math.max(aB, bB))
    local area = x * y
    local aArea = (aR-aL)*(aT-aB)
    local bArea = (bR-bL)*(bT-bB)
    return aArea > 0 and bArea > 0 and area >= math.min(aArea,bArea) * 0.28
end

-- Only the separate Ascension vanity wardrobe / microbuttons are hidden.
-- The native/transmog appearance collection and class form visuals stay.
local VANITY_NAMES = {
    "AscensionVanityFrame", "VanityCollectionFrame", "AscensionVanityCollection",
    "AscensionCosmeticsFrame", "PepeVanityFrame", "VanityMicroButton",
    "AscensionVanityMicroButton"
}
local hiddenVanity = {}
function AF.SuppressAscensionVanity()
    for _,name in ipairs(VANITY_NAMES) do
        local frame=_G[name]
        if frame and not hiddenVanity[name] then
            hiddenVanity[name]=true
            frame:Hide()
            if frame.HookScript then
                frame:HookScript("OnShow", function(self)
                    if self:IsShown() then self:Hide() end
                end)
            end
        end
    end
end


local names = {
    spell = "ForeverUISpellBookSearchBox",
    talent = "ForeverUITalentsSearchBox",
}
local function groupOf(name)
    if not name or not string.find(string.lower(name), "search", 1, true) then
        return nil
    end
    local lower = string.lower(name)
    if string.find(lower, "spell", 1, true) then return "spell" end
    if string.find(lower, "talent", 1, true) then return "talent" end
end

function AF.FixDuplicateSearches()
    -- The patched client has its own spell/talent search in addition to the
    -- modern port. Only suppress an *actual overlapping* legacy search edit
    -- box of the same category. Never alter CoA class searches elsewhere.
    if InCombatLockdown and InCombatLockdown() then return end
    for group, modernName in pairs(names) do
        local modern = _G[modernName]
        if modern and modern:IsShown() then
            local frame = EnumerateFrames()
            while frame do
                local nextFrame = EnumerateFrames(frame)
                if frame ~= modern and frame.GetObjectType and
                    frame:GetObjectType() == "EditBox" and
                    groupOf(frame:GetName()) == group then
                    local n = frame:GetName()
                    if n and not AF.searchSuppressed[n] then
                        -- The same parent screen already has the ForeverUI
                        -- search box; any second spell/talent input is
                        -- redundant even when its border is offset.
                        frame:Hide()
                        local p = frame:GetParent()
                        if p and p.GetName and p:GetName() and
                            string.find(string.lower(p:GetName()),"search",1,true) then
                            p:Hide()
                        end
                        AF.searchSuppressed[n] = frame
                        AF.overlapFixes = AF.overlapFixes + 1
                    end
                end
                frame = nextFrame
            end
        end
    end
end

function AF.RestoreLegacySearches()
    for name, frame in pairs(AF.searchSuppressed) do
        if frame then frame:Show() end
        AF.searchSuppressed[name] = nil
    end
    notice("Legacy search frames restored where available.")
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher.elapsed = 0
watcher:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        local cvar = readCVar("uiScale")
        local enabled = readCVar("useUiScale")
        -- Respect explicit user scaling. If no manual scale was set, choose
        -- a smaller sensible default for the integrated modern UI.
        if enabled == "0" or not cvar then
            AF.SetScale(AF.defaultScale, false)
        else
            AF.scale = tonumber(cvar) or AF.defaultScale
        end
    end
    self.elapsed = 0
end)
watcher:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed < 0.8 then return end
    self.elapsed = 0
    AF.FixDuplicateSearches()
    AF.SuppressAscensionVanity()
end)

SLASH_AZEROTHFOREVERNATIVE1 = "/afui"
SlashCmdList["AZEROTHFOREVERNATIVE"] = function(msg)
    local command, arg = string.match(msg or "", "^%s*(%S*)%s*(.-)%s*$")
    command = string.lower(command or "")
    if command == "scale" then
        if not AF.SetScale(tonumber(arg)) then notice("Usage: /afui scale 0.80") end
    elseif command == "audit" then
        local coa=AF.CoATalents
        local home=AF.CoATreeHome
        local art=AF.CoATreeVisuals
        local micro=AF.MicroMenu
        local menu=AF.GameMenu
        local frame=_G.CoATalentFrame
        notice("Native Client UI Build: " .. tostring(AF.version))
        notice("CoA tree: "..tostring(home and home.treesOpened) ..
               " | original talent controls: "..
               tostring(coa and coa.HasOriginalHandlers and coa.HasOriginalHandlers(frame)))
        notice("Forever talent nodes styled: " .. tostring(art and art.nodeCount or 0) ..
               " | visual errors: " .. tostring(art and art.lastError or "none"))
        local removed=0
        if micro and micro.removed then
            for name in pairs(micro.removed) do removed=removed+1 end
        end
        notice("Micro buttons: "..tostring(micro and micro.lastCount or "n/a")..
               " | custom buttons removed: "..tostring(removed)..
               " | Esc menu: "..tostring(menu and menu.installed))
        local errors=AzerothForeverNativeBootstrap and
                     AzerothForeverNativeBootstrap.errors or {}
        notice("Bootstrap errors: "..tostring(#errors))
    elseif command == "searchrestore" then
        AF.RestoreLegacySearches()
    elseif command == "errors" then
        local errors = AzerothForeverNativeBootstrap and AzerothForeverNativeBootstrap.errors or {}
        notice("Startup errors: " .. #errors .. "; duplicate search corrections: " .. AF.overlapFixes)
        for i=1,math.min(#errors, 5) do notice(errors[i]) end
        notice("For other client errors, enable Interface > Display > Lua errors.")
    elseif command == "settings" or command == "" then
        if AF.OpenSettings then AF.OpenSettings() else notice("The native settings panel is unavailable.") end
    elseif command == "transmog" then
        if AF.OpenTransmog then AF.OpenTransmog(true) else notice("Transmog panel is unavailable.") end
    else
        notice("/afui audit | settings | scale 0.80 | errors | searchrestore")
    end
end
