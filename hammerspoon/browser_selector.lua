if hs.urlevent.getDefaultHandler('http') ~= 'org.hammerspoon.Hammerspoon' then
    return
end

local browsers = {
    Safari = { bundleID = "com.apple.Safari" },
    Arc = { bundleID = "company.thebrowser.Browser" },
}

local text_style = {
    font = { size = 22 },
    color = hs.drawing.color.definedCollections.hammerspoon.grey,
    paragraphSpacingBefore = 2,
}

for name, browser in pairs(browsers) do
    browser.name = name
    browser.text = hs.styledtext.new(name, text_style)
    browser.image = hs.image.imageFromAppBundle(browser.bundleID)
    browser.lastSelectedTime = 0
end

---@diagnostic disable-next-line: unused-local
local function selectBrowser(schema, host, params, fullUrl, senderPID)
    if not fullUrl then
        return
    end
    local choices = {}
    for _, browser in pairs(browsers) do
        table.insert(choices, browser)
    end
    -- Sort the choices by last selected time
    table.sort(choices, function(a, b)
        return a.lastSelectedTime >= b.lastSelectedTime
    end)

    hs.chooser.new(function(choice)
        if choice then
            browsers[choice.name].lastSelectedTime = hs.timer.secondsSinceEpoch()
            hs.urlevent.openURLWithBundle(fullUrl, choice.bundleID)
        end
    end)
        :choices(choices)
        :rows(#choices)
        :width(15)
        :show()
end

hs.urlevent.httpCallback = selectBrowser
