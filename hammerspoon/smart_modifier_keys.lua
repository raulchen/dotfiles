-- Make the modifiers keys smarter:
-- Tap ctrl -> esc.
-- Tap shift -> switch input method.

local module = {}

-- Whether ctrl and shift is being pressed alone.
module.ctrlPressed = false
module.shiftPressed = false

module.prevModifiers = {}

module.log = hs.logger.new('smart_modifier_keys','debug')

module.modifierKeyListener = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
    local events_to_post = nil

    local modifiers = e:getFlags()
    local count = 0
    for _, __ in pairs(modifiers) do
        count = count + 1
    end

    -- Check `ctrl` key.
    -- if modifiers['ctrl'] and not module.prevModifiers['ctrl'] and count == 1 then
    --     module.ctrlPressed = true
    -- else
    --     if count == 0 and module.ctrlPressed then
    --         -- Ctrl was tapped alone, send an esc key.
    --         events_to_post = {
    --             hs.eventtap.event.newKeyEvent(nil, "escape", true),
    --             hs.eventtap.event.newKeyEvent(nil, "escape", false),
    --         }
    --     end
    --     module.ctrlPressed = false
    -- end

    -- Check `shift` key.
    if modifiers['shift'] and not module.prevModifiers['shift'] and count == 1 then
        module.shiftPressed = true
    else
        if count == 0 and module.shiftPressed then
            -- Shift was tapped alone, switch input method (ctrl + space).
            events_to_post = {
                hs.eventtap.event.newKeyEvent({"ctrl"}, "space", true),
                hs.eventtap.event.newKeyEvent({"ctrl"}, "space", false),
            }
        end
        module.shiftPressed = false
    end

    module.prevModifiers = modifiers
    return false, events_to_post
end):start()


module.normalKeyListener = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    -- If a non-modifier key is pressed, reset these two flags.
    module.ctrlPressed = false
    module.shiftPressed = false
end):start()

return module
