local E = {frames={}, checks=0, notices={}, nativeSelections={}, activeId=271, combat=false, canApply=true}
local unpackValues = unpack or table.unpack

function E.check(value, message)
    E.checks = E.checks+1
    assert(value, message or ("check " .. E.checks .. " failed"))
end

function E.frame(name, parent)
    local f = {name=name, parent=parent, shown=true, enabled=true, scale=1, level=3,
               scripts={}, hooks={}, events={}, points={}, children={}, text=""}
    E.frames[#E.frames+1] = f
    if parent then parent.children[#parent.children+1] = f end
    if name then _G[name] = f end
    function f:Fire(event, ...)
        if self.scripts[event] then self.scripts[event](self, ...) end
        for _, fn in ipairs(self.hooks[event] or {}) do fn(self, ...) end
    end
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:GetScript(event) return self.scripts[event] end
    function f:HookScript(event, fn)
        self.hooks[event] = self.hooks[event] or {}
        self.hooks[event][#self.hooks[event]+1] = fn
    end
    function f:RegisterEvent(event) self.events[event] = true end
    function f:Show() if not self.shown then self.shown=true; self:Fire("OnShow") end end
    function f:Hide() if self.shown then self.shown=false; self:Fire("OnHide") end end
    function f:IsShown() return self.shown end
    function f:Enable() if not self.enabled then self.enabled=true; self:Fire("OnEnable") end end
    function f:Disable() if self.enabled then self.enabled=false; self:Fire("OnDisable") end end
    function f:IsEnabled() return self.enabled end
    function f:GetName() return self.name end
    function f:SetText(value) self.text=value end
    function f:GetText() return self.text end
    function f:SetHeight(value) self.height=value end
    function f:GetHeight() return self.height or (self.parent and self.parent:GetHeight()) or 900 end
    function f:SetWidth(value) self.width=value end
    function f:GetWidth()
        if self.width then return self.width end
        local left, right = self.points.TOPLEFT, self.points.TOPRIGHT
        if left and right and left.parent == right.parent then return left.parent:GetWidth()-left.x+right.x end
        return (self.parent and self.parent:GetWidth()) or 1290
    end
    function f:SetPoint(point, relative, relativePoint, x, y)
        self.points[point] = {parent=relative, point=relativePoint, x=x or 0, y=y or 0}
    end
    function f:ClearAllPoints() self.points={} end
    function f:SetAllPoints(other) self.allPoints=other end
    function f:GetParent() return self.parent end
    function f:GetChildren() return unpackValues(self.children) end
    function f:SetScale(value) self.scale=value end
    function f:GetScale() return self.scale end
    function f:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
    function f:SetClampedToScreen(value) self.clamped=value end
    function f:SetFrameLevel(value) self.level=value end
    function f:GetFrameLevel() return self.level end
    function f:EnableMouse(value) self.mouse=value end
    function f:SetAlpha(value) self.alpha=value end
    function f:SetTexture(value) self.texture=value end
    function f:SetVertexColor(...) self.color={...} end
    function f:SetTextColor(...) self.textColor={...} end
    function f:SetFontObject(value) self.fontObject=value end
    function f:SetWordWrap(value) self.wordWrap=value end
    function f:SetBackdrop(value) self.backdrop=value end
    function f:SetBackdropColor(...) self.backdropColor={...} end
    function f:SetBackdropBorderColor(...) self.borderColor={...} end
    function f:CreateTexture() return E.frame(nil, self) end
    function f:CreateFontString() return E.frame(nil, self) end
    function f:GetFontString()
        if not self.font then self.font=E.frame(nil, self) end
        return self.font
    end
    return f
end

function E.event(event, ...)
    local snapshot = {}
    for _, frame in ipairs(E.frames) do snapshot[#snapshot+1]=frame end
    for _, frame in ipairs(snapshot) do if frame.events[event] then frame:Fire("OnEvent", event, ...) end end
end

function E.setup()
    _G.AzerothForeverNative = {Notice=function(text) E.notices[#E.notices+1]=text end}
    _G.IsCustomClass = function() return true end
    _G.InCombatLockdown = function() return E.combat end
    _G.UnitClass = function() return "Starcaller", "STARCALLER" end
    _G.CreateFrame = function(_, name, parent) return E.frame(name, parent) end
    _G.UIParent = E.frame("UIParent")
    UIParent:SetWidth(1920); UIParent:SetHeight(1080)
    _G.ForeverUI = {Templates={ThreeSliceButton=function(button, atlas)
        button.skinCount=(button.skinCount or 0)+1
        button.atlas=atlas
    end}}
    _G.C_ClassInfo = {
        GetAllSpecs=function() return {"MOONGUARD", "SENTINEL"} end,
        GetSpecInfo=function(_, token)
            return token == "MOONGUARD" and {ID=271, Name="Moon Guard"} or {ID=272, Name="Sentinel"}
        end
    }
    _G.C_CharacterAdvancement = {
        GetActiveChrSpec=function() return E.activeId end,
        CanApplyPendingBuild=function() return E.canApply end,
        CanSwitchActiveChrSpec=function(id) return E.lockedSpec ~= id end
    }
    local root = E.frame("CoATalentFrame", UIParent)
    local view = E.frame(nil, root)
    view:SetWidth(1290); view:SetHeight(900)
    root.TreeView, root.SpecView = view, E.frame(nil, root)
    view.ClassTree, view.SpecTree = E.frame(nil, view), E.frame(nil, view)
    for _, tree in ipairs({view.ClassTree, view.SpecTree}) do
        tree.Label, tree.Points = E.frame(nil, tree), E.frame(nil, tree)
        tree.originalNodes = {{rank=2, maxRank=5}, {rank=0, maxRank=1}}
    end
    view.BottomBar = E.frame(nil, view)
    for _, name in ipairs({"SaveChanges", "UndoButton", "ChangeSpec", "Search", "ResetButton", "SpecDropDown"}) do
        view.BottomBar[name] = E.frame(nil, view.BottomBar)
        view.BottomBar[name]:SetScript(name == "Search" and "OnTextChanged" or "OnClick", function() end)
    end
    function view:SetSpecID(id)
        if E.failPreview == id then error("simulated missing talent data") end
        self.renderCalls=(self.renderCalls or 0)+1
        self.lastSpecId=id
    end
    local choices={}
    for _, id in ipairs({271, 272}) do
        choices[#choices+1] = {specInfo={ID=id}, OnSelected=function(self)
            if E.failChoice then error("simulated native selection failure") end
            E.nativeSelections[#E.nativeSelections+1]=self.specInfo.ID
            if not E.stageOnly then E.activeId=self.specInfo.ID end
        end}
    end
    root.SpecView.SpecChoicePool={EnumerateActive=function()
        local index=0
        return function() index=index+1; return choices[index] end
    end}
    _G.Collections = E.frame("Collections", UIParent)
    Collections:SetWidth(1290); Collections:SetHeight(900)
    Collections.Tabs={CharacterAdvancement=1, Vanity=2, Wardrobe=3}
    function Collections:GoToTab(id) self.currentTab=id end
    function Collections:HideTabID(id) self.hiddenTabs=self.hiddenTabs or {}; self.hiddenTabs[id]=true end
    return root
end

return E
