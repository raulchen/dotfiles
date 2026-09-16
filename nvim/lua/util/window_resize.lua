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
      min_width = 1,
      min_height = 1 + info.status_height,
      fixed_width = vim.wo[win].winfixwidth,
      fixed_height = vim.wo[win].winfixheight,
    }
  end
  local node = { layout = layout, axis = layout[1] == "row" and "width" or "height", children = {} }
  for i, child in ipairs(layout[2]) do
    node.children[i] = measure(child)
  end
  node.x, node.y = node.children[1].x, node.children[1].y
  for _, axis in ipairs({ "width", "height" }) do
    local position = axis == "width" and "x" or "y"
    local size, total, minimum, fixed = 0, 0, 0, node.axis == axis
    for _, child in ipairs(node.children) do
      size = math.max(size, child[position] + child[axis] - node[position])
      total = total + child[axis]
      if node.axis == axis then
        minimum = minimum + child["min_" .. axis]
        fixed = fixed and child["fixed_" .. axis]
      else
        minimum = math.max(minimum, child["min_" .. axis])
        fixed = fixed or child["fixed_" .. axis]
      end
    end
    node["min_" .. axis] = minimum + (node.axis == axis and size - total or 0)
    node[axis], node["fixed_" .. axis] = size, fixed
  end
  return node
end

local function restore(old, current, axis, size, keep_fixed)
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
      restore(old.children[i], child, axis, size, keep_fixed)
    end
    return
  end

  local gaps, fixed, weight, minimum, targets = current[axis], 0, 0, 0, {}
  for i, child in ipairs(current.children) do
    gaps = gaps - child[axis]
    local previous = keep_fixed and child["fixed_" .. axis] and child[axis] or old.children[i][axis]
    targets[i] = previous
    if child["fixed_" .. axis] then
      fixed = fixed + previous
    else
      weight = weight + previous
      minimum = minimum + child["min_" .. axis]
    end
  end
  -- If the fixed sizes cannot fill this frame, use Neovim's allocation as
  -- the weights. Descendants still retain their own saved proportions.
  local constrained = weight == 0 or fixed + minimum > size - gaps
  if constrained then
    fixed, weight, minimum = 0, 0, 0
    for i, child in ipairs(current.children) do
      targets[i] = child[axis]
      weight = weight + child[axis]
      minimum = minimum + child["min_" .. axis]
    end
  end
  local available = math.max(0, size - gaps - fixed)
  local cumulative, allocated = 0, 0
  for i, child in ipairs(current.children) do
    local target = targets[i]
    if constrained or not child["fixed_" .. axis] then
      cumulative = cumulative + target
      minimum = minimum - child["min_" .. axis]
      local boundary = math.floor(available * cumulative / math.max(1, weight) + 0.5)
      -- Leave room for every remaining child, even when a ratio rounds to zero.
      boundary = math.max(allocated + child["min_" .. axis], math.min(available - minimum, boundary))
      target, allocated = boundary - allocated, boundary
    end
    restore(old.children[i], child, axis, target, keep_fixed)
  end
end

local function find_frame(tree, layout)
  if vim.deep_equal(tree.layout, layout) then return tree end
  for _, child in ipairs(tree.children or {}) do
    local found = find_frame(child, layout)
    if found then return found end
  end
end

-- Keep Neovim's allocation between siblings. Only restore proportions inside
-- surviving frames whose available space changed, including after open/close.
local function restore_inner(old, current, axis)
  if current.win then return end
  local previous = find_frame(old, current.layout)
  if previous and current.axis == axis and previous[axis] ~= current[axis] then
    -- Fixed windows keep Neovim's chosen sizes, which may already be clamped.
    restore(previous, current, axis, current[axis], true)
  else
    for _, child in ipairs(current.children) do
      restore_inner(old, child, axis)
    end
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
    state.resizing = true
    local ok, err = pcall(function()
      for tab, current in pairs(tabs) do
        local previous = state.observed[tab]
        if previous and not vim.deep_equal(previous, current) then
          for _ = 1, 2 do
            restore_inner(previous.tree, current.tree, "width")
            restore_inner(previous.tree, current.tree, "height")
          end
        end
      end
    end)
    state.resizing = false
    tabs = snapshot()
    for tab, saved in pairs(tabs) do
      if not vim.deep_equal(saved, state.observed[tab]) then
        state.saved[tab] = saved
      end
    end
    for tab in pairs(state.saved) do
      if not tabs[tab] then state.saved[tab] = nil end
    end
    state.observed = tabs
    if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
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
    desc = "Preserve inner split proportions after layout changes settle",
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
