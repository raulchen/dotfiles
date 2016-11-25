local prefix = require("prefix")
local utils = require("utils")

hs.grid.setGrid('6x4', nil, nil)
hs.grid.setMargins({0, 0})
prefix.bind('', 'g', function() hs.grid.show() end)

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
