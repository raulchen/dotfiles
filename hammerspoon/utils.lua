local module = {}

function module.tempNotify(timeout, notif)
    notif:send()
    hs.timer.doAfter(timeout, function() notif:withdraw() end)
end

function module.splitStr(str, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(str, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

return module
