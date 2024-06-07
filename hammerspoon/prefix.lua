-- Tmux style hotkey binding: prefix + hotkey

local module = {}

local TIMEOUT = 5

local modal = hs.hotkey.modal.new()
module.enabled = false

module.toggle = function()
    if not module.enabled then
        modal:enter()
    else
        modal:exit()
    end
end

local alert_id = nil
local timer = nil

function modal:entered()
    module.enabled = true
    alert_id = hs.alert.show("Prefix Mode", 9999)
    timer = hs.timer.doAfter(TIMEOUT, function() modal:exit() end)
end

function modal:exited()
    module.enabled = false
    if alert_id then
        hs.alert.closeSpecific(alert_id)
    end
    module.cancelTimeout()
end

function module.exit()
    modal:exit()
end

function module.cancelTimeout()
    if timer then
        timer:stop()
    end
end

function module.bind(mod, key, fn)
    modal:bind(mod, key, nil, function()
        module.exit()
        fn()
    end, nil)
end

function module.bindMultiple(mod, key, pressedFn, releasedFn, repeatFn)
    modal:bind(mod, key, pressedFn, releasedFn, repeatFn)
end

module.bind('', 'escape', module.exit)

module.bind('', 'd', hs.toggleConsole)
module.bind('', 'r', hs.reload)

module.bind('', 'a', hs.hid.capslock.toggle)

return module
