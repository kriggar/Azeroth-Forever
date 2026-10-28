-- Azeroth Forever | native modern Talent panel for Conquest of Azeroth.
-- Loaded by the CLIENT FrameXML patch (never from Interface/AddOns).
-- IMPORTANT: CoA classes use CoATalentFrame and C_CharacterAdvancement,
-- not the normal WotLK three-tab PlayerTalentFrame + GetTalentInfo system.
-- ONLY skin original CoA controls. Their scripts, event registrations,
-- class/spec tree data, pending talent decisions and server opcodes are sacred.

local AF = AzerothForeverNative or {}
AzerothForeverNative = AF
AF.CoATalents = AF.CoATalents or {}
local R = AF.CoATalents

local function inCoA()
    return type(IsCustomClass) == "function" and IsCustomClass()
end

local function uiError(msg)
    if type(AF.Notice) == "function" then AF.Notice("CoA Talents: " .. msg) end
end

local function modernAtlas(tex, name)
    if not tex then return false end
    local F = _G.ForeverUI
    if not F or type(F.AtlasEntry) ~= "function" then return false end
    local e = F.AtlasEntry(name)
    if not e then return false end
    tex:SetTexture(e[1])
    tex:SetTexCoord(e[2], e[3], e[4], e[5])
    return true
end

local function setStone(parent, x)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetWidth(637)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)
    t:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, 0)
    if not modernAtlas(t, "talents-background-c60") then
        t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    end
    t:SetAlpha(0.95)
    return t
end

local function resetTextStyle(fs, font, r, g, b)
    if not fs then return end
    fs:SetFontObject(font or GameFontNormalLarge)
    if r then fs:SetTextColor(r, g, b) end
end

-- Check the full class/spec control chain before doing any work. Never take
-- ownership of the actual CoA OnClick, OnEvent, NodeMap, Save or Undo handlers.
function R.HasOriginalHandlers(root)
    if not root or not root.TreeView or not root.SpecView then return false end
    local tree = root.TreeView
    local bottom = tree.BottomBar
    if not bottom or not tree.ClassTree or not tree.SpecTree then return false end
    if not bottom.SaveChanges or not bottom.UndoButton or
       not bottom.ChangeSpec or not bottom.Search then return false end
    if type(_G.C_CharacterAdvancement) ~= "table" then return false end
    if type(C_CharacterAdvancement.GetActiveChrSpec) ~= "function" or
       type(C_CharacterAdvancement.CanApplyPendingBuild) ~= "function" then return false end
    return true
end

function R.Style()
    if not inCoA() then return false end
    local panel = _G.CoATalentFrame
    if not R.HasOriginalHandlers(panel) then return false end
    if panel.afForeverTalentStyled then return true end

    local view = panel.TreeView
    local bar = view.BottomBar

    -- Original CoA node widgets, spec IDs, levels, currencies, save/cancel
    -- handlers and prerequisite lines remain in the original tree frames.
    panel.afForeverTalentStyled = true

    -- Two modern art columns (CoA Class + Spec), not Blizzard's three
    -- WotLK/Forever class spec columns. The data comes from existing CoA.
    local art = CreateFrame("Frame", "AzerothForeverCoATalentsArt", view)
    art:SetAllPoints(view)
    art:SetFrameLevel(math.max(0, view:GetFrameLevel() - 1))
    art:EnableMouse(false)
    setStone(art, 0)
    setStone(art, 637)
    R.art = art

    -- The CoA client's old opaque art is reduced to a faint class-specific
    -- tint. The actual nodes, mouse targets and connections stay untouched.
    for _, key in ipairs({ "Background1", "Background2", "Background3" }) do
        local layer = view[key]
        if layer and layer.SetAlpha then
            layer:SetAlpha(key == "Background1" and 0.1 or 0.025)
        end
    end

    -- Forever talent frame border art from the already-packaged GPL port.
    local separator = view:CreateTexture(nil, "BORDER")
    separator:SetWidth(14)
    separator:SetPoint("TOP", view, "TOP", 0, -45)
    separator:SetPoint("BOTTOM", view, "BOTTOM", 0, 65)
    if not modernAtlas(separator, "talents-divider-vertical-c60") then
        separator:SetTexture("Interface\\Buttons\\WHITE8X8")
        separator:SetVertexColor(0.52, 0.43, 0.24, 0.8)
    end

    local border = CreateFrame("Frame", "AzerothForeverCoATalentsBorder", view)
    border:SetAllPoints(view)
    border:EnableMouse(false)
    border:SetFrameLevel(view:GetFrameLevel() + 2)
    if _G.ForeverUI and type(ForeverUI.CreateNineSlice) == "function" then
        pcall(ForeverUI.CreateNineSlice, border, "talents-inner-frame-c60",
              24, { 0, 0, 0, 0 }, "OVERLAY")
    end

    -- Keep the existing labels and point counts connected to CoA updates,
    -- only change typography.
    for _, t in ipairs({ view.ClassTree, view.SpecTree }) do
        resetTextStyle(t.Label, GameFontNormalLarge, 1, 0.83, 0.44)
        resetTextStyle(t.Points, GameFontNormalLarge)
    end

    if bar.Texture then bar.Texture:SetAlpha(0.25) end
    local bottomArt = bar:CreateTexture(nil, "BACKGROUND")
    bottomArt:SetAllPoints(bar)
    bottomArt:SetTexture("Interface\\Buttons\\WHITE8X8")
    bottomArt:SetVertexColor(0.045, 0.05, 0.065, 0.97)

    -- Single CoA search: this is the SAME EditBox that runs
    -- C_CharacterAdvancement.SetFilteredEntries(), no second search.
    local old = bar.Search
    old:SetWidth(212)
    old:SetHeight(24)
    old:ClearAllPoints()
    old:SetPoint("RIGHT", bar.SaveChanges, "LEFT", -30, 0)

    -- Preserve the exact buttons' original OnClick handlers, especially:
    -- CharacterAdvancementUtil.ConfirmApplyPendingBuild() (Save),
    -- C_CharacterAdvancement.CancelPendingBuild() (Undo),
    -- and the native CoA specialization chooser.
    bar.SaveChanges:SetWidth(164)
    bar.SaveChanges:SetHeight(27)
    bar.ChangeSpec:SetWidth(164)
    bar.ChangeSpec:SetHeight(27)

    -- CoA has specializations; the spec-selection view remains the original
    -- ClassInfo-driven view, presented in the same modern outer shell.
    if panel.SpecView.Background then
        panel.SpecView.Background:SetAlpha(0.22)
    end

    R.panel = panel
    return true
end

function R.RemoveAscensionCollectionTabs()
    if not inCoA() then return end
    local collections = _G.Collections
    if not collections or not collections.Tabs then return end
    if R.tabsPruned then return end
    -- The core tab is mandatory. Vanity and the old Ascension Wardrobe are
    -- removed from navigation; Forever transmog lives at an NPC panel.
    if not collections.Tabs.CharacterAdvancement then return end
    if type(collections.HideTabID) == "function" then
        for _, key in ipairs({ "Vanity", "Wardrobe", "SeasonalCollection",
                                "MysticEnchants", "SkillCards" }) do
            local id = collections.Tabs[key]
            if id then
                collections:HideTabID(id)
            end
        end
        R.tabsPruned = true
    end
end

function R.Fit()
    local panel = _G.CoATalentFrame
    local collections = _G.Collections
    if not (panel and collections and UIParent) then return end
    if InCombatLockdown and InCombatLockdown() then return end
    -- The Collections shell is scaled only enough to fit on-screen.
    -- Avoid overriding CoA's original scale on large screens.
    local w, h = collections:GetWidth(), collections:GetHeight()
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    if not w or w <= 0 or not h or h <= 0 then return end
    local original = collections:GetScale() or 1
    local limit = math.min(1, (sw - 90) / w, (sh - 90) / h)
    collections:SetScale(math.min(original, math.max(0.65, limit)))
end

function R.Open()
    if not inCoA() then return false end
    if type(_G.CharacterAdvancement_LoadUI) == "function" then
        pcall(_G.CharacterAdvancement_LoadUI)
    end
    local c = _G.Collections
    if c and c.Tabs and c.Tabs.CharacterAdvancement and
        type(c.GoToTab) == "function" then
        R.RemoveAscensionCollectionTabs()
        c:GoToTab(c.Tabs.CharacterAdvancement)
        R.Style()
        R.Fit()
        return true
    end
    uiError("CoA Character Advancement is not loaded. Use its native N key.")
    return false
end
AF.OpenTalents = R.Open

local function attach()
    if not inCoA() then return end
    local p = _G.CoATalentFrame
    if not p or p.afForeverTalentHooked then return end
    p.afForeverTalentHooked = true
    p:HookScript("OnShow", function()
        R.Style()
        R.RemoveAscensionCollectionTabs()
        R.Fit()
    end)
    R.Style()
    R.RemoveAscensionCollectionTabs()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_LOGIN" or event == "PLAYER_REGEN_ENABLED" or
       (event == "ADDON_LOADED" and
        (name == "Ascension_CoATalents" or name == "Ascension_Collections")) then
        attach()
    end
end)
-- CoA's UI is load-on-demand; a low-frequency fallback handles builds that
-- do not fire the standard addon event when the patched client loads it.
events.elapsed = 0
events:SetScript("OnUpdate", function(self, dt)
    if not inCoA() or self.discovered then return end
    self.elapsed = self.elapsed + (dt or 0)
    if self.elapsed >= 1 then
        self.elapsed = 0
        attach()
        if _G.CoATalentFrame and _G.CoATalentFrame.afForeverTalentHooked then
            self.discovered = true
            self:SetScript("OnUpdate", nil)
        end
    end
end)
