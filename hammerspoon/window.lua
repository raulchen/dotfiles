local prefix = require("prefix")

hs.window.animationDuration = 0

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
