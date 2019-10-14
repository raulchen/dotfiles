-- Make the modifiers keys smarter:
-- Tap ctrl -> esc.
-- Tap shift -> switch input method.

-- Whether ctrl and shift is being pressed alone.
local ctrlPressed = 0
local shiftPressed = 0

hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
    local modifiers = e:getFlags()
    local events_to_post = {}
    if modifiers['ctrl'] then
      ctrlPressed = true
    else
      if ctrlPressed then
        -- Ctrl was tapped, send an esc key.
        events_to_post = {
            hs.eventtap.event.newKeyEvent(nil, "escape", true),
            hs.eventtap.event.newKeyEvent(nil, "escape", false),
        }
      end
      ctrlPressed = false
    end

    if modifiers['shift'] then
      shiftPressed = true
    else
      if shiftPressed then
        -- Shift was tapped, switch input method (cmd + space).
        events_to_post = {
            hs.eventtap.event.newKeyEvent({"cmd"}, "space", true),
            hs.eventtap.event.newKeyEvent({"cmd"}, "space", false),
        }
      end
      shiftPressed = false
    end
    return false, events_to_post
end):start()


hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    -- If a non-modifier key is pressed, reset these two flags.
    ctrlPressed = false
    shiftPressed = false
end):start()
