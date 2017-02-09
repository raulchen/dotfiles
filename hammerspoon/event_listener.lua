-- listen key events
local mod = {}

mod.flagsChangeCallbacks = {}

mod.flagsChangeListener = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
    for i = 1, #mod.flagsChangeCallbacks do
        mod.flagsChangeCallbacks[i](e)
    end
end):start()

-- double ctrl -> esc
local lastCtrlTime = 0
table.insert(mod.flagsChangeCallbacks, function(e)
    local f = e:getFlags()
    if f.ctrl and not (f.cmd or f.alt or f.fn or f.shift) then
        local now = hs.timer.secondsSinceEpoch()
        if now - lastCtrlTime < 0.5 then
            hs.eventtap.keyStroke({}, 'escape', 10)
        end
        lastCtrlTime = now
    end
end)

return mod
