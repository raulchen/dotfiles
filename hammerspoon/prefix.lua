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

local function cancel_timeout()
    if timer then
        timer:stop()
    end
end

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
    cancel_timeout()
end

function module.exit()
    modal:exit()
end

function module.bind(mod, key, fn, can_repeat)
    if can_repeat ~= true then
        modal:bind(mod, key, nil, function()
            module.exit()
            fn()
        end, nil)
    else
        local pressed_fn = function()
            fn()
            cancel_timeout()
        end
        modal:bind(mod, key, pressed_fn, nil, fn)
    end
end

function module.bind_multiple(mod, key, pressed_fn, released_fn, repeat_fn)
    modal:bind(mod, key, pressed_fn, released_fn, repeat_fn)
end

module.bind('', 'escape', module.exit)

module.bind('', 'd', hs.toggleConsole)
module.bind('', 'r', hs.reload)

module.bind('', 'a', hs.hid.capslock.toggle)

local function switch_primary_monitor()
    hs.screen.primaryScreen():next():setPrimary()
end

module.bind('', 'm', switch_primary_monitor)

return module
