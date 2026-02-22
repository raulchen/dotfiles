-- Custom Linemode: Size | YYYY-MM-DD HH:MM
function Linemode:custom_linemode()
	local time = math.floor(self._file.cha.mtime or 0)
	local time_str = ""
	if time > 0 then
		time_str = os.date("%Y-%m-%d %H:%M", time)
	end

	local size = self._file:size()
	local size_str = ""
	if size and not self._file.cha.is_dir then
		size_str = ya.readable_size(size) .. " | "
	end

	return string.format("%s%s", size_str, time_str)
end

-- Status Bar (Right side): [Size] | [Mtime] | [Owner:Group] 
Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ui.Line {}
	end

	local time = math.floor(h.cha.mtime or 0)
	local time_str = time > 0 and os.date("%Y-%m-%d %H:%M", time) or ""
	
	local size = h:size()
	local size_str = (size and not h.cha.is_dir) and ya.readable_size(size) or ""

	local lines = {}

	if size_str ~= "" then
		table.insert(lines, ui.Span(size_str):fg("yellow"))
		table.insert(lines, ui.Span(" | "))
	end

	if time_str ~= "" then
		table.insert(lines, ui.Span(time_str):fg("blue"))
		table.insert(lines, ui.Span(" | "))
	end

	table.insert(lines, ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"))
	table.insert(lines, ui.Span(":"))
	table.insert(lines, ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"))
	table.insert(lines, ui.Span(" "))

	return ui.Line(lines)
end, 500, Status.RIGHT)
