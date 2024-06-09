local module = {}

function module.temp_notify(timeout, notif)
    notif:send()
    hs.timer.doAfter(timeout, function() notif:withdraw() end)
end

function module.split_str(str, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    local i = 1
    for s in string.gmatch(str, "([^" .. sep .. "]+)") do
        t[i] = s
        i = i + 1
    end
    return t
end

function module.str_to_table(str)
    local t = {}
    for i = 1, #str do
        t[i] = str:sub(i, i)
    end
    return t
end

local caps_lock_on_label = require("labels").new("Caps lock on", "bottom_left")
local caps_lock_off_label = require("labels").new("Caps lock off", "bottom_left")

function module.toggle_caps_lock()
    hs.hid.capslock.toggle()
    local msg = "Caps lock"
    if hs.hid.capslock.get() then
        msg = msg .. " on"
        caps_lock_off_label:hide()
        caps_lock_on_label:show(1)
    else
        msg = msg .. " off"
        caps_lock_on_label:hide()
        caps_lock_off_label:show(1)
    end
end

module.key_stroke_fn = function(mod, key, delay)
    delay = delay or (10 * 1000)
    return function()
        hs.eventtap.keyStroke(mod, key, delay)
    end
end

module.system_key_stroke_fn = function(key, delay)
    delay = delay or (10 * 1000)
    return function()
        hs.eventtap.event.newSystemKeyEvent(key, true):post()
        hs.timer.usleep(delay)
        hs.eventtap.event.newSystemKeyEvent(key, false):post()
    end
end

return module
