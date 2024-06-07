local module = {}

local inspect = hs.inspect.inspect

local MIN_INTERVAL_S = 0.5

local mod_keys = { "ctrl", "shift" }

local key_states = {}

local function reset_key_states()
    for _, key in ipairs(mod_keys) do
        key_states[key] = {
            repeats = 0,
            last_press_time = 0,
        }
    end
end

reset_key_states()

local last_toggle_caps_lock_time = 0.0

local mod_key_listener = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(e)
    local now = hs.timer.secondsSinceEpoch() or 0

    local modifiers = e:getFlags()

    local pressed_keys = {}
    for key, _ in pairs(modifiers) do
        table.insert(pressed_keys, key)
    end

    if #pressed_keys > 1 then
        -- If multiple modifier keys are pressed, reset the states of all keys.
        reset_key_states()
    elseif #pressed_keys == 1 then
        local key = pressed_keys[1]
        for _, k in ipairs(mod_keys) do
            if k == key then
                if now - key_states[k].last_press_time < MIN_INTERVAL_S then
                    key_states[k].repeats = key_states[k].repeats + 1
                else
                    key_states[k].repeats = 1
                end
                key_states[k].last_press_time = now
            else
                key_states[k].repeats = 0
            end
        end
    else
        -- If shift is pressed twice, toggle caps lock.
        if key_states["shift"].repeats == 2 then
            -- If the second shift press was released after the interval,
            -- do not trigger caps lock.
            if now - key_states["shift"].last_press_time < MIN_INTERVAL_S then
                -- `hs.hid.capslock.toggle()` will also trigger this callback,
                -- need the following check to avoid infinite callbacks.
                if now - last_toggle_caps_lock_time > MIN_INTERVAL_S then
                    ---@diagnostic disable-next-line: undefined-field
                    hs.hid.capslock.toggle()
                    last_toggle_caps_lock_time = now
                end
            end
        end
        if key_states["ctrl"].repeats == 2 then
            if now - key_states["ctrl"].last_press_time < MIN_INTERVAL_S then
                require("prefix").toggle()
            end
        end
    end

    return false, nil
end)

module.start = function()
    mod_key_listener:start()
end

return module
