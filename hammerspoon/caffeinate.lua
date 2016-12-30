-- To replace the Caffeinate app

local prefix = require('prefix')

local menu = nil

local function toggle()
    local enabled = hs.caffeinate.toggle('system')
    if enabled then
        menu = hs.menubar.new():setTitle('☕')
    else
        menu:delete()
    end
end

prefix.bind('', 'c', toggle)
prefix.bind('', 's', hs.caffeinate.startScreensaver)
