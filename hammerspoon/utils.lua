local module = {}

function module.tempNotify(timeout, notif)
    notif:send()
    hs.timer.doAfter(timeout, function() notif:withdraw() end)
end

return module
