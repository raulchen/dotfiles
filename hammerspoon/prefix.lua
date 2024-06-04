-- Tmux style hotkey binding: prefix + hotkey

local module = {}

local TIMEOUT = 5

-- Assign an impossible hotkey for the modal. And use another hotkey to trigger the modal.
-- Because we want to temporarily disable the modal hotkey in the "ctrl+`" callback, which
-- isn't supported by hs.hotkey.modal.
local modal = hs.hotkey.modal.new({ "ctrl" }, "F19")
local trigger_modal = hs.hotkey.new({ "ctrl" }, "`", function() modal:enter() end)
trigger_modal:enable()

function modal:entered()
    modal.alertId = hs.alert.show("Prefix Mode", 9999)
    modal.timer = hs.timer.doAfter(TIMEOUT, function() modal:exit() end)
end

function modal:exited()
    if modal.alertId then
        hs.alert.closeSpecific(modal.alertId)
    end
    module.cancelTimeout()
end

function module.exit()
    modal:exit()
end

function module.cancelTimeout()
    if modal.timer then
        modal.timer:stop()
    end
end

function module.bind(mod, key, fn)
    modal:bind(mod, key, nil, function()
        fn(); module.exit()
    end)
end

function module.bindMultiple(mod, key, pressedFn, releasedFn, repeatFn)
    modal:bind(mod, key, pressedFn, releasedFn, repeatFn)
end

module.bind('', 'escape', module.exit)
-- "ctrl+`" again to exit the modal and send the "ctrl+`" key event.
module.bind({ 'ctrl' }, '`', function()
    modal:exit()
    trigger_modal:disable()
    hs.eventtap.keyStroke({ 'ctrl' }, '`')
    hs.timer.doAfter(1, function() trigger_modal:enable() end)
end)

module.bind('', 'd', hs.toggleConsole)
module.bind('', 'r', hs.reload)

return module
