-- Azeroth Forever native FrameXML post-load.
-- Deliver the original UI port's ADDON_LOADED("ForeverUI") to frames created
-- by its own modules. Do not spoof the event to Blizzard/CoA interface frames.
local boot = AzerothForeverNativeBootstrap
if boot and boot.existingFrames then
    local frame = EnumerateFrames()
    local count = 0
    while frame do
        if not boot.existingFrames[frame] and
            frame.IsEventRegistered and
            frame:IsEventRegistered("ADDON_LOADED") then
            local handler = frame.GetScript and frame:GetScript("OnEvent")
            if type(handler) == "function" then
                local ok, err = pcall(handler, frame, "ADDON_LOADED", "ForeverUI")
                if not ok then
                    table.insert(boot.errors, tostring(err))
                end
                count = count + 1
            end
        end
        frame = EnumerateFrames(frame)
    end
    boot.initializedListeners = count
    boot.existingFrames = nil
end

-- Report client errors after login so the player isn't left with a cryptic
-- "interface error" and no explanation of the source.
local diag = CreateFrame("Frame")
diag:RegisterEvent("PLAYER_LOGIN")
diag:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    if boot and #boot.errors > 0 and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff6666Azeroth Forever native UI: " .. #boot.errors ..
            " initialization error(s); restore patch-Z.MPQ if panels are broken.|r")
        for index = 1, math.min(3, #boot.errors) do
            DEFAULT_CHAT_FRAME:AddMessage(boot.errors[index])
        end
    end
end)
