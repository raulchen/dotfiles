----------------
-- Switch
----------------

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
