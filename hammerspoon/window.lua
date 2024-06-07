local prefix = require("prefix")
local utils = require("utils")

hs.window.animationDuration = 0

----------------
-- Switch
----------------
hs.hints.hintChars = utils.str_to_table('ASDFGQWERTZXCVB12345')
prefix.bind('', 'w', function() hs.hints.windowHints() end)

local switcher = hs.window.switcher.new(hs.window.filter.new():setCurrentSpace(true):setDefaultFilter {}, {
    fontName = ".AppleSystemUIFont",
    textSize = 16,
    textColor = { white = 0, alpha = 1 },
    highlightColor = { white = 0.5, alpha = 0.3 },
    backgroundColor = { white = 0.95, alpha = 0.9 },
    titleBackgroundColor = { white = 0.95, alpha = 0 },
    showThumbnails = false,
    showSelectedThumbnail = false,
})

local function next_window()
    switcher:next()
end

local function previous_window()
    switcher:previous()
end

hs.hotkey.bind('alt', 'tab', next_window, nil, next_window)
hs.hotkey.bind('alt-shift', 'tab', previous_window, nil, previous_window)

----------------
-- resize & move
----------------
local arrow_keys = { 'h', 'j', 'k', 'l' }

-- prefix + h -> left half
-- prefix + j -> bottom half
-- prefix + k -> top half
-- prefix + l -> right half
-- prefix + hj -> bottom left quarter
-- prefix + hk -> top left quarter
-- prefix + jl -> top right quarter
-- prefix + kl -> top bottom quarter
-- prefix + lj -> top bottom quarter
-- prefix + jk -> maximize 70%
-- prefix + hl -> full screen
local rect_map = {
    ['h'] = { 0, 0, 0.5, 1 },
    ['j'] = { 0, 0.5, 1, 0.5 },
    ['k'] = { 0, 0, 1, 0.5 },
    ['l'] = { 0.5, 0, 0.5, 1 },
    ['hj'] = { 0, 0.5, 0.5, 0.5 },
    ['hk'] = { 0, 0, 0.5, 0.5 },
    ['jl'] = { 0.5, 0.5, 0.5, 0.5 },
    ['kl'] = { 0.5, 0, 0.5, 0.5 },
    ['hl'] = { 0, 0, 1, 1 },
    ['jk'] = { 0.15, 0.15, 0.7, 0.7 },
}
local was_pressed = { false, false, false, false }
local pressed = { false, false, false, false }

local function resize_window()
    for i = 1, #pressed do
        if pressed[i] then
            return
        end
    end

    local win = hs.window.focusedWindow()
    if win ~= nil then
        local keys = ''
        for i = 1, #was_pressed do
            if was_pressed[i] then
                keys = keys .. arrow_keys[i]
                was_pressed[i] = false
            end
        end
        local rect = rect_map[keys]
        print(keys)
        if rect ~= nil then
            win:moveToUnit(rect)
        end
    end
    prefix.exit()
end

for i = 1, #arrow_keys do
    local pressed_fn = function()
        was_pressed[i] = true
        pressed[i] = true
    end
    local released_fn = function()
        pressed[i] = false
        resize_window()
    end
    prefix.bind_multiple('', arrow_keys[i], pressed_fn, released_fn, nil)
end

-- prefix + ctrl-h -> left one third
-- prefix + ctrl-j -> left two thirds
-- prefix + ctrl-k -> right two thirds
-- prefix + ctrl-l -> right one third
local rect_map_ctrl = {
    ['h'] = { 0, 0, 1 / 3, 1 },
    ['j'] = { 0, 0, 2 / 3, 1 },
    ['k'] = { 1 / 3, 0, 2 / 3, 1 },
    ['l'] = { 2 / 3, 0, 1 / 3, 1 },
}

for k, v in pairs(rect_map_ctrl) do
    local fn = function()
        local win = hs.window.focusedWindow()
        if win ~= nil then
            win:move(v)
        end
    end
    prefix.bind('ctrl', k, fn)
end

-- prefix + shift-hjkl -> move window
local DX = { -1, 0, 0, 1 }
local DY = { 0, 1, -1, 0 }
local DELTA = 20

for i = 1, 4 do
    local move_win = function()
        local win = hs.window.focusedWindow()
        if win ~= nil then
            local p = win:topLeft()
            p.x = p.x + DX[i] * DELTA
            p.y = p.y + DY[i] * DELTA
            win:setTopLeft(p)
        end
    end
    prefix.bind('shift', arrow_keys[i], move_win, true)
end

-- prefix + ; -> move window to the next screen

local function get_next_screen(s)
    local all = hs.screen.allScreens()
    for i = 1, #all do
        if all[i] == s then
            return all[(i - 1 + 1) % #all + 1]
        end
    end
    return nil
end

local function move_to_next_screen()
    local win = hs.window.focusedWindow()
    if win ~= nil then
        local currentScreen = win:screen()
        local nextScreen = get_next_screen(currentScreen)
        if nextScreen then
            win:moveToScreen(nextScreen)
        end
    end
end

prefix.bind('', ';', move_to_next_screen)

-- prefix + - -> shrink window frame
-- prefix + = -> expand window frame

local function expand_win(ratio)
    local win = hs.window.focusedWindow()
    if win == nil then
        return
    end
    local frame = win:frame()
    local cx = frame.x + frame.w / 2
    local cy = frame.y + frame.h / 2
    local nw = frame.w * ratio
    local nh = frame.h * ratio
    local nx = cx - nw / 2
    local ny = cy - nh / 2
    win:setFrame(hs.geometry.rect(nx, ny, nw, nh))
end

prefix.bind('', '-', function() expand_win(0.9) end)
prefix.bind('', '=', function() expand_win(1.1) end)


-- prefix + cmd-hjkl -> expand window edges
-- prefix + cmd-shift-hjkl -> shrink window edges
--
local function expand_edge(edge, ratio)
    local win = hs.window.focusedWindow()
    if win == nil then
        return
    end
    local frame = win:frame()
    local x, y, w, h = frame.x, frame.y, frame.w, frame.h
    if edge == 'h' then
        w = frame.w * ratio
        x = frame.x + frame.w - w
    elseif edge == 'j' then
        h = frame.h * ratio
    elseif edge == 'k' then
        h = frame.h * ratio
        y = frame.y + frame.h - h
    elseif edge == 'l' then
        w = frame.w * ratio
    else
        return
    end
    win:setFrame(hs.geometry.rect(x, y, w, h))
end

local edges = { 'h', 'j', 'k', 'l' }
local ratios = { 0.9, 1.111111 }

for i = 1, #edges do
    local edge = edges[i]
    for j = 1, #ratios do
        local mod = (ratios[j] > 1) and 'cmd' or 'cmd+shift'
        local fn = function() expand_edge(edge, ratios[j]) end
        prefix.bind(mod, edge, fn, true)
    end
end
