local module = {}

local logger = hs.logger.new('vim_mode', 'debug')

local current_mode = nil

local function new_mode(name)
    local modal = hs.hotkey.modal.new()
    local label = require("labels").new(name, "bottom_right")

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
local normal_g = new_mode("normal:g")
local normal_c = new_mode("normal:c")
local normal_d = new_mode("normal:d")
local visual = new_mode("visual")
local visual_g = new_mode("visual:g")

local modes = {
    insert = insert,
    normal = normal,
    ["normal:g"] = normal_g,
    ["normal:c"] = normal_c,
    ["normal:d"] = normal_d,
    visual = visual,
    ["visual:g"] = visual_g,
}

local function switch_to_mode(mode)
    if current_mode then
        modes[current_mode].modal:exit()
    end
    mode.modal:enter()
end

module.toggle = function()
    if current_mode ~= "insert" then
        switch_to_mode(insert)
    else
        switch_to_mode(normal)
    end
end

-- Use ctrl + [ to toggle insert/normal modes
local toggler = hs.hotkey.bind({ "ctrl" }, "[", function()
    module.toggle()
end)

-- Disable vim mode for kitty.
hs.window.filter.new('kitty')
    :subscribe(hs.window.filter.windowFocused, function()
        switch_to_mode(insert)
        toggler:disable()
    end)
    :subscribe(hs.window.filter.windowUnfocused, function()
        toggler:enable()
    end)

local key_stroke_fn = require("utils").key_stroke_fn
local system_key_stroke_fn = require("utils").system_key_stroke_fn

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

-- === Normal mode ===

-- hjkl movements
bind_key(normal, {}, 'h', {}, 'left', true)
bind_key(normal, {}, 'j', {}, 'down', true)
bind_key(normal, {}, 'k', {}, 'up', true)
bind_key(normal, {}, 'l', {}, 'right', true)

-- w/e -> move forward by word
bind_key(normal, {}, 'w', { 'alt' }, 'right', true)
bind_key(normal, {}, 'e', { 'alt' }, 'right', true)
-- b -> move backward by word
bind_key(normal, {}, 'b', { 'alt' }, 'left', true)

-- 0/$ -> move to the beginning/end of the line
bind_key(normal, {}, '0', { 'cmd' }, 'left', false)
bind_key(normal, { 'shift' }, '4', { 'cmd' }, 'right', false)

-- gg -> move to the beginning of the file
bind_fn(normal, {}, 'g', function()
    switch_to_mode(normal_g)
end, false)
bind_fn(normal_g, {}, 'g', function()
    key_stroke_fn({ 'cmd' }, 'up')()
    switch_to_mode(normal)
end, false)

-- G -> move to the end of the file
bind_key(normal, { 'shift' }, 'g', { 'cmd' }, 'down', false)

-- ctrl + u/d -> page up/down
bind_key(normal, { 'ctrl' }, 'u', {}, 'pageup', true)
bind_key(normal, { 'ctrl' }, 'd', {}, 'pagedown', true)

-- p -> paste
bind_key(normal, {}, 'p', { 'cmd' }, 'v', false)

-- x -> delete character forward
bind_key(normal, {}, 'x', {}, 'forwarddelete', true)

-- Implement c_ d_ commands
bind_fn(normal, {}, 'c', function()
    switch_to_mode(normal_c)
end, false)
bind_fn(normal, {}, 'd', function()
    switch_to_mode(normal_d)
end, false)
for _, op in ipairs({ 'c', 'd' }) do
    local mode = op == 'c' and normal_c or normal_d
    local target_mode = op == 'c' and insert or normal
    -- w/e -> delete word forward
    bind_fn(mode, {}, 'w', function()
        key_stroke_fn({ 'alt' }, 'forwarddelete')()
        switch_to_mode(target_mode)
    end, false)
    bind_fn(mode, {}, 'e', function()
        key_stroke_fn({ 'alt' }, 'forwarddelete')()
        switch_to_mode(target_mode)
    end, false)
    -- b -> delete word backwards
    bind_fn(mode, {}, 'b', function()
        key_stroke_fn({ 'alt' }, 'delete')()
        switch_to_mode(target_mode)
    end, false)
    -- 0/$ -> delete to the beginning/end of the line
    bind_fn(mode, {}, '0', function()
        key_stroke_fn({ 'cmd' }, 'delete')()
        switch_to_mode(target_mode)
    end, false)
    bind_fn(mode, { 'shift' }, '4', function()
        key_stroke_fn({ 'ctrl' }, 'k')()
        switch_to_mode(target_mode)
    end, false)
    -- cc/dd -> delete the whole line
    bind_fn(mode, {}, op, function()
        key_stroke_fn({ 'cmd' }, 'right')()
        key_stroke_fn({ 'cmd' }, 'delete')()
        if op == 'd' then
            key_stroke_fn({ '' }, 'forwarddelete')()
        end
        switch_to_mode(target_mode)
    end, false)
    -- C/D -> delete to the end of the line
    bind_fn(normal, { 'shift' }, op, function()
        key_stroke_fn({ 'ctrl' }, 'k')()
        switch_to_mode(target_mode)
    end, false)
end

-- u -> undo
bind_key(normal, {}, 'u', { 'cmd' }, 'z', false)
-- ctrl + r -> redo
bind_key(normal, { 'ctrl' }, 'r', { 'shift', 'cmd' }, 'z', false)

-- i/I/a/A/o/O -> switch to insert mode
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
bind_fn(normal, {}, 'o', function()
    key_stroke_fn({ 'cmd' }, 'right')()
    key_stroke_fn({ '' }, 'return')()
    switch_to_mode(insert)
end, false)
bind_fn(normal, { 'shift' }, 'o', function()
    key_stroke_fn({ 'cmd' }, 'left')()
    key_stroke_fn({ '' }, 'return')()
    key_stroke_fn({ '' }, 'up')()
    switch_to_mode(insert)
end, false)

-- v -> switch to visual mode
bind_fn(normal, {}, 'v', function()
    switch_to_mode(visual)
end, false)

-- ==== Visual mode ====

-- hjkl movements
bind_key(visual, {}, 'h', { 'shift' }, 'left', true)
bind_key(visual, {}, 'j', { 'shift' }, 'down', true)
bind_key(visual, {}, 'k', { 'shift' }, 'up', true)
bind_key(visual, {}, 'l', { 'shift' }, 'right', true)

-- w/e -> move forward by word
bind_key(visual, {}, 'w', { 'shift', 'alt' }, 'right', true)
bind_key(visual, {}, 'e', { 'shift', 'alt' }, 'right', true)
-- b -> move backward by word
bind_key(visual, {}, 'b', { 'shift', 'alt' }, 'left', true)

-- 0/$ -> move to the beginning/end of the line
bind_key(visual, {}, '0', { 'shift', 'cmd' }, 'left', false)
bind_key(visual, { 'shift' }, '4', { 'shift', 'cmd' }, 'right', false)

-- gg -> move to the beginning of the file
bind_fn(visual, {}, 'g', function()
    switch_to_mode(visual_g)
end, false)
bind_fn(visual_g, {}, 'g', function()
    key_stroke_fn({ 'shift', 'cmd' }, 'up')()
    switch_to_mode(visual)
end, false)
-- G -> move to the end of the file
bind_key(visual, { 'shift' }, 'g', { 'shift', 'cmd' }, 'down', false)

-- y -> copy
bind_key(visual, {}, 'y', { 'cmd' }, 'c', false)
-- p -> paste
bind_key(visual, {}, 'p', { 'cmd' }, 'v', false)

-- x/d -> delete visual selection
bind_key(visual, {}, 'x', {}, 'delete', false)
bind_key(visual, {}, 'd', {}, 'delete', false)

-- u -> undo
bind_key(visual, {}, 'u', { 'cmd' }, 'z', false)
-- ctrl + r -> redo
bind_key(visual, { 'ctrl' }, 'r', { 'shift', 'cmd' }, 'z', false)

-- v/esc -> switch to normal mode
bind_fn(visual, {}, 'v', function()
    -- TODO: cancel visual selection
    switch_to_mode(normal)
end, false)
bind_fn(visual, {}, 'escape', function()
    -- TODO: cancel visual selection
    switch_to_mode(normal)
end, false)

-- ==== Insert mode ====

-- alt-hjkl -> arrow keys
bind_key(insert, { 'alt' }, 'h', {}, 'left', true)
bind_key(insert, { 'alt' }, 'j', {}, 'down', true)
bind_key(insert, { 'alt' }, 'k', {}, 'up', true)
bind_key(insert, { 'alt' }, 'l', {}, 'right', true)

-- alt-m/n -> ctrl-tab and ctrl-shift-tab
bind_key(insert, { 'alt' }, 'm', { 'ctrl' }, 'tab', true)
bind_key(insert, { 'alt' }, 'n', { 'ctrl', 'shift' }, 'tab', true)

bind_fn(insert, { 'alt' }, ',', system_key_stroke_fn('SOUND_DOWN'), true)
bind_fn(insert, { 'alt' }, '.', system_key_stroke_fn('SOUND_UP'), true)
bind_fn(insert, { 'alt' }, '/', system_key_stroke_fn('MUTE'), false)

switch_to_mode(insert)
return module
