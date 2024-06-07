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

function module.toggle_caps_lock()
    hs.hid.capslock.toggle()
    local msg = "Caps lock"
    if hs.hid.capslock.get() then
        msg = msg .. " on"
    else
        msg = msg .. " off"
    end
    require("labels").show(msg, 1)
end

return module
