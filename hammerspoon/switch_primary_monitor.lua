local prefix = require('prefix')

local function switchPrimaryMonitor()
  hs.screen.primaryScreen():next():setPrimary()
end

prefix.bind('', 'm', switchPrimaryMonitor)
