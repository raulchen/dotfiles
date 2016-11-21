utils = require('utils')
volume = require('volume')

local REPEAT_FASTER = 10 * 1000
local REPEAT_SLOWER = 100 * 1000
local NO_REPEAT = -1

local function keyStroke(mod, key, repeatDelay)
    hs.eventtap.event.newKeyEvent(mod, key, true):post()
    if repeatDelay > 0 then
        hs.timer.usleep(repeatDelay)
    end
    hs.eventtap.event.newKeyEvent(mod, key, false):post()
end

local function keymap(sourceKey, sourceMod, targetKey, targetMod, repeatDelay)
    sourceMod = sourceMod or {}
    targetMod = utils.splitStr(targetMod or '', '+')

	repeatDelay = repeatDelay or REPEAT_FASTER
	noRepeat = repeatDelay <= 0

    fn = hs.fnutils.partial(keyStroke, targetMod, targetKey, repeatDelay)
	if not noRepeat then
		hs.hotkey.bind(sourceMod, sourceKey, fn, nil, fn)
	else
		hs.hotkey.bind(sourceMod, sourceKey, fn, nil, nil)
	end
end

-- ------------------
-- move
-- ------------------
arrows = {
	h = 'left',
	j = 'down',
	k = 'up',
	l = 'right'
}
for k, v in pairs(arrows) do
	keymap(k, 'alt', v, '')
	keymap(k, 'alt+shift', v, 'alt')
	keymap(k, 'alt+shift+ctrl', v, 'shift')
end

keymap('y', 'alt', 'home', '')
keymap('u', 'alt', 'end', '')
keymap('i', 'alt', 'pageup', '')
keymap('o', 'alt', 'pagedown', '')

-- ------------------
-- delete
-- ------------------
keymap('d', 'alt', 'delete', '')
keymap('f', 'alt', 'forwarddelete', '')
keymap('d', 'alt+shift', 'delete', 'alt')
keymap('f', 'alt+shift', 'forwarddelete', 'alt')

-- ------------------
-- functionalities
-- ------------------
keymap('n', 'alt', 'tab', 'ctrl+shift', REPEAT_SLOWER)
keymap('m', 'alt', 'tab', 'ctrl', REPEAT_SLOWER)

keymap('q', 'alt', 'escape', '', NO_REPEAT)

hs.hotkey.bind('alt', ',', volume.up, nil, volume.down)
hs.hotkey.bind('alt', '.', volume.up, nil, volume.down)
