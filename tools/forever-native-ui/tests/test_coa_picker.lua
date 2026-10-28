-- Native CoA spec picker regression; Lua 5.1 with mocked client frames.
-- Ensure Moon Priest/Sentinel and their original class IDs/OnSelected logic
-- are preserved. This tests client wiring, NOT a real rendered screenshot.
local function frame(name)
    local f={name=name, shown=true, alpha=1, enabled=true, level=3, scripts={}, hooks={}, texture="Interface\\Icons\\Spell_Holy_HolyBolt"}
    setmetatable(f,{
        __index=function(_,key)
            return function(self,...)
                if key=="CreateTexture" or key=="CreateFontString" then
                    return frame()
                elseif key=="GetFrameLevel" then return self.level
                elseif key=="SetFrameLevel" then self.level=...; return
                elseif key=="Show" then self.shown=true; return
                elseif key=="Hide" then self.shown=false; return
                elseif key=="IsShown" then return self.shown
                elseif key=="SetAlpha" then self.alpha=...; return
                elseif key=="EnableMouse" then self.enabled=...; return
                elseif key=="SetTexture" then self.texture=...; return
                elseif key=="GetTexture" then return self.texture
                elseif key=="GetTexCoord" then return 0,1,0,1
                elseif key=="SetText" then self.text=...; return
                elseif key=="GetText" then return self.text
                elseif key=="SetScript" then
                    local event,cb=...
                    self.scripts[event]=cb
                    return
                elseif key=="HookScript" then
                    local event,cb=...
                    self.hooks[event]=cb
                    return
                elseif key=="Enable" then self.disabled=false; return
                elseif key=="Disable" then self.disabled=true; return
                end
                return
            end
        end
    })
    return f
end

_G.AzerothForeverNative={Notice=function() end}
local frames={}
CreateFrame=function(_,name)
    local f=frame(name)
    table.insert(frames,f)
    return f
end
IsCustomClass=function() return true end
GetSpellTexture=function(id) return "Interface\\Icons\\Spell_Holy_HolyBolt" end
C_CharacterAdvancement={
    CanSwitchActiveChrSpec=function(id) return id==271 or id==272 end,
    GetActiveChrSpec=function() return nil end
}

local called={}
local function makeChoice(id,name)
    local c=frame(name)
    c.specInfo={ ID=id, Name=name, Description=name.." original CoA spec",
        ExampleSpells={481,482,483}, SpecFilename="Spell_Holy_HolyBolt" }
    c.Banner={Image=frame()}
    c.OnSelected=function(self) table.insert(called,self.specInfo.ID) end
    return c
end
local moon=makeChoice(271,"Moon Priest")
local sentinel=makeChoice(272,"Sentinel")
local pool={
    EnumerateActive=function()
        local index=0
        return function()
            index=index+1
            return ({moon,sentinel})[index]
        end
    end
}
local spec=frame("SpecView")
spec.SpecChoicePool=pool
CoATalentFrame={SpecView=spec}

local path=arg[0]:gsub("tests[/\\]test_coa_picker.lua$","client/AzerothForeverCoASpecPicker.lua")
assert(path~=arg[0])
dofile(path)

local registered
for _,f in ipairs(frames) do
    if f.scripts.OnEvent then registered=f end
end
assert(registered and registered.scripts.OnEvent)
registered.scripts.OnEvent(registered,"PLAYER_LOGIN")
local picker=AzerothForeverNative.CoASpecPicker
assert(picker.overlay and picker.count==2)
assert(moon.alpha==0 and sentinel.alpha==0,
    "old large CoA specialization cards must no longer render")
assert(picker.buttons[1].name.text=="Moon Priest")
assert(picker.buttons[2].name.text=="Sentinel")
picker.buttons[2].scripts.OnClick(picker.buttons[2])
picker.select.scripts.OnClick(picker.select)
assert(#called==1 and called[1]==272,
    "new UI MUST delegate to the original CoA specialization activation")
spec.hooks.OnHide()
assert(moon.alpha==1 and sentinel.alpha==1,
    "original CoA selection view must be restorable on failure")
print("PASS: full native spec picker replaces old cards, displays real CoA specs and delegates original selection")
