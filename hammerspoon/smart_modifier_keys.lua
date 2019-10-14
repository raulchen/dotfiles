-- Make the modifiers keys smarter:
-- Tap ctrl -> esc.
-- Tap shift -> switch input method.

-- Whether ctrl and shift is being pressed alone.
local ctrlPressed = false
local shiftPressed = false

local prevModifiers = {}

local log = hs.logger.new('smart_modifier_keys','debug')

hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
    local events_to_post = nil

    local modifiers = e:getFlags()
    local count = 0
    for _, __ in pairs(modifiers) do
        count = count + 1
    end

    -- Check `ctrl` key.
    if modifiers['ctrl'] and not prevModifiers['ctrl'] and count == 1 then
        ctrlPressed = true
    else
        if count == 0 and ctrlPressed then
            -- Ctrl was tapped alone, send an esc key.
            events_to_post = {
                hs.eventtap.event.newKeyEvent(nil, "escape", true),
                hs.eventtap.event.newKeyEvent(nil, "escape", false),
            }
        end
        ctrlPressed = false
    end

    -- Check `shift` key.
    if modifiers['shift'] and not prevModifiers['shift'] and count == 1 then
        shiftPressed = true
    else
        if count == 0 and shiftPressed then
            -- Shift was tapped alone, switch input method (cmd + space).
            events_to_post = {
                hs.eventtap.event.newKeyEvent({"cmd"}, "space", true),
                hs.eventtap.event.newKeyEvent({"cmd"}, "space", false),
            }
        end
        shiftPressed = false
    end

    prevModifiers = modifiers
    return false, events_to_post
end):start()


hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    -- If a non-modifier key is pressed, reset these two flags.
    ctrlPressed = false
    shiftPressed = false
end):start()
