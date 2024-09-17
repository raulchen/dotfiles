local module = {}

local logger = hs.logger.new('vim_mode', 'info')

local current_mode = nil

local mode_entered = function(mode)
    logger.d("Entered " .. mode.name)
    current_mode = mode.name
    if mode.name ~= "insert" then
        mode.label:show()
    end
end

local mode_exited = function(mode)
    logger.d("Exited " .. mode.name)
    current_mode = nil
    mode.label:hide()
end

local function new_mode(name)
    local mode = {
        name = name,
        modal = hs.hotkey.modal.new(),
        label = require("labels").new(name, "bottom_right"),
    }

    mode.modal.entered = function()
        mode_entered(mode)
    end
    mode.modal.exited = function()
        mode_exited(mode)
    end

    return mode
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

-- Disable vim mode for terminal apps.
hs.window.filter.new({ "kitty", "WezTerm" })
    :subscribe(hs.window.filter.windowFocused, function()
        switch_to_mode(insert)
        toggler:disable()
    end)
    :subscribe(hs.window.filter.windowUnfocused, function()
        toggler:enable()
    end)

local key_stroke_fn = require("utils").key_stroke_fn
local system_key_stroke_fn = require("utils").system_key_stroke_fn

local bind_fn = function(mode, mod, key, fn, can_repeat)
    local pressed_fn = nil
    local released_fn = nil
    local repeat_fn = nil

    if not can_repeat then
        released_fn = fn
    else
        pressed_fn = fn
        repeat_fn = fn
    end
    mode.modal:bind(mod, key, pressed_fn, released_fn, repeat_fn)
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

-- ctrl + u/d -> move up/down N lines
local CTRL_UD_NUM_LINES = 20
local CTRL_UD_KEY_PRESS_DELAY = 500
bind_fn(normal, { 'ctrl' }, 'u', function()
    for _ = 1, CTRL_UD_NUM_LINES do
        key_stroke_fn({}, 'up', CTRL_UD_KEY_PRESS_DELAY)()
    end
end, true)
bind_fn(normal, { 'ctrl' }, 'd', function()
    for _ = 1, CTRL_UD_NUM_LINES do
        key_stroke_fn({}, 'down', CTRL_UD_KEY_PRESS_DELAY)()
    end
end, true)

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
bind_key(normal, {}, 'u', { 'cmd' }, 'z', true)
-- ctrl + r -> redo
bind_key(normal, { 'ctrl' }, 'r', { 'shift', 'cmd' }, 'z', true)

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
-- V -> select current line and switch to visual mode
-- TODO: implement real line-wise visual mode.
bind_fn(normal, { 'shift' }, 'v', function()
    key_stroke_fn({ 'cmd' }, 'left')()
    key_stroke_fn({ 'shift', 'cmd' }, 'right')()
    switch_to_mode(visual)
    visual.is_cursor_right_to_start = true
end, false)

-- ==== Visual mode ====

-- Whether the cursor is on the right side of
-- the visual selection start.
visual.is_cursor_right_to_start = nil

visual.modal.entered = function()
    mode_entered(visual)
    visual.is_cursor_right_to_start = nil
end

local visual_bind_key = function(source_mod, source_key, target_mod, target_key, right)
    table.insert(target_mod, 'shift')
    local fn = function()
        key_stroke_fn(target_mod, target_key)()
        visual.is_cursor_right_to_start = right
    end
    bind_fn(visual, source_mod, source_key, fn, true)
end

-- hjkl movements
visual_bind_key({}, 'h', {}, 'left', false)
visual_bind_key({}, 'j', {}, 'down', true)
visual_bind_key({}, 'k', {}, 'up', false)
visual_bind_key({}, 'l', {}, 'right', true)

-- w/e -> move forward by word
visual_bind_key({}, 'w', { 'alt' }, 'right', true)
visual_bind_key({}, 'e', { 'alt' }, 'right', true)
-- b -> move backward by word
visual_bind_key({}, 'b', { 'alt' }, 'left', false)

-- 0/$ -> move to the beginning/end of the line
visual_bind_key({}, '0', { 'cmd' }, 'left', false)
visual_bind_key({ 'shift' }, '4', { 'cmd' }, 'right', true)

-- ctrl-u/d -> move up/down N lines
bind_fn(visual, { 'ctrl' }, 'u', function()
    for _ = 1, CTRL_UD_NUM_LINES do
        key_stroke_fn({ 'shift' }, 'up', CTRL_UD_KEY_PRESS_DELAY)()
    end
end, true)
bind_fn(visual, { 'ctrl' }, 'd', function()
    for _ = 1, CTRL_UD_NUM_LINES do
        key_stroke_fn({ 'shift' }, 'down', CTRL_UD_KEY_PRESS_DELAY)()
    end
end, true)

-- gg -> move to the beginning of the file
bind_fn(visual, {}, 'g', function()
    switch_to_mode(visual_g)
end, false)
bind_fn(visual_g, {}, 'g', function()
    key_stroke_fn({ 'shift', 'cmd' }, 'up')()
    visual.is_cursor_right_to_start = false
    switch_to_mode(visual)
end, false)
-- G -> move to the end of the file
visual_bind_key({ 'shift' }, 'g', { 'cmd' }, 'down', true)

local visual_to_normal = function(clear_selection)
    if clear_selection == nil then
        clear_selection = true
    end
    if clear_selection then
        -- Clear visual selection and move the cursor to
        -- the visual selection start position.
        if visual.is_cursor_right_to_start ~= nil then
            if visual.is_cursor_right_to_start then
                key_stroke_fn({}, 'right')()
            else
                key_stroke_fn({}, 'left')()
            end
        end
    end
    switch_to_mode(normal)
end

-- y -> copy
bind_fn(visual, {}, 'y', function()
    key_stroke_fn({ 'cmd' }, 'c')()
    visual_to_normal()
end, false)
-- p -> paste
bind_fn(visual, {}, 'p', function()
    key_stroke_fn({ 'cmd' }, 'v')()
    visual_to_normal()
end, false)

-- x/d -> delete visual selection
bind_fn(visual, {}, 'x', function()
    key_stroke_fn({ '' }, 'forwarddelete')()
    visual_to_normal(false)
end, false)
bind_fn(visual, {}, 'd', function()
    key_stroke_fn({ '' }, 'forwarddelete')()
    visual_to_normal(false)
end, false)

-- c -> delete visual selection and switch to insert mode
bind_fn(visual, {}, 'c', function()
    key_stroke_fn({ '' }, 'forwarddelete')()
    switch_to_mode(insert)
end, false)

-- v/esc/ctrl-[ -> switch to normal mode
bind_fn(visual, {}, 'v', visual_to_normal, false)
bind_fn(visual, {}, 'escape', visual_to_normal, false)
bind_fn(visual, { 'ctrl' }, '[', visual_to_normal, false)

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
