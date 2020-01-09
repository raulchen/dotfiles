inspect = hs.inspect.inspect
prefix = require("prefix")
utils = require("utils")

require("double_cmdq_to_quit")
require("keymaps")
require("window")
require("caffeinate")
require("url_dispatcher")
require("smart_modifier_keys")
pcall(hs.fnutils.partial(require, "local"))

utils.tempNotify(3, hs.notify.new({
    title = "Config reloaded",
}))
