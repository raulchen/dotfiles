require("double_cmdq_to_quit")
require("keymaps")
require("window")
require("modifier_key_monitor").start()
require("switch_primary_monitor")
---@diagnostic disable-next-line: param-type-mismatch
pcall(hs.fnutils.partial(require, "local"))

require("utils").tempNotify(3, hs.notify.new({
    title = "Config reloaded",
}))

if hs.fs.attributes("~/.hammerspoon/Spoons/EmmyLua.spoon/annotations", "size") == nil then
    hs.loadSpoon("EmmyLua")
end
