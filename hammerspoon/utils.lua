local module = {}

function module.tempNotify(timeout, notif)
    notif:send()
    hs.timer.doAfter(timeout, function() notif:withdraw() end)
end

function module.splitStr(str, sep)
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

function module.strToTable(str)
    local t = {}
    for i = 1, #str do
        t[i] = str:sub(i, i)
    end
    return t
end

return module
