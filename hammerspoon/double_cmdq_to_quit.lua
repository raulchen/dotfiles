-- Press Cmd+Q twice to quit

local quitModal = hs.hotkey.modal.new('cmd','q')

-- For special apps that have multiple menu items starting with "Quit",
-- match the full name
local WHITELIST = {}
WHITELIST["com.tencent.QQMusicMac"] = "退出QQ音乐"

function quitModal:entered()
    hs.alert.show("Press Cmd+Q again to quit", 1)
    hs.timer.doAfter(1, function() quitModal:exit() end)
end

local function doQuit()
    local app = hs.application.frontmostApplication()
    local bundleID = app:bundleID()
    local menu =  "(Quit|退出).*"
    local regex = true
    if WHITELIST[bundleID] then
        menu = WHITELIST[bundleID]
        regex = false
    end
    app:selectMenuItem(menu, regex)
    quitModal:exit()
end

quitModal:bind('cmd', 'q', doQuit)

quitModal:bind('', 'escape', function() quitModal:exit() end)
