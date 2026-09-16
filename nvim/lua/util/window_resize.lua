local api = vim.api
local M = {}

-- Measure actual split rectangles, including status lines and the gaps
-- between siblings. Floating windows are absent from winlayout().
local function measure(layout)
  if layout[1] == "leaf" then
    local win = layout[2]
    local info = vim.fn.getwininfo(win)[1]
    return {
      win = win,
      x = info.wincol,
      y = info.winrow,
      width = info.width,
      height = api.nvim_win_get_height(win) + info.status_height,
      padding = info.status_height,
      fixed_width = vim.wo[win].winfixwidth,
      fixed_height = vim.wo[win].winfixheight,
    }
  end
  local node = { axis = layout[1] == "row" and "width" or "height", children = {} }
  for i, child in ipairs(layout[2]) do
    node.children[i] = measure(child)
  end
  node.x, node.y = node.children[1].x, node.children[1].y
  for _, axis in ipairs({ "width", "height" }) do
    local position = axis == "width" and "x" or "y"
    local size, fixed = 0, node.axis == axis
    for _, child in ipairs(node.children) do
      size = math.max(size, child[position] + child[axis] - node[position])
      if node.axis == axis then
        fixed = fixed and child["fixed_" .. axis]
      else
        fixed = fixed or child["fixed_" .. axis]
      end
    end
    node[axis], node["fixed_" .. axis] = size, fixed
  end
  return node
end

local function restore(old, current, axis, size)
  if current.win then
    local target = math.max(1, size - (axis == "height" and current.padding or 0))
    if axis == "width" then
      api.nvim_win_set_width(current.win, target)
    else
      api.nvim_win_set_height(current.win, target)
    end
    return
  end
  if current.axis ~= axis then
    for i, child in ipairs(current.children) do
      restore(old.children[i], child, axis, size)
    end
    return
  end

  local gaps, fixed, weight = current[axis], 0, 0
  for i, child in ipairs(current.children) do
    gaps = gaps - child[axis]
    local previous = old.children[i][axis]
    if child["fixed_" .. axis] then
      fixed = fixed + previous
    else
      weight = weight + previous
    end
  end
  local available = math.max(0, size - gaps - fixed)
  local cumulative, allocated = 0, 0
  for i, child in ipairs(current.children) do
    local target = old.children[i][axis]
    if not child["fixed_" .. axis] then
      cumulative = cumulative + target
      local boundary = math.floor(available * cumulative / math.max(1, weight) + 0.5)
      target, allocated = boundary - allocated, boundary
    end
    restore(old.children[i], child, axis, target)
  end
end

function M.setup(group)
  local state = {
    columns = vim.o.columns,
    lines = vim.o.lines,
    saved = {}, -- Desired proportions, retained across terminal resizes.
    observed = {}, -- Last applied geometry, used to detect manual changes.
    resizing = false,
    pending = false,
  }

  local function snapshot()
    local tabs = {}
    for _, tab in ipairs(api.nvim_list_tabpages()) do
      local layout = vim.fn.winlayout(api.nvim_tabpage_get_number(tab))
      tabs[tab] = { layout = layout, tree = measure(layout) }
    end
    return tabs
  end

  local function remember()
    -- Do not overwrite the old proportions with Neovim's native resize result.
    if state.resizing or vim.fn.getcmdwintype() ~= ""
      or vim.o.columns ~= state.columns or vim.o.lines ~= state.lines then
      return
    end
    local tabs = snapshot()
    for tab, saved in pairs(tabs) do
      if not vim.deep_equal(saved, state.observed[tab]) then
        state.saved[tab] = saved
      end
    end
    for tab in pairs(state.saved) do
      if not tabs[tab] then state.saved[tab] = nil end
    end
    state.observed = tabs
  end

  local function schedule_snapshot()
    if state.pending or state.resizing then return end
    state.pending = true
    vim.schedule(function()
      state.pending = false
      remember()
    end)
  end

  local function resize()
    -- Tab switching is forbidden in the command-line window. CmdwinLeave
    -- retries after it closes, using the proportions saved before it opened.
    if vim.fn.getcmdwintype() ~= "" then return end
    local current_win = api.nvim_get_current_win()
    state.resizing = true
    local ok, err = pcall(function()
      for _, tab in ipairs(api.nvim_list_tabpages()) do
        -- Inactive tabs need their native layout updated before measuring.
        vim.cmd("noautocmd tabnext " .. api.nvim_tabpage_get_number(tab))
        local saved = state.saved[tab]
        local layout = vim.fn.winlayout()
        if saved and vim.deep_equal(saved.layout, layout) then
          local current = measure(layout)
          -- Like winrestcmd(), apply twice: resizing an outer split can
          -- change an inner split that was already restored in this pass.
          for _ = 1, 2 do
            restore(saved.tree, current, "width", current.width)
            restore(saved.tree, current, "height", current.height)
          end
        else
          -- A split may have opened/closed before its scheduled snapshot ran.
          state.saved[tab] = { layout = layout, tree = measure(layout) }
        end
      end
    end)
    -- Restore focus and clear the guard even if a resize fails.
    if api.nvim_win_is_valid(current_win) then
      vim.cmd("noautocmd call win_gotoid(" .. current_win .. ")")
    end
    state.resizing = false
    state.columns, state.lines = vim.o.columns, vim.o.lines
    -- Keep the original ratios through rounding and temporary size limits.
    state.observed = snapshot()
    if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
  end

  remember()
  api.nvim_create_autocmd({ "VimEnter", "WinResized", "WinNew", "WinClosed", "TabEnter", "TabClosed" }, {
    desc = "Remember split proportions after layout changes settle",
    group = group,
    callback = schedule_snapshot,
  })

  api.nvim_create_autocmd("VimResized", {
    desc = "Preserve split proportions when vim is resized",
    group = group,
    callback = resize,
  })
  api.nvim_create_autocmd("CmdwinLeave", {
    desc = "Apply terminal resizing deferred by the command-line window",
    group = group,
    callback = function()
      vim.schedule(function()
        if vim.o.columns ~= state.columns or vim.o.lines ~= state.lines then
          resize()
        end
      end)
    end,
  })
end

return M
