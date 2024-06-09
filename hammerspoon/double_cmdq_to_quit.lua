-- Press Cmd+Q twice to quit

local quit_modal = hs.hotkey.modal.new('cmd', 'q')
local label = require("labels").new("Press Cmd+Q again to quit", "center")

function quit_modal:entered()
    label:show(1)
    hs.timer.doAfter(1, function() quit_modal:exit() end)
end

local function do_quit()
    label:hide()
    local app = hs.application.frontmostApplication()
    app:kill()
end

quit_modal:bind('cmd', 'q', do_quit)

quit_modal:bind('', 'escape', function() quit_modal:exit() end)
