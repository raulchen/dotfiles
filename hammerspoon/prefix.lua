-- Simulate tmux's key binding: prefix + hotkey
local module = {}

local TIMEOUT = 5

local modal = hs.hotkey.modal.new('ctrl', 'space')

function modal:entered()
	modal.alertId = hs.alert.show("Prefix mode", TIMEOUT)
	hs.timer.doAfter(TIMEOUT, function() modal:exit() end)
end

function modal:exited()
    if modal.alertId then
        hs.alert.closeSpecific(modal.alertId)
    end
end

modal:bind('', 'escape', function() modal:exit() end)
modal:bind('ctrl', 'space', function() modal:exit() end)

function module.bind(mod, key, fn, autoExit)
    if autoExit == nil or autoExit then
        bindFn = function()
            modal:exit()
            fn()
        end
    else
        bindFn = fn
    end
    modal:bind(mod, key, bindFn)
end

module.bind('', 'd', hs.toggleConsole)

return module
