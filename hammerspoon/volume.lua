local module = {}

local function increment(delta)
    local dev = audio.defaultOutputDevice()
    if dev == nil then
        return false
    end

    local volume = dev:volume()
    volume = math.max(math.min(volume + delta, 100), 0)
    if dev:setVolume(volume) then
        return volume
    end

    return false
end

module.up = hs.fnutils.partial(increment, 5)
module.down = hs.fnutils.partial(increment, -5)

return module
