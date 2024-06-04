inspect = hs.inspect.inspect
prefix = require("prefix")
utils = require("utils")

require("double_cmdq_to_quit")
require("keymaps")
require("window")
require("caffeinate")
require("url_dispatcher")
require("smart_modifier_keys")
require("switch_primary_monitor")
pcall(hs.fnutils.partial(require, "local"))

utils.tempNotify(3, hs.notify.new({
    title = "Config reloaded",
}))

if hs.fs.attributes("~/.hammerspoon/Spoons/EmmyLua.spoon/annotations", "size") == nil then
    hs.loadSpoon("EmmyLua")
end
