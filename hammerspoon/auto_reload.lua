-- Auto reload Hammerspoon config

utils = require("utils")

function reloadConfig()
  configFileWatcher:stop()
  configFileWatcher = nil
  hs.reload()
end

configFileWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig)
configFileWatcher:start()
utils.tempNotify(3, hs.notify.new({
    title = "Hammerspoon",
    subTitle = "Config reloaded",
}))
