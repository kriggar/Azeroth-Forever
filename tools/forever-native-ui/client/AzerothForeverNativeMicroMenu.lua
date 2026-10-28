-- Azeroth Forever: native WoW Forever-like micro menu.
-- Restrict the bottom micro strip to the original built-in game functions:
-- character, professions, spellbook, CoA talents, achievements, quests,
-- social, group finder and game menu. Do NOT touch action bar spell slots,
-- CoA custom resource frames, pet bar, stance bar, keybinds or equipment.

local AF=_G.AzerothForeverNative or {}
_G.AzerothForeverNative=AF
local M={}
AF.MicroMenu=M
M.version=1
M.removed={}
M.lastCount=0
M.passes=0
M.allowed={
    CharacterMicroButton=true,
    ForeverUIProfessionMicroButton=true,
    SpellbookMicroButton=true,
    TalentMicroButton=true,
    AchievementMicroButton=true,
    QuestLogMicroButton=true,
    SocialsMicroButton=true,
    LFDMicroButton=true,
    MainMenuMicroButton=true,
}
local function inCombat()
    return type(InCombatLockdown)=="function" and InCombatLockdown()
end
local function notice(s)
    if AF.Notice then AF.Notice("Micro menu: "..tostring(s)) end
end

local function hideUnwanted(button)
    if not button or not button.GetName or not button.Hide then return false end
    local name=button:GetName()
    if not name or name=="" or M.allowed[name] then return false end
    if M.removed[name] then return true end
    -- This is a micro-menu surface, not an action bar or class resource.
    M.removed[name]=true
    button:Hide()
    if button.HookScript then
        button:HookScript("OnShow",function(self)
            -- Some original Ascension UI modules show their buttons again.
            if self:IsShown() then self:Hide() end
        end)
    end
    return true
end

function M.Clean()
    if inCombat() then return false end
    local f=_G.ForeverUI
    local list=f and f.MicroButtons
    local bar=_G.ForeverUIMicroMenu
    if not list or not bar then return false end

    local removed=0
    for i=#list,1,-1 do
        local item=list[i]
        local btn=item and item.button
        local name=btn and btn.GetName and btn:GetName()
        if name and not M.allowed[name] then
            if hideUnwanted(btn) then removed=removed+1 end
            table.remove(list,i)
        end
    end
    local count=#list
    -- Camelot / WoW Forever uses 32x40 buttons with -5px spacing.
    -- Recalculate the strip to avoid invisible/empty gaps left by old
    -- Ascension Trial, prestige, cash shop and custom-system buttons.
    local width=count>0 and (count*32+(count-1)*-5) or 32
    bar:SetWidth(width)
    for i,item in ipairs(list) do
        local btn=item.button
        if btn and btn.ClearAllPoints and btn.SetPoint then
            btn:ClearAllPoints()
            btn:SetPoint("LEFT",bar,"LEFT",(i-1)*27,0)
            if M.allowed[btn:GetName()] and not btn:IsShown() then btn:Show() end
        end
    end
    -- Some Ascension entries were never registered through ForeverUI's
    -- AddMicroButton. If they are direct children of the micro container
    -- and are buttons, suppress them too. Parent/character/action bars
    -- remain intact because only the dedicated micro frame is inspected.
    if bar.GetChildren then
        for _,child in ipairs({bar:GetChildren()}) do
            if child and child.GetObjectType and child:GetObjectType()=="Button" then
                if hideUnwanted(child) then removed=removed+1 end
            end
        end
    end
    M.lastCount=count
    M.passes=M.passes+1
    return true
end

local f=CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent",function() M.Clean() end)
f.elapsed=0
f:SetScript("OnUpdate",function(self,dt)
    self.elapsed=self.elapsed+(dt or 0)
    if self.elapsed<1.5 then return end
    self.elapsed=0
    M.Clean()
end)
