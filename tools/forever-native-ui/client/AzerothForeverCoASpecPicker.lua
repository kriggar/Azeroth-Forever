-- Azeroth Forever: World of Warcraft: Forever-styled CoA spec selection.
--
-- The original CoA selection screen shows up to 4 giant portrait cards.
-- This replaces only that PRESENTATION with a modern Talent window: a slim
-- spec selector, large active-spec detail, and an entry into the actual
-- *connected* Class/Spec CoA talent trees. No new talents are generated.
--
-- This loads via FrameXML in the original client, never a new addon.
-- CoASpecChoiceMixin:OnSelected() remains the ONLY commit pathway.
-- CoA specialization IDs, rules, skill trees, abilities, points, tooltips,
-- prereqs and server RPC are deliberately not modified.

local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
AF.CoASpecPicker = AF.CoASpecPicker or {}
local R = AF.CoASpecPicker
R.version = "1.0.0"
R.count = 0
R.lastError = nil
R.buttons = {}
R.entries = {}

local function output(s)
    if AF.Notice then AF.Notice("CoA spec picker: " .. tostring(s)) end
end
local function atl(texture, name)
    local F = _G.ForeverUI
    if not F or type(F.SetAtlas) ~= "function" then return false end
    local ok, result = pcall(F.SetAtlas, texture, name, true)
    return ok and result == true
end
local function flat(parent, level, r, g, b, a)
    local t=parent:CreateTexture(nil, level or "BACKGROUND")
    t:SetTexture("Interface\Buttons\WHITE8X8")
    t:SetVertexColor(r or .04,g or .05,b or .07,a or 1)
    return t
end
local function label(p, value, style, x, y, width, color)
    local s=p:CreateFontString(nil,"ARTWORK",style or "GameFontHighlight")
    s:SetPoint("TOPLEFT",p,"TOPLEFT",x,y)
    s:SetWidth(width or 250)
    s:SetJustifyH("LEFT")
    s:SetText(value or "")
    if color then s:SetTextColor(color[1],color[2],color[3]) end
    return s
end
local function border(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile="Interface\DialogFrame\UI-DialogBox-Background",
            edgeFile="Interface\Tooltips\UI-Tooltip-Border",
            tile=true,tileSize=32,edgeSize=20,
            insets={left=5,right=5,top=5,bottom=5}
        })
        frame:SetBackdropColor(.025,.035,.05,.97)
        frame:SetBackdropBorderColor(.47,.39,.25,.9)
    end
end
local function pad(s)
    if not s then return "Unknown" end
    return tostring(s)
end
local function choices()
    local root=_G.CoATalentFrame
    local pool=root and root.SpecView and root.SpecView.SpecChoicePool
    local out={}
    if not pool or type(pool.EnumerateActive)~="function" then return out end
    for original in pool:EnumerateActive() do
        if original and original.specInfo and original.specInfo.ID then
            table.insert(out,original)
        end
    end
    return out
end
local function canChoose(original)
    if not original or not original.specInfo then return false end
    local api=_G.C_CharacterAdvancement
    if not api or type(api.CanSwitchActiveChrSpec)~="function" then return false end
    local active=api.GetActiveChrSpec and api.GetActiveChrSpec() or nil
    if active and active==original.specInfo.ID then return true end
    local ok,result=pcall(api.CanSwitchActiveChrSpec,original.specInfo.ID)
    return ok and result~=false and result~=nil
end
local function sourceImg(original)
    local b=original and original.Banner and original.Banner.Image
    if not b or not b.GetTexture then return nil end
    return b:GetTexture(), { b:GetTexCoord() }
end
local function repaintBanner(original)
    if not R.banner then return end
    local texture,uv=sourceImg(original)
    if texture then
        R.banner:SetTexture(texture)
        if uv and #uv==4 then R.banner:SetTexCoord(unpack(uv))
        else R.banner:SetTexCoord(0,1,0,1) end
    else
        R.banner:SetTexture("Interface\Icons\INV_Misc_QuestionMark")
        R.banner:SetTexCoord(0,1,0,1)
    end
end
local function choiceClick(original)
    if not canChoose(original) then
        output("That CoA specialization is not available.")
        return
    end
    if type(original.OnSelected)~="function" then
        output("Original CoA specialization handler not loaded; selection not changed.")
        return
    end
    -- Same original OnSelected function used by the old 'Choose Talents'
    -- buttons. It calls ChangeSpecID, which waits for server confirmation
    -- before switching into the actual Class/Spec talent trees.
    local ok,err=pcall(original.OnSelected,original)
    if not ok then output(err) end
end
local function refreshEntryImages()
    for i,button in ipairs(R.buttons) do
        local original=R.entries[i]
        if not original then button:Hide()
        else
            local info=original.specInfo
            local selected=R.current==i
            button.name:SetText(pad(info.Name))
            button.role:SetText(pad(info.Role or info.RoleName or "CoA Specialization"))
            local icon=info.SpecFilename or info.Icon
            if icon and icon~="" then
                button.icon:SetTexture("Interface\Icons\"..tostring(icon))
            else
                local texture=sourceImg(original)
                button.icon:SetTexture(texture or "Interface\Icons\INV_Misc_QuestionMark")
            end
            if selected then
                button.bg:SetVertexColor(.11,.15,.21,1)
                button.edge:SetVertexColor(.87,.69,.33,.95)
            else
                button.bg:SetVertexColor(.045,.065,.09,1)
                button.edge:SetVertexColor(.22,.29,.37,.65)
            end
            button:Show()
        end
    end
end
local function refreshDetails()
    local original=R.entries[R.current]
    if not original then
        R.detailsName:SetText("CHOOSE A SPECIALIZATION")
        R.detailsDesc:SetText("The existing CoA class talents will appear once a specialization is chosen.")
        R.select:Disable()
        return
    end
    local info=original.specInfo
    R.detailsName:SetText(pad(info.Name))
    R.detailsDesc:SetText(pad(info.Description or
        (original.SpecInfo and original.SpecInfo.Description and original.SpecInfo.Description:GetText()) or
        "Choose this original Conquest of Azeroth specialization."))
    R.budgetHint:SetText("Your talents, ranks, connections and prerequisites remain those of CoA.")
    repaintBanner(original)
    for i,spell in ipairs(R.spellIcons) do
        local id=info.ExampleSpells and info.ExampleSpells[i] or nil
        if id then
            spell:SetTexture(GetSpellTexture and GetSpellTexture(id) or
                "Interface\Icons\INV_Misc_QuestionMark")
            spell:Show()
        else
            spell:Hide()
        end
    end
    R.select:SetText("View / Choose CoA Talents")
    if canChoose(original) then R.select:Enable() else R.select:Disable() end
    refreshEntryImages()
end
function R.Refresh()
    if not R.overlay then return false end
    local found=choices()
    if #found==0 then
        -- Leave original functioning screen visible if the actual client is
        -- missing a custom-class API or has not loaded its spec frames.
        R.overlay:Hide()
        return false
    end
    R.entries=found
    R.count=#found
    if R.current<1 or R.current>#found then R.current=1 end
    for _,original in ipairs(found) do
        if original.SetAlpha then original:SetAlpha(0) end
        if original.EnableMouse then original:EnableMouse(false) end
        R.hiddenOriginal[original]=true
    end
    R.overlay:Show()
    refreshDetails()
    return true
end
function R.Restore()
    for original in pairs(R.hiddenOriginal or {}) do
        if original.SetAlpha then original:SetAlpha(1) end
        if original.EnableMouse then original:EnableMouse(true) end
        R.hiddenOriginal[original]=nil
    end
    if R.overlay then R.overlay:Hide() end
end

local function makeEntry(parent,index)
    local y=-118-(index-1)*109
    local b=CreateFrame("Button","AzerothForeverCoASpecEntry"..index,parent)
    b:SetWidth(267) b:SetHeight(100)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",27,y)
    local bg=flat(b,"BACKGROUND",.045,.065,.09,1)
    bg:SetAllPoints(b)
    b.bg=bg
    local edge=flat(b,"BORDER",.25,.29,.39,.85)
    edge:SetPoint("TOPLEFT",b,"TOPLEFT",0,0)
    edge:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",0,0)
    b.edge=edge
    local interior=flat(b,"ARTWORK",.02,.03,.05,.93)
    interior:SetPoint("TOPLEFT",b,"TOPLEFT",2,-2)
    interior:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2)
    local icon=b:CreateTexture(nil,"OVERLAY")
    icon:SetWidth(69) icon:SetHeight(69)
    icon:SetPoint("LEFT",b,"LEFT",13,0)
    b.icon=icon
    b.name=label(b,"", "GameFontNormalLarge",94,-22,165,{1,.88,.63})
    b.role=label(b,"", "GameFontHighlightSmall",94,-57,165,{.73,.79,.86})
    local hover=b:CreateTexture(nil,"HIGHLIGHT")
    hover:SetTexture("Interface\Buttons\ButtonHilight-Square")
    hover:SetAllPoints(b)
    hover:SetBlendMode("ADD")
    b:SetScript("OnClick",function()
        R.current=index
        refreshDetails()
    end)
    b:Hide()
    return b
end

local function create(spec)
    local frame=CreateFrame("Frame","AzerothForeverCoASpecPicker",spec)
    R.overlay=frame
    R.hiddenOriginal={}
    R.current=1
    frame:SetAllPoints(spec)
    frame:EnableMouse(true)
    frame:SetFrameLevel(spec:GetFrameLevel()+30)
    border(frame)
    local bg=flat(frame,"BACKGROUND",.027,.032,.047,1)
    bg:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-4)
    bg:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-3,3)

    local title=label(frame,"TALENTS", "GameFontNormalHuge",31,-20,440,{1,.86,.55})
    label(frame,"Choose a Conquest of Azeroth specialization", "GameFontHighlight",31,-60,520,{.74,.79,.87})
    local line=flat(frame,"BORDER",.54,.41,.23,.9)
    line:SetPoint("TOPLEFT",frame,"TOPLEFT",25,-95)
    line:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-25,-95)
    line:SetHeight(2)

    local column=flat(frame,"BORDER",.41,.34,.26,.75)
    column:SetPoint("TOPLEFT",frame,"TOPLEFT",317,-111)
    column:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",317,24)
    column:SetWidth(2)
    label(frame,"SPECIALIZATIONS","GameFontNormal",34,-103,270,{.98,.77,.35})
    R.buttons={}
    for i=1,5 do R.buttons[i]=makeEntry(frame,i) end

    local right=CreateFrame("Frame",nil,frame)
    right:SetPoint("TOPLEFT",frame,"TOPLEFT",337,-111)
    right:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-25,24)
    R.details=right
    border(right)
    R.banner=right:CreateTexture(nil,"ARTWORK")
    R.banner:SetPoint("TOP",right,"TOP",0,-20)
    R.banner:SetWidth(390) R.banner:SetHeight(214)
    local bannerFrame=CreateFrame("Frame",nil,right)
    bannerFrame:SetPoint("CENTER",R.banner,"CENTER",0,0)
    bannerFrame:SetWidth(398) bannerFrame:SetHeight(220)
    bannerFrame:EnableMouse(false)
    border(bannerFrame)
    R.detailsName=label(right,"CHOOSE A SPECIALIZATION","GameFontNormalHuge",35,-248,750,{1,.84,.57})
    R.detailsDesc=label(right,"", "GameFontHighlight",35,-290,750,{.84,.88,.94})
    R.detailsDesc:SetJustifyV("TOP")
    R.detailsDesc:SetHeight(72)
    R.budgetHint=label(right,"", "GameFontHighlightSmall",35,-365,750,{.75,.78,.80})
    R.spellIcons={}
    for i=1,3 do
        local tex=right:CreateTexture(nil,"ARTWORK")
        tex:SetWidth(42) tex:SetHeight(42)
        tex:SetPoint("BOTTOMLEFT",right,"BOTTOMLEFT",35+(i-1)*57,67)
        R.spellIcons[i]=tex
    end
    local select=CreateFrame("Button",nil,right,"UIPanelButtonTemplate")
    select:SetWidth(250) select:SetHeight(32)
    select:SetPoint("BOTTOMRIGHT",right,"BOTTOMRIGHT",-25,40)
    select:SetText("View / Choose CoA Talents")
    select:SetScript("OnClick",function() choiceClick(R.entries[R.current]) end)
    R.select=select

    local footer=label(frame,"Your real CoA talents and specialization rules are retained.", "GameFontHighlightSmall",29,-598,900,{.70,.74,.82})
    frame:Hide()
end

local function attach()
    local root=_G.CoATalentFrame
    if not root or not root.SpecView or root.afForeverPickerHook then return end
    if type(IsCustomClass)=="function" and not IsCustomClass() then return end
    local spec=root.SpecView
    if not R.overlay then create(spec) end
    root.afForeverPickerHook=true
    spec:HookScript("OnShow",function()
        local ok,errorMsg=pcall(R.Refresh)
        if not ok then
            R.lastError=errorMsg
            R.Restore()
            output(errorMsg)
        end
    end)
    spec:HookScript("OnHide",function()
        R.Restore()
    end)
    if spec:IsShown() then
        local ok,errorMsg=pcall(R.Refresh)
        if not ok then R.lastError=errorMsg R.Restore() output(errorMsg) end
    end
end

local e=CreateFrame("Frame")
e:RegisterEvent("ADDON_LOADED")
e:RegisterEvent("PLAYER_LOGIN")
e:RegisterEvent("PLAYER_REGEN_ENABLED")
e:SetScript("OnEvent", function(self,event,addon)
    if event=="PLAYER_LOGIN" or event=="PLAYER_REGEN_ENABLED"
       or addon=="Ascension_CoATalents" or addon=="Ascension_Collections" then
        attach()
    end
end)
-- CoATalents is load-on-demand, while the native UI patch is loaded early.
-- Keep a cheap, slow probe until the original panel appears.
e.elapsed=0
e:SetScript("OnUpdate",function(self,dt)
    if R.overlay then self:SetScript("OnUpdate",nil) return end
    self.elapsed=self.elapsed+(dt or 0)
    if self.elapsed<0.9 then return end
    self.elapsed=0
    attach()
end)
