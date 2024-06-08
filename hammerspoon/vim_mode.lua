local module = {}

local logger = hs.logger.new('vim_mode', 'debug')

local current_mode = nil

local function new_mode(name)
    local modal = hs.hotkey.modal.new()
    local label = require("labels").new(name)

    function modal:entered()
        logger.d("Entered " .. name)
        current_mode = name
        if name ~= "insert" then
            label:show()
        end
    end

    function modal:exited()
        logger.d("Exited " .. name)
        current_mode = nil
        label:hide()
    end

    return {
        name = name,
        modal = modal,
    }
end

local insert = new_mode("insert")
local normal = new_mode("normal")
local visual = new_mode("visual")

local modes = {
    insert = insert,
    normal = normal,
    visual = visual,
}

local function switch_to_mode(mode)
    if current_mode then
        modes[current_mode].modal:exit()
    end
    mode.modal:enter()
end

switch_to_mode(insert)

module.toggle = function()
    if current_mode ~= "insert" then
        switch_to_mode(insert)
    else
        switch_to_mode(normal)
    end
end

local toggler = hs.hotkey.bind({ "ctrl" }, "[", function()
    module.toggle()
end)

hs.window.filter.new('kitty')
    :subscribe(hs.window.filter.windowFocused, function()
        toggler:disable()
    end)
    :subscribe(hs.window.filter.windowUnfocused, function()
        toggler:enable()
    end)

local key_stroke_fn = function(mod, key)
    return function()
        hs.eventtap.keyStroke(mod, key, 20 * 1000)
    end
end

local bind_fn = function(mode, source_mod, source_key, fn, can_repeat)
    local pressed_fn = nil
    local released_fn = nil
    local repeat_fn = nil

    if not can_repeat then
        released_fn = fn
    else
        pressed_fn = fn
        repeat_fn = fn
    end
    mode.modal:bind(source_mod, source_key, pressed_fn, released_fn, repeat_fn)
end

local bind_key = function(mode, source_mod, source_key, target_mod, target_key, can_repeat)
    local fn = key_stroke_fn(target_mod, target_key)
    bind_fn(mode, source_mod, source_key, fn, can_repeat)
end


bind_key(normal, {}, 'h', {}, 'left', true)
bind_key(normal, {}, 'j', {}, 'down', true)
bind_key(normal, {}, 'k', {}, 'up', true)
bind_key(normal, {}, 'l', {}, 'right', true)

bind_key(normal, {}, 'w', { 'alt' }, 'right', true)
bind_key(normal, {}, 'e', { 'alt' }, 'right', true)
bind_key(normal, {}, 'b', { 'alt' }, 'left', true)

bind_key(normal, {}, '0', { 'cmd' }, 'left', false)
bind_key(normal, { 'shift' }, '4', { 'cmd' }, 'right', false) -- $

-- TODO gg -> go to top
bind_key(normal, { 'shift' }, 'g', { 'cmd' }, 'down', false)

bind_key(normal, {}, 'x', {}, 'del', false)

bind_key(normal, { 'ctrl' }, 'u', {}, 'pageup', true)
bind_key(normal, { 'ctrl' }, 'd', {}, 'pagedown', true)

bind_key(normal, {}, 'u', { 'cmd' }, 'z', false)
bind_key(normal, { 'ctrl' }, 'r', { 'shift', 'cmd' }, 'z', false)

bind_fn(normal, {}, 'i', function()
    switch_to_mode(insert)
end, false)

bind_fn(normal, { 'shift' }, 'i', function()
    key_stroke_fn({ 'cmd' }, 'left')()
    switch_to_mode(insert)
end, false)

bind_fn(normal, {}, 'a', function()
    key_stroke_fn({}, 'right')()
    switch_to_mode(insert)
end, false)

bind_fn(normal, { 'shift' }, 'a', function()
    key_stroke_fn({ 'cmd' }, 'right')()
    switch_to_mode(insert)
end, false)

bind_fn(normal, {}, 'v', function()
    switch_to_mode(visual)
end, false)


-- ==== Visual mode ====

bind_key(visual, {}, 'h', { 'shift' }, 'left', true)
bind_key(visual, {}, 'j', { 'shift' }, 'down', true)
bind_key(visual, {}, 'k', { 'shift' }, 'up', true)
bind_key(visual, {}, 'l', { 'shift' }, 'right', true)

bind_key(visual, {}, 'w', { 'shift', 'alt' }, 'right', true)
bind_key(visual, {}, 'e', { 'shift', 'alt' }, 'right', true)
bind_key(visual, {}, 'b', { 'shift', 'alt' }, 'left', true)

bind_key(visual, {}, '0', { 'shift', 'cmd' }, 'left', false)
bind_key(visual, { 'shift' }, '4', { 'shift', 'cmd' }, 'right', false) -- $

bind_key(visual, { 'shift' }, 'g', { 'shift', 'cmd' }, 'down', false)

bind_key(visual, {}, 'y', { 'cmd' }, 'c', false)
bind_key(visual, {}, 'u', { 'cmd' }, 'z', false)
bind_key(visual, { 'ctrl' }, 'r', { 'shift', 'cmd' }, 'z', false)

bind_fn(visual, {}, 'v', function()
    switch_to_mode(normal)
end, false)

bind_fn(visual, {}, 'escape', function()
    switch_to_mode(normal)
end, false)

return module
