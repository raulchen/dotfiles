require("leader_key")
require("double_cmdq_to_quit")
require("window")
require("modifier_key_monitor").start()
require("vim_mode")
require("browser_selector")
---@diagnostic disable-next-line: param-type-mismatch
pcall(hs.fnutils.partial(require, "local"))

require("utils").temp_notify(3, hs.notify.new({
    title = "Config reloaded",
}))

if hs.fs.attributes("~/.hammerspoon/Spoons/EmmyLua.spoon/annotations", "size") == nil then
    hs.loadSpoon("EmmyLua")
end
