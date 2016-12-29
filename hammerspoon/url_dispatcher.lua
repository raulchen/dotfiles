-- Choose a browser to open URL with

if hs.urlevent.getDefaultHandler('http') ~= 'org.hammerspoon.hammerspoon' then
    return
end

local url = nil

local chooser = hs.chooser.new(function(choice)
    if choice == nil then
        return
    end
    hs.urlevent.openURLWithBundle(url, choice['bundle'])
end)

local choices = {
    {
        ['text'] = 'Chrome',
        ['bundle'] = 'com.google.chrome',
    },
    {
        ['text'] = 'Safari',
        ['bundle'] = 'com.apple.safari',
    }
}

chooser:choices(choices)

chooser:rows(#choices)

hs.urlevent.httpCallback = function(schema, host, params, fullURL)
    url = fullURL
    chooser:show()
end

