local key_stroke_fn = require("utils").key_stroke_fn
local system_key_stroke_fn = require("utils").system_key_stroke_fn

-- ctrl+[ -> escape
hs.hotkey.bind({ 'ctrl' }, '[', nil, function() hs.eventtap.keyStroke({}, 'escape', 0) end)

-- alt-hjkl -> arrow keys
hs.hotkey.bind({ 'alt' }, 'h', key_stroke_fn({}, 'left'), nil, key_stroke_fn({}, 'left'))
hs.hotkey.bind({ 'alt' }, 'j', key_stroke_fn({}, 'down'), nil, key_stroke_fn({}, 'down'))
hs.hotkey.bind({ 'alt' }, 'k', key_stroke_fn({}, 'up'), nil, key_stroke_fn({}, 'up'))
hs.hotkey.bind({ 'alt' }, 'l', key_stroke_fn({}, 'right'), nil, key_stroke_fn({}, 'right'))

-- alt-m/n and alt-2/1 -> ctrl-tab and ctrl-shift-tab
hs.hotkey.bind({ 'alt' }, 'm', key_stroke_fn({ 'ctrl' }, 'tab'), nil, key_stroke_fn({ 'ctrl' }, 'tab'))
hs.hotkey.bind({ 'alt' }, 'n', key_stroke_fn({ 'ctrl', 'shift' }, 'tab'), nil, key_stroke_fn({ 'ctrl', 'shift' }, 'tab'))
hs.hotkey.bind({ 'alt', 'ctrl' }, 'tab', key_stroke_fn({ 'ctrl', 'shift' }, 'tab'), nil, key_stroke_fn({ 'ctrl', 'shift' }, 'tab'))

-- alt-,/. -> volume down/up, alt-/ -> mute
hs.hotkey.bind({ 'alt' }, ',', system_key_stroke_fn('SOUND_DOWN'), nil, system_key_stroke_fn('SOUND_DOWN'))
hs.hotkey.bind({ 'alt' }, '.', system_key_stroke_fn('SOUND_UP'), nil, system_key_stroke_fn('SOUND_UP'))
hs.hotkey.bind({ 'alt' }, '/', nil, system_key_stroke_fn('MUTE'))

-- ctrl+cmd+tab -> ctrl+shift+tab (eventtap needed to intercept before apps see it)
_ctrl_cmd_tab_tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
    local flags = e:getFlags()
    if flags.ctrl and flags.cmd and not flags.alt and not flags.shift then
        if e:getKeyCode() == 48 then  -- tab
            hs.eventtap.keyStroke({ 'ctrl', 'shift' }, 'tab', 0)
            return true
        end
    end
end)
_ctrl_cmd_tab_tap:start()
