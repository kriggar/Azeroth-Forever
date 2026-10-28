-- Azeroth Forever | Native NPC-driven Transmogrify window, WoW 3.3.5 Lua.
-- This is loaded by the game's FrameXML, NOT Interface/AddOns.
-- The outfit/appearance layout follows the WoW: Forever 2026 beta system.
-- The server-side appearance application requires the separately installed,
-- open-source mod-transmog-plus compatible backend. Never fake a successful save.
-- Original item equipment stats and all 21 CoA class resources remain untouched.

local AF = AzerothForeverNative
if not AF then return end

local S = {
    slots = {
        { id=0,  name="Head",      x=77,  y=-118 },
        { id=2,  name="Shoulders", x=77,  y=-165 },
        { id=4,  name="Chest",     x=77,  y=-212 },
        { id=5,  name="Waist",     x=77,  y=-259 },
        { id=6,  name="Legs",      x=77,  y=-306 },
        { id=7,  name="Feet",      x=77,  y=-353 },
        { id=8,  name="Wrists",    x=419, y=-118 },
        { id=9,  name="Hands",     x=419, y=-165 },
        { id=14, name="Back",      x=419, y=-212 },
        { id=15, name="Main Hand", x=419, y=-259 },
        { id=16, name="Off Hand",  x=419, y=-306 },
        { id=17, name="Ranged",    x=419, y=-353 }
    },
    chosenSlot=0,
    slotsFromServer={}, choices={}, pending={},
    latestChunk={}, rows={}, active=false, capable=false,
    owner=nil, npcOpen=false, outfit=1, outfits={{},{}},
    backendNotices=0,
}
AF.Transmog = S

local function message(m)
    AF.Notice("Transmog: " .. m)
end
local function c(text)
    return {1,0.82,0.42}
end
local function backdrop(frame)
    frame:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=32,edgeSize=24,
        insets={left=6,right=6,top=6,bottom=6}
    })
    frame:SetBackdropColor(.032,.035,.044,.97)
end
local function label(parent,str,x,y,w,style)
    local fs=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlight")
    fs:SetWidth(w or 160)
    fs:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    fs:SetJustifyH("LEFT")
    fs:SetText(str)
    return fs
end
local function uiButton(parent,text,x,y,w,h,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetWidth(w) b:SetHeight(h)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(text)
    if fn then b:SetScript("OnClick",fn) end
    return b
end
local function send(command)
    if not S.npcOpen then
        message("Talk to a city transmogrifier to use this panel.")
        return false
    end
    if not S.capable or type(SendAddonMessage)~="function" then
        message("No compatible transmog server backend is active; no changes applied.")
        return false
    end
    local name=UnitName("player")
    if not name then return false end
    SendAddonMessage("transmog", command, "WHISPER",name)
    return true
end
local function iconFor(id)
    if id == 999999 then return "Interface\\Icons\\Ability_Spy" end
    if id == 0 then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    local path=GetItemIcon and GetItemIcon(id)
    return path or "Interface\\Icons\\INV_Misc_QuestionMark"
end
local function itemLink(id)
    return "item:"..tostring(id)..":0:0:0:0:0:0:0"
end
local function equipped(slot)
    return GetInventoryItemLink and GetInventoryItemLink("player",slot+1) or nil
end

local function drawPreview()
    if not S.model then return end
    S.model:SetUnit("player")
    -- TryOn only modifies the visual model, not equipped items or stats.
    for slot,itemID in pairs(S.pending) do
        if itemID and itemID>0 and itemID~=999999 and S.model.TryOn then
            pcall(S.model.TryOn,S.model,itemLink(itemID))
        end
    end
end

local function showSlot(slot)
    S.chosenSlot=slot
    local spec
    for _,t in ipairs(S.slots) do
        if t.id==slot then spec=t break end
    end
    if S.slotTitle then S.slotTitle:SetText(spec and spec.name or "Appearance") end
    local entries=S.choices[slot] or {}
    for i,row in ipairs(S.rows) do
        local id=entries[i]
        if id then
            row.id=id
            row.icon:SetTexture(iconFor(id))
            row:Show()
        else
            row.id=nil
            row:Hide()
        end
    end
    if S.empty then
        S.empty:SetShown(false)
        if #entries==0 then
            S.empty:SetText(S.capable and "No collected appearances for this slot."
                or "A transmog server backend is required to load appearances.")
            S.empty:Show()
        end
    end
end

local function choose(id)
    if not S.capable then message("No transmog backend; the appearance was not applied.") return end
    S.pending[S.chosenSlot]=id
    S.outfits[S.outfit][S.chosenSlot]=id
    drawPreview()
    if S.selection then
        S.selection:SetText("Selected: " .. (GetItemInfo(id) or "Appearance " .. tostring(id)))
    end
end

local function apply()
    if not S.capable or not S.npcOpen then
        message("Talk to a transmogrifier on a compatible server before saving an outfit.")
        return
    end
    local n=0
    -- The backend validates class/armor/weapon/level requirements, costs
    -- and ownership. This client sends only the requested slot and item ID.
    for slot,id in pairs(S.pending) do
        if id==0 then
            if send("Remove:" .. slot) then n=n+1 end
        elseif id and id>0 then
            if send("Apply:" .. slot .. ":" .. id) then n=n+1 end
        end
    end
    if n==0 then message("No changes selected.") return end
    message("Requested " .. n .. " slot change(s); waiting for server confirmation.")
end

local function split(source, delimiter)
    local result={}
    for part in string.gmatch(source, "[^" ..delimiter.. "]+") do
        table.insert(result, part)
    end
    return result
end

local function readProtocol(data)
    if data=="Open" then
        S.npcOpen=true
        S.capable=true
        if S.frame then S.frame:Show() end
        send("GetTransmogStatus")
        send("GetAvailableTransmogs")
        return
    end
    local parts=split(data,":")
    if parts[1]=="AvailableTransmogs" then
        local slot=tonumber(parts[2])
        local segment=parts[5]
        if not slot then return end
        if segment=="start" then
            S.latestChunk[slot]={}
        elseif segment=="end" then
            S.choices[slot]=S.latestChunk[slot] or {}
            if S.chosenSlot==slot then showSlot(slot) end
        else
            local list=S.latestChunk[slot] or {}
            for i=5,#parts do
                local id=tonumber(parts[i])
                if id and id>0 then table.insert(list,id) end
            end
            S.latestChunk[slot]=list
        end
    elseif parts[1]=="TransmogStatus" then
        S.slotsFromServer={}
        for i=3,#parts do
            local pair=split(parts[i],",")
            local slot,id=tonumber(pair[1]),tonumber(pair[2])
            if slot and id then S.slotsFromServer[slot]=id end
        end
    elseif parts[1]=="ApplyTransmogResult" then
        if parts[2]=="1" then
            local pair=split(parts[3] or "",",")
            local slot,id=tonumber(pair[1]),tonumber(pair[2])
            if slot then
                S.slotsFromServer[slot]=id
                S.pending[slot]=nil
            end
            message("Appearance saved by the server.")
            drawPreview()
        else
            message("The server rejected this change. Check item, level and armor compatibility.")
        end
    elseif parts[1]=="CollectionUpdated" then
        if S.npcOpen then send("GetAvailableTransmogs") end
    end
end

local function make()
    local f=CreateFrame("Frame","AzerothForeverNativeTransmogFrame",UIParent)
    S.frame=f
    f:SetWidth(1020) f:SetHeight(555)
    f:SetPoint("CENTER",UIParent,"CENTER",0,18)
    f:SetFrameStrata("DIALOG")
    backdrop(f)
    f:EnableMouse(true)
    f:SetMovable(true) f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) if not InCombatLockdown() then self:StartMoving() end end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    local title=label(f,"TRANSMOGRIFY",455,-17,190,"GameFontNormalLarge")
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-9)
    close:SetScript("OnClick",function() f:Hide() end)

    local left=CreateFrame("Frame",nil,f)
    left:SetPoint("TOPLEFT",f,"TOPLEFT",14,-58)
    left:SetWidth(174) left:SetHeight(472)
    backdrop(left)
    label(left,"OUTFITS",16,-17,130,"GameFontNormal")
    for i=1,2 do
        uiButton(left,"Outfit "..i,11,-55-(i-1)*43,150,30,function()
            S.outfit=i
            S.pending={}
            for slot,id in pairs(S.outfits[i]) do S.pending[slot]=id end
            drawPreview()
            showSlot(S.chosenSlot)
        end)
    end
    label(left,"Your saved equipment look is applied through the transmogrifier.",12,-184,147,"GameFontHighlightSmall")
    label(left,"Collections remain available when you disable others' transmogs.",12,-279,147,"GameFontHighlightSmall")

    local center=CreateFrame("Frame",nil,f)
    center:SetPoint("TOPLEFT",f,"TOPLEFT",197,-58)
    center:SetWidth(529) center:SetHeight(472)
    backdrop(center)
    label(center,"SHOW CURRENTLY EQUIPPED GEAR",125,-19,280,"GameFontHighlightSmall")
    local model=CreateFrame("DressUpModel","AzerothForeverNativeTransmogModel",center)
    S.model=model
    model:SetPoint("TOPLEFT",center,"TOPLEFT",116,-50)
    model:SetWidth(300) model:SetHeight(343)
    model:SetUnit("player")
    model:SetFacing(0)
    for _,spec in ipairs(S.slots) do
        local slot=spec.id
        local b=CreateFrame("Button",nil,center)
        b:SetWidth(36) b:SetHeight(36)
        b:SetPoint("TOPLEFT",center,"TOPLEFT",spec.x-50,spec.y+32)
        local tex=b:CreateTexture(nil,"ARTWORK")
        tex:SetAllPoints(b)
        tex:SetTexture(equipped(slot) and iconFor(tonumber(string.match(equipped(slot),"item:(%d+)")) or 0) or iconFor(0))
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
        b:SetScript("OnClick",function() showSlot(slot) end)
        b:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(spec.name,1,0.82,0.33)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    local showEquipment=uiButton(center,"Show Equipped Gear",132,-414,175,27,function()
        S.pending={}
        drawPreview()
    end)
    local rotateL=uiButton(center,"Rotate Left",18,-414,100,27,function()
        if model.GetFacing then model:SetFacing(model:GetFacing()+0.2) end
    end)
    local rotateR=uiButton(center,"Rotate Right",329,-414,105,27,function()
        if model.GetFacing then model:SetFacing(model:GetFacing()-0.2) end
    end)
    local right=CreateFrame("Frame",nil,f)
    right:SetPoint("TOPLEFT",f,"TOPLEFT",731,-58)
    right:SetWidth(275) right:SetHeight(472)
    backdrop(right)
    S.slotTitle=label(right,"Head",19,-20,220,"GameFontNormalLarge")
    S.selection=label(right,"Select a collected appearance",17,-53,245,"GameFontHighlightSmall")
    S.rows={}
    for n=1,24 do
        local row=CreateFrame("Button",nil,right)
        local col=math.mod(n-1,4)
        local rr=math.floor((n-1)/4)
        row:SetWidth(50) row:SetHeight(50)
        row:SetPoint("TOPLEFT",right,"TOPLEFT",15+col*61,-86-rr*53)
        row.icon=row:CreateTexture(nil,"ARTWORK")
        row.icon:SetAllPoints(row)
        row:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
        row:SetScript("OnClick",function(self) if self.id then choose(self.id) end end)
        row:SetScript("OnEnter",function(self)
            if not self.id then return end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink(self.id))
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        table.insert(S.rows,row)
    end
    S.empty=label(right,"",14,-165,244,"GameFontHighlightSmall")
    uiButton(f,"Hide Selected Slot",766,-494,145,25,function()
        local allow={ [0]=true,[2]=true,[4]=true,[5]=true,[6]=true,
            [7]=true,[8]=true,[9]=true,[14]=true }
        if not allow[S.chosenSlot] then
            message("Only armor and cloak slots can be hidden.") return
        end
        choose(999999)
    end)
    uiButton(f,"Use Equipped Item",912,-494,97,25,function() choose(0) end)
    uiButton(f,"Save Outfit",24,-494,150,25,apply)
    local note=label(f,"Appearance changes are validated and saved by the server.",210,-499,510,"GameFontHighlightSmall")
    f:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames,"AzerothForeverNativeTransmogFrame") end
    f:SetScript("OnHide",function()
        S.npcOpen=false
        S.capable=false
    end)
    showSlot(0)
end

function AF.OpenTransmog(previewOnly)
    if not S.frame then make() end
    if previewOnly and not S.npcOpen then
        message("Preview only. Talk to a transmogrifier NPC to apply changes.")
    end
    S.frame:Show()
    showSlot(S.chosenSlot)
    drawPreview()
end

local listener=CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:RegisterEvent("GOSSIP_SHOW")
listener:RegisterEvent("GOSSIP_CLOSED")
listener:RegisterEvent("PLAYER_LOGIN")
listener:SetScript("OnEvent",function(self,event,prefix,data,channel)
    if event=="PLAYER_LOGIN" then
        if not S.frame then make() end
        return
    end
    if event=="GOSSIP_CLOSED" then
        if S.frame and S.frame:IsShown() and S.npcOpen then
            S.frame:Hide()
        end
        return
    end
    if event=="GOSSIP_SHOW" then
        if S.npcOpen then
            if GossipFrame then GossipFrame:Hide() end
            AF.OpenTransmog(false)
        end
        return
    end
    if event=="CHAT_MSG_ADDON" and prefix=="transmog" and type(data)=="string" then
        readProtocol(data)
    end
end)
