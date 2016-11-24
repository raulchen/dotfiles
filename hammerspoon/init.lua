inspect = hs.inspect.inspect
utils = require("utils")
prefix = require("prefix")

require("auto_reload")
require("double_cmdq_to_quit")
require("keymaps")
require("mouse_key")
require("window")
require("caffeinate")
require("local")

utils.tempNotify(3, hs.notify.new({
    title = "Hammerspoon",
    subTitle = "Config reloaded",
}))
