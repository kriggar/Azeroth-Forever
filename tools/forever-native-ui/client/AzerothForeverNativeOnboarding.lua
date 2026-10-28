-- Azeroth Forever — integrated first-login experience WORKFLOW PREVIEW.
-- It is loaded by Interface/FrameXML, not Interface/AddOns.
--
-- Verified beta steps: Ruleset -> Experience Preset (Classic/Enhanced)
-- -> CoA character creation -> Social Contract -> Enter World.
-- IMPORTANT: We are running in the in-world client FrameXML. This is a
-- preview of the character-select sequence, not a replacement for GlueXML
-- and not a server implementation of PvP/Hardcore or a class creator.
-- We DO NOT falsely claim a new character or ruleset was created.
--
-- Data is SESSION ONLY until the CoA account/realm protocol is implemented.
-- Choices that map to existing client CVars may be applied (UI scale,
-- quest marker settings). Legacy/Hardcore/ruleset transfers are not spoofed.

local AF = _G.AzerothForeverNative or {}
_G.AzerothForeverNative = AF
local O = {}
AF.Onboarding = O
O.version = 1
O.step = 1
O.ruleset = "Normal"
O.preset = "Enhanced"
O.transmog = true
O.oneBag = true
O.questMarkers = true
O.centerUI = true
O.hdModels = true
O.strafe = true
O.consent = false
O.class = "Starcaller"
O.race = "Night Elf"
O.name = ""
O.surname = ""
O.status = "Preview only — no account or character creation"
O.enabled = false
O.buttons = {}
O.raceButtons = {}
O.classButtons = {}
O.setupChoices = {}
O.sourceClasses = {
    "Barbarian", "Bloodmage", "Chronomancer", "Cultist", "Felsworn",
    "Guardian", "Knight of Xoroth", "Necromancer", "Primalist",
    "Pyromancer", "Ranger", "Reaper", "Runemaster", "Starcaller",
    "Stormbringer", "Sun Cleric", "Templar", "Tinker",
    "Venomancer", "Witch Doctor", "Witch Hunter"
}
local RULES = {
    {id="Normal", title="Normal", subtitle="PvE / Optional PvP",
     desc="Explore, quest, cooperate and choose when to engage in PvP.",
     available=true, connected=true, color={0.30,0.65,0.9}},
    {id="PvP", title="PvP", subtitle="Open-world conflict",
     desc="PvP danger in contested regions. One faction per account on this ruleset.",
     available=true, connected=false, color={0.9,0.35,0.2}},
    {id="Roleplaying", title="Roleplaying", subtitle="Immersive roleplay",
     desc="Explore with a roleplay-focused community and naming standards.",
     available=true, connected=false, color={0.7,0.55,0.85}},
    {id="Roleplay-PvP", title="Roleplay-PvP", subtitle="Roleplay with PvP danger",
     desc="Launch ruleset combining roleplay and contested-zone PvP.",
     available=true, connected=false, color={0.85,0.52,0.35}},
    {id="Hardcore", title="Hardcore", subtitle="Coming after launch",
     desc="One life and an isolated ruleset. Not available at Forever launch.",
     available=false, connected=false, color={0.55,0.75,0.72}},
}
local function say(t)
    if AF.Notice then AF.Notice("First-login preview: "..t) end
end
local function face(tex, color, alpha)
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    tex:SetVertexColor(color[1],color[2],color[3],alpha or 1)
end
local function text(p,s,x,y,w,style,color)
    local f=p:CreateFontString(nil,"OVERLAY",style or "GameFontHighlight")
    f:SetPoint("TOPLEFT",p,"TOPLEFT",x,y)
    f:SetWidth(w)
    f:SetJustifyH("LEFT")
    f:SetText(s)
    if color then f:SetTextColor(color[1],color[2],color[3]) end
    return f
end
local function button(p,name,x,y,w,h,cb)
    local b=CreateFrame("Button",nil,p,"UIPanelButtonTemplate")
    b:SetWidth(w) b:SetHeight(h)
    b:SetPoint("TOPLEFT",p,"TOPLEFT",x,y)
    b:SetText(name)
    b:SetScript("OnClick",cb)
    return b
end
local function panel(p,x,y,w,h)
    local f=CreateFrame("Frame",nil,p)
    f:SetWidth(w) f:SetHeight(h)
    f:SetPoint("TOPLEFT",p,"TOPLEFT",x,y)
    f:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true,tileSize=32,edgeSize=15,
        insets={left=3,right=3,top=3,bottom=3}
    })
    f:SetBackdropColor(.018,.026,.043,.96)
    f:SetBackdropBorderColor(.37,.32,.25,.95)
    return f
end
local function holder(f)
    local t=f:CreateTexture(nil,"BACKGROUND")
    t:SetAllPoints(f)
    face(t,{.018,.026,.043},.97)
    return t
end
local function clear()
    for _,obj in ipairs(O.controls or {}) do
        if obj.Hide then obj:Hide() end
    end
    O.controls={}
end
local function own(f)
    table.insert(O.controls,f)
    return f
end
local function head(section,sub)
    own(text(O.frame,section,37,-85,870,"GameFontNormalHuge",{1,.81,.48}))
    own(text(O.frame,sub,37,-119,880,"GameFontHighlightSmall",{.71,.74,.82}))
end
local function choiceButton(p,label,x,y,w,cb,active)
    local b=own(button(p,label,x,y,w,30,cb))
    if active and b.GetFontString then
        local f=b:GetFontString()
        if f then f:SetTextColor(1,.82,.35) end
    end
    return b
end
local function updateNav()
    if not O.frame then return end
    O.progress:SetText(O.step.." / 5  •  "..({
        "RULESET","EXPERIENCE","CHARACTER","SOCIAL CONTRACT","SUMMARY"
    })[O.step])
    if O.back then O.back:SetShown(O.step>1) end
    O.next:SetText(O.step==5 and "Close Preview" or "Continue")
    O.next:SetEnabled(O.step~=4 or O.consent)
    if O.note then O.note:SetText(O.status) end
end
local function redraw()
    if not O.frame then return end
    clear()
    if O.step==1 then
        head("CHOOSE YOUR RULESET",
             "In Forever this replaces realm selection. Your local CoA server currently has one realm.")
        for i,r in ipairs(RULES) do
            local col=(i-1)%3
            local row=math.floor((i-1)/3)
            local x=30+col*316
            local y=-166-row*157
            local p=own(panel(O.frame,x,y,300,146))
            own(text(p,r.title,16,-15,255,"GameFontNormalLarge",
                     r.available and {1,.8,.4} or {.62,.62,.62}))
            own(text(p,r.subtitle,16,-45,260,"GameFontHighlightSmall",{.72,.72,.78}))
            own(text(p,r.desc,16,-72,265,"GameFontHighlightSmall",{.85,.86,.91}))
            local bb=own(button(p,O.ruleset==r.id and "Selected" or "Choose",19,-115,260,24,function()
                if not r.available then
                    say("Hardcore was announced for after Forever launch; no server support yet.")
                    return
                end
                O.ruleset=r.id
                O.status=r.connected and "Normal ruleset selected (presentation only until creation hooks exist)"
                    or ("Previewing "..r.id.."; this local CoA server does not enforce that ruleset yet")
                redraw()
            end))
            if not r.available then bb:Disable() end
        end
        own(text(O.frame,
             "Normal and PvP appeared in beta; Roleplaying / Roleplay-PvP launch November 4. Hardcore later.",
             33,-493,930,"GameFontHighlightSmall",{.73,.77,.81}))
    elseif O.step==2 then
        head("CHOOSE YOUR EXPERIENCE PRESET",
             "These are starting preferences; Forever lets you change them in Options later.")
        for i,preset in ipairs({"Classic","Enhanced"}) do
            local p=own(panel(O.frame,58+(i-1)*472,-163,432,160))
            own(text(p,preset,18,-17,360,"GameFontNormalLarge",{1,.81,.43}))
            own(text(p,preset=="Classic" and
                "Standard models • quest guidance off • separate bags • transmog off • classic UI"
                or "HD models • quest guidance on • one bag • transmog on • centered UI",
                18,-52,391,"GameFontHighlight",{.84,.84,.89}))
            own(button(p,O.preset==preset and "Selected" or "Choose "..preset,35,-113,354,29,function()
                O.preset=preset
                local enabled=preset=="Enhanced"
                O.transmog=enabled O.oneBag=enabled O.questMarkers=enabled
                O.centerUI=enabled O.hdModels=enabled O.strafe=enabled
                redraw()
            end))
        end
        local opts={
            {"Display transmog", "transmog"},
            {"HD character models", "hdModels"},
            {"Quest objective markers", "questMarkers"},
            {"One combined bag", "oneBag"},
            {"Centered HUD layout", "centerUI"},
            {"Strafe movement bindings", "strafe"},
        }
        for i,o in ipairs(opts) do
            local col=(i-1)%2 local row=math.floor((i-1)/2)
            local x=70+col*468 local y=-354-row*45
            own(button(O.frame,(O[o[2]] and "[x] " or "[ ] ")..o[1],x,y,395,29,function()
                O[o[2]]=not O[o[2]]
                O.preset="Custom"
                redraw()
            end))
        end
        own(text(O.frame,"HD models, transmog, and one-bag need compatible client/server implementations; this panel previews choices.",
            45,-501,905,"GameFontHighlightSmall",{.76,.79,.84}))
    elseif O.step==3 then
        head("CREATE YOUR CHARACTER",
             "The genuine CoA creator owns race/class compatibility, appearance, spells, and character creation.")
        own(text(O.frame,"Choose a CoA class",40,-175,450,"GameFontNormalLarge",{1,.83,.49}))
        for i,name in ipairs(O.sourceClasses) do
            local col=(i-1)%4 local row=math.floor((i-1)/4)
            local x=42+col*241 local y=-204-row*45
            own(button(O.frame,(name==O.class and "• " or "")..name,x,y,223,31,function()
                O.class=name
                redraw()
            end))
        end
        own(text(O.frame,"These are class-selection previews. Creating a real character still uses the native CoA creation screen.",
            38,-501,950,"GameFontHighlightSmall",{.74,.77,.82}))
    elseif O.step==4 then
        head("A WORLD TO EXPLORE TOGETHER",
             "Acknowledge community conduct expectations before beginning your journey.")
        own(text(O.frame,
            "Respect other players. Do not harass, threaten, impersonate or exploit. Keep roleplay names appropriate on RP rulesets. Adventure responsibly.",
            71,-189,830,"GameFontHighlightLarge",{.89,.9,.95}))
        own(text(O.frame,"This is an original Azeroth Forever preview agreement, not Blizzard's legal text.",
            71,-294,825,"GameFontHighlightSmall",{.7,.75,.8}))
        own(button(O.frame,(O.consent and "[x]" or "[ ]")..
            "  I have read and accept these community guidelines",80,-368,825,36,function()
            O.consent=not O.consent
            redraw()
        end))
    else
        head("YOUR JOURNEY BEGINS HERE",
             "Review your selections. They are not submitted to the realm database in this preview.")
        local summary={
            {"Ruleset", O.ruleset},
            {"Experience",O.preset},
            {"Class", O.class},
            {"Transmog", O.transmog and "Visible" or "Hidden"},
            {"Character models",O.hdModels and "HD (requires future client work)" or "Standard"},
            {"Quest guidance",O.questMarkers and "Enabled" or "Disabled"},
            {"Combined bags",O.oneBag and "On" or "Off"},
        }
        for i,kv in ipairs(summary) do
            local y=-168-(i-1)*41
            own(text(O.frame,kv[1],90,y,260,"GameFontNormal",{1,.83,.5}))
            own(text(O.frame,kv[2],354,y,500,"GameFontHighlight",{.90,.91,.95}))
        end
        own(text(O.frame,
             "Native game integration status: UI workflow preview. PvP, RP, Hardcore and transmog require server code; names/races are created through CoA's own character creator.",
             61,-474,878,"GameFontHighlightSmall",{.80,.73,.69}))
    end
    updateNav()
end
function O.Open()
    if not O.frame then O.Create() end
    O.frame:Show()
    redraw()
end
function O.Close()
    if O.frame then O.frame:Hide() end
end
function O.Create()
    local f=CreateFrame("Frame","AzerothForeverNativeOnboarding",UIParent)
    O.frame=f
    f:SetWidth(1010) f:SetHeight(654)
    f:SetPoint("CENTER",UIParent,"CENTER",0,6)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(205)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self)
        if not InCombatLockdown or not InCombatLockdown() then self:StartMoving() end
    end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=32,edgeSize=30,
        insets={left=8,right=8,top=8,bottom=8}
    })
    f:SetBackdropColor(.012,.022,.045,.99)
    local top=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    top:SetPoint("TOP",f,"TOP",0,-21)
    top:SetText("AZEROTH FOREVER")
    O.progress=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    O.progress:SetPoint("TOP",top,"BOTTOM",0,-11)
    O.note=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    O.note:SetPoint("BOTTOM",f,"BOTTOM",0,62)
    O.note:SetTextColor(.95,.68,.43)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-8)
    close:SetScript("OnClick",function() O.Close() end)
    O.back=button(f,"Back",30,-596,150,31,function()
        O.step=math.max(1,O.step-1) redraw()
    end)
    O.next=button(f,"Continue",826,-596,150,31,function()
        if O.step==4 and not O.consent then
            say("Accept the community guidelines to continue.")
            return
        end
        if O.step==5 then O.Close()
        else O.step=math.min(5,O.step+1) redraw() end
    end)
    f:Hide()
    if _G.UISpecialFrames then table.insert(UISpecialFrames,"AzerothForeverNativeOnboarding") end
    return f
end
function O.Status()
    local data={}
    for _,key in ipairs({"ruleset","preset","class","transmog","hdModels","oneBag","questMarkers","centerUI"}) do
        data[#data+1]=key.."="..tostring(O[key])
    end
    return table.concat(data,", ")
end
SLASH_AZEROTHFOREVERSTART1="/afstart"
SlashCmdList["AZEROTHFOREVERSTART"]=function(arg)
    arg=string.lower(arg or "")
    if arg=="reset" then
        O.step=1 O.ruleset="Normal" O.preset="Enhanced"
        O.consent=false O.class="Starcaller" O.transmog=true
        O.oneBag=true O.questMarkers=true O.centerUI=true
        O.hdModels=true O.strafe=true
    elseif arg=="status" then say(O.Status()); return end
    O.Open()
end
local login=CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent",function(self,event)
    self:UnregisterEvent("PLAYER_LOGIN")
    -- Do not auto-interrupt the player's live character. In a future client
    -- GlueXML integration this flow must run BEFORE character creation.
    -- For now the native UI is testable by /afstart and Escape > New Journey.
end)
