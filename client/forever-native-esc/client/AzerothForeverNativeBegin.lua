-- Azeroth Forever native FrameXML bootstrap (Lua 5.1, client-side).
-- Loaded by the client's own FrameXML.toc, NOT by an addon manifest.
-- Records preexisting UI frames so only native UI module listeners receive
-- the equivalent of the ForeverUI ADDON_LOADED notification.

AzerothForeverNativeBootstrap = {
    existingFrames = setmetatable({}, { __mode = "k" }),
    errors = {}
}

local frame = EnumerateFrames()
while frame do
    AzerothForeverNativeBootstrap.existingFrames[frame] = true
    frame = EnumerateFrames(frame)
end

-- Addons have SavedVariables, whereas built-in FrameXML does not. Initialize
-- the UI's in-memory defaults; persistence needs a separate native client CVar
-- bridge, deliberately not fabricated here.
ForeverUIDB = ForeverUIDB or { positions = {} }
ForeverUI = ForeverUI or {}
