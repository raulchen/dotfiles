local REPEAT_FASTER = 10 * 1000
local REPEAT_SLOWER = 100 * 1000
local NO_REPEAT = -1

local function key_stroke(mod, key, repeat_delay)
    hs.eventtap.event.newKeyEvent(mod, key, true):post()
    if repeat_delay <= 0 then
        repeat_delay = REPEAT_FASTER
    end
    hs.timer.usleep(repeat_delay)
    hs.eventtap.event.newKeyEvent(mod, key, false):post()
end

local function key_stroke_system(key, repeat_delay)
    hs.eventtap.event.newSystemKeyEvent(key, true):post()
    if repeat_delay <= 0 then
        repeat_delay = REPEAT_FASTER
    end
    hs.timer.usleep(repeat_delay)
    hs.eventtap.event.newSystemKeyEvent(key, false):post()
end

-- Map source_key + source_mod -> target_key + target_mod
local function keymap(source_key, source_mod, target_key, target_mod, repeat_delay)
    source_mod = source_mod or {}

    repeat_delay = repeat_delay or REPEAT_FASTER
    local noRepeat = repeat_delay <= 0

    local fn = nil
    if target_mod == nil then
        fn = hs.fnutils.partial(key_stroke_system, string.upper(target_key), repeat_delay)
    else
        target_mod = require("utils").split_str(target_mod, '+')
        fn = hs.fnutils.partial(key_stroke, target_mod, target_key, repeat_delay)
    end
    if noRepeat then
        hs.hotkey.bind(source_mod, source_key, fn, nil, nil)
    else
        hs.hotkey.bind(source_mod, source_key, fn, nil, fn)
    end
end

-- ------------------
-- move
-- ------------------
local arrows = {
    h = 'left',
    j = 'down',
    k = 'up',
    l = 'right'
}
for k, v in pairs(arrows) do
    keymap(k, 'alt', v, '')
    keymap(k, 'alt+shift', v, 'shift')
    keymap(k, 'alt+ctrl', v, 'alt')
    keymap(k, 'alt+shift+ctrl', v, 'shift+alt')
end

-- ------------------
-- functionalities
-- ------------------
keymap('n', 'alt', 'tab', 'ctrl+shift', REPEAT_SLOWER)
keymap('m', 'alt', 'tab', 'ctrl', REPEAT_SLOWER)

keymap('[', 'ctrl', 'escape', '', NO_REPEAT)

-- ------------------
-- system
-- ------------------

keymap('p', 'alt', 'PLAY', nil, NO_REPEAT)
keymap('[', 'alt', 'REWIND', nil, NO_REPEAT)
keymap(']', 'alt', 'FAST', nil, NO_REPEAT)
keymap(',', 'alt', 'SOUND_DOWN', nil)
keymap('.', 'alt', 'SOUND_UP', nil)
keymap('/', 'alt', 'MUTE', nil)
