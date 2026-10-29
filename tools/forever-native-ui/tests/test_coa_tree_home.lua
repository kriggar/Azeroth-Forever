local root = assert(arg[0]:match("^(.*)[/\\]tests[/\\][^/\\]+$"))
local E = dofile(root .. "/tests/ui_test_env.lua")
local frame = E.setup()
local tree = frame.TreeView
local originalNodes = tree.SpecTree.originalNodes
local saveClick = tree.BottomBar.SaveChanges:GetScript("OnClick")
dofile(root .. "/client/AzerothForeverCoATreeHome.lua")
local R = AzerothForeverNative.CoATreeHome
E.check(R.Attach() and R.OpenTrees(), "real CoA graph opens directly")
E.check(tree:IsShown() and not frame.SpecView:IsShown(), "card selector is not the first screen")
E.check(tree.lastSpecId == 271 and #E.nativeSelections == 0, "opening never chooses a spec")
local calls = tree.renderCalls
E.check(R.OpenTrees() and tree.renderCalls == calls, "opening again must not rebuild a pending talent graph")
E.check(R.Select(272) and tree.lastSpecId == 272, "inactive specialization can be previewed")
E.check(#E.nativeSelections == 0 and E.activeId == 271, "tab clicks must never select a specialization")
E.check(R.OpenTrees() and tree.lastSpecId == 272, "preview must not snap back to active specialization")
E.check(R.readOnly and not tree.BottomBar.SaveChanges:IsEnabled(), "preview cannot save another build")
E.check(tree.SpecTree.afForeverPreviewGuard:IsShown() and tree.ClassTree.afForeverPreviewGuard:IsShown(),
        "preview blocks accidental native talent purchases")
tree.BottomBar.SaveChanges:Enable()
E.check(not tree.BottomBar.SaveChanges:IsEnabled(), "native refresh must not bypass preview save guard")
E.check(R.Select(271) and tree.BottomBar.SaveChanges:IsEnabled(), "valid pending build can save when returning to active")
E.check(not tree.SpecTree.afForeverPreviewGuard:IsShown(), "active tree remains interactive")
E.canApply=false
E.check(R.Select(272) and R.Select(271) and not tree.BottomBar.SaveChanges:IsEnabled(), "invalid build stays disabled")
E.canApply=true
E.check(R.Select(272) and R.ConfirmSelection(272), "explicit choose delegates to original CoA handler")
E.check(#E.nativeSelections == 1 and E.nativeSelections[1] == 272, "exactly one original selection")
E.check(tree.SpecTree.originalNodes == originalNodes and tree.BottomBar.SaveChanges:GetScript("OnClick") == saveClick,
        "original ranks and save handler are untouched")
E.lockedSpec=271
E.check(R.Select(271) and not R.ConfirmSelection(271) and #E.nativeSelections == 1, "locked spec fails closed")
E.lockedSpec=nil
E.failChoice=true
E.check(not R.ConfirmSelection(271) and not R.selecting, "native exception releases selection guard")
E.failChoice=false
E.check(R.ConfirmSelection(271), "selection can retry after a native exception")
E.failPreview=272
E.check(not R.Select(272) and R.previewSpecID == 271 and not R.opening, "failed preview rolls back selection state")
E.failPreview=nil
E.check(R.Select(272), "preview can recover after data becomes available")
E.combat=true
local selections=#E.nativeSelections
E.check(not R.Select(271) and not R.ConfirmSelection(272) and #E.nativeSelections == selections,
        "combat cannot trigger specialization changes")
E.combat=false
E.activeId=0
R.previewSpecID=nil; R.renderedSpecID=nil; R.stagedSpecID=nil
E.check(R.OpenTrees() and R.readOnly, "zero active-spec sentinel means preview, not an active build")
local originalCanSwitch=C_CharacterAdvancement.CanSwitchActiveChrSpec
C_CharacterAdvancement.CanSwitchActiveChrSpec=nil
E.check(not R.ConfirmSelection(R.previewSpecID), "missing specialization validation fails closed")
C_CharacterAdvancement.CanSwitchActiveChrSpec=originalCanSwitch
E.stageOnly=true
E.check(R.ConfirmSelection(R.previewSpecID) and E.activeId == 0, "native selection can be staged before server acknowledgement")
E.check(not R.readOnly and tree.BottomBar.SaveChanges:IsEnabled(), "staged first spec can use native Save")
E.check(R.choose:GetText() == "Selection staged", "staged selection is not represented as server-confirmed")
tree.BottomBar.UndoButton:Fire("OnClick")
E.check(R.stagedSpecID == nil and R.readOnly, "native Undo clears the staged editing state")
E.stageOnly=false
E.check(not R.Select(999999) and not R.ConfirmSelection(999999), "unknown IDs cannot reach native selection")
local shapeCount=0
for classId=12,32 do
    UnitClass=function() return "CoA Test", "COA_" .. classId end
    for specCount=1,7 do
        C_ClassInfo.GetAllSpecs=function()
            local names={}; for i=1,specCount do names[i]="Spec" .. i end; return names
        end
        C_ClassInfo.GetSpecInfo=function(_, key)
            return {ID=classId*100+tonumber(key:match("%d+")), Name="Long specialization name " .. key}
        end
        R.specs=R.GetSpecs(); R.previewSpecID=R.specs[1].id
        E.check(#R.specs == specCount, "class/spec shape must not assume exactly three trees")
        R.UpdateTabs()
        local rightEdge=12+specCount*R.tabWidth+(specCount-1)*6
        E.check(rightEdge <= R.tabStrip:GetWidth()-R.choose:GetWidth()-24, "tabs cannot overlap choose control")
        for i=specCount+1,#R.buttons do E.check(not R.buttons[i]:IsShown(), "stale class tabs stay hidden") end
        shapeCount=shapeCount+1
    end
end
E.check(shapeCount == 147)
print("PASS: talent preview/selection and 147 simulated class/spec shapes; " .. E.checks .. " checks")
