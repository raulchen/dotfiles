local prefix = require("prefix")
local utils = require("utils")

----------------
-- Grid
----------------
hs.grid.setGrid('6x4', nil, nil)
hs.grid.setMargins({0, 0})
prefix.bind('', 'g', function() hs.grid.show() end)

----------------
-- Switch
----------------
hs.hints.hintChars = utils.strToTable('ASDFGQWERTZXCVB12345')
prefix.bind('', 'w', function() hs.hints.windowHints() end)

local switcher = hs.window.switcher.new(nil, {
    fontName = ".AppleSystemUIFont",
    textSize = 16,
    textColor = { white = 0, alpha = 1 },
    highlightColor = { white = 0.6, alpha = 0.9 },
    backgroundColor = { white = 1, alpha = 0.8 },
    titleBackgroundColor = { white = 0.9, alpha = 0.9 },
    showThumbnails = false,
    showSelectedThumbnail = false,
})

local function nextWindow()
    switcher:next()
end

local function previousWindow()
    switcher:previous()
end

hs.hotkey.bind('alt', 'tab', nextWindow, nil, nextWindow)
hs.hotkey.bind('alt-shift', 'tab', previousWindow, nil, previousWindow)

----------------
-- resize & move
----------------
local arrowKeys = {'h', 'j', 'k', 'l'}

-- prefix + h -> left half
-- prefix + j -> bottom half
-- prefix + k -> top half
-- prefix + l -> right half
-- prefix + hj -> bottom left quarter
-- prefix + hk -> top left quarter
-- prefix + jl -> top right quarter
-- prefix + kl -> top bottom quarter
-- prefix + lj -> top bottom quarter
-- prefix + jk -> center
-- prefix + hl -> full screen
local rectMap = {
    ['h'] = {0, 0, 0.5, 1},
    ['j'] = {0, 0.5, 1, 0.5},
    ['k'] = {0, 0, 1, 0.5},
    ['l'] = {0.5, 0, 0.5, 1},
    ['hj'] = {0, 0.5, 0.5, 0.5},
    ['hk'] = {0, 0, 0.5, 0.5},
    ['jl'] = {0.5, 0.5, 0.5, 0.5},
    ['kl'] = {0.5, 0, 0.5, 0.5},
    ['hl'] = {0, 0, 1, 1},
}
local wasPressed = {false, false, false, false}
local pressed = {false, false, false, false}

local function resizeWindow()
    for i = 1, #pressed do
        if pressed[i] then
            return
        end
    end

    local win = hs.window.focusedWindow()
    if win ~= nil then
        local keys = ''
        for i = 1, #wasPressed do
            if wasPressed[i] then
                keys = keys .. arrowKeys[i]
                wasPressed[i] = false
            end
        end
        local rect = rectMap[keys]
        if rect ~= nil then
            win:move(rect)
        elseif keys == 'jk' then
            win:centerOnScreen()
        end
    end
    prefix.exit()
end

for i = 1, #arrowKeys do
    local pressedFn = function()
        wasPressed[i] = true
        pressed[i] = true
    end
    local releasedFn = function()
        pressed[i] = false
        resizeWindow()
    end
    prefix.bindMultiple('', arrowKeys[i], pressedFn, releasedFn, nil)
end

-- prefix + ctrl-h -> left one third
-- prefix + ctrl-j -> left two thirds
-- prefix + ctrl-k -> right two thirds
-- prefix + ctrl-l -> right one third
local rectMapCtrl = {
    ['h'] = {0, 0, 1/3, 1},
    ['j'] = {0, 0, 2/3, 1},
    ['k'] = {1/3, 0, 2/3, 1},
    ['l'] = {2/3, 0, 1/3, 1},
}

for k, v in pairs(rectMapCtrl) do
    local fn = function()
        win = hs.window.focusedWindow()
        if win ~= nil then
            win:move(v)
        end
    end
    prefix.bind('ctrl', k, fn)
end

-- prefix + shift-hjkl -> move window
local DX = {-1, 0, 0, 1}
local DY = {0, 1, -1, 0}
local DELTA = 20

for i = 1, 4 do
    local moveWin = function()
        local win = hs.window.focusedWindow()
        if win ~= nil then
            local p = win:topLeft()
            p.x = p.x + DX[i] * DELTA
            p.y = p.y + DY[i] * DELTA
            win:setTopLeft(p)
        end
    end
    local pressedFn = function()
        prefix.cancelTimeout()
        moveWin()
    end
    prefix.bindMultiple('shift', arrowKeys[i], pressedFn, nil, moveWin)
end

