-- Ask where to put something: label each window in place, and let a chord make
-- a new split, tab, or float instead.

local M = {}

-- Home row, left to right.
local PICK_CHARS = "asdfghjkl;"
local PICK_HINT = " Pick window  C-v: vsplit  C-x: hsplit  C-t: tab  C-f: float  q/<Esc>: cancel "

-- Windows that can host a buffer: real splits in the current tabpage, skipping
-- floats (pickers, notifications) and winfixbuf windows (file trees, terminals).
-- The window we're in is skipped too, unless the caller wants it as a target.
local function pickable_windows(include_current)
  local skip = not include_current and vim.api.nvim_get_current_win() or nil
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= skip and vim.api.nvim_win_get_config(win).relative == "" and not vim.wo[win].winfixbuf then
      table.insert(wins, win)
    end
  end
  -- Sort by window number so labels follow the layout (top-left to bottom-right)
  -- instead of creation order.
  table.sort(wins, function(a, b)
    return vim.api.nvim_win_get_number(a) < vim.api.nvim_win_get_number(b)
  end)
  return wins
end

-- Named so a colorscheme can restyle them. `default` never clobbers an existing
-- definition, and these are re-applied per pick because :colorscheme clears them.
local function ensure_highlights()
  -- Letter and border only, no fill: take Title's colour (a message-family group,
  -- so it carries a foreground and no background in any theme) and embolden it.
  local title = vim.api.nvim_get_hl(0, { name = "Title", link = false })
  vim.api.nvim_set_hl(0, "WindowPickerLabel", { fg = title.fg, bold = true, default = true })
  vim.api.nvim_set_hl(0, "WindowPickerHint", { link = "ModeMsg", default = true })
end

-- Draw `text` centered in `win` (or, for a nil `win`, at the bottom right of
-- the editor), in highlight group `hl`. Returns a closer for the overlay.
local function overlay(win, text, hl)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

  local config
  if win then
    config = {
      relative = "win",
      win = win,
      row = math.max(0, math.floor(vim.api.nvim_win_get_height(win) / 2) - 1),
      col = math.max(0, math.floor((vim.api.nvim_win_get_width(win) - #text) / 2)),
    }
  else
    config = {
      relative = "editor",
      anchor = "SE",
      row = vim.o.lines - vim.o.cmdheight - 1,
      col = vim.o.columns,
    }
  end
  config = vim.tbl_extend("error", config, {
    width = #text,
    height = 1,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 250,
    noautocmd = true,
  })

  local ok, float = pcall(vim.api.nvim_open_win, buf, false, config)
  if not ok then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    return function() end
  end
  vim.wo[float].winhighlight = ("Normal:%s,FloatBorder:%s"):format(hl, hl)
  return function()
    pcall(vim.api.nvim_win_close, float, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

---@class core.window_picker.Target
---@field win? integer window to open in (already created for split/tab picks)
---@field float? boolean open in a floating window instead
---@field created? boolean the pick made this window, so nothing in it predates us

--- Ask where to open something: an existing window (labelled in place), a new
--- split or tab (created on the spot), or a float.
---@param opts? { include_current?: boolean } also label the window we're in,
---   for operations that can sensibly target it (default: false)
---@return core.window_picker.Target|nil target nil when cancelled
M.pick = function(opts)
  ensure_highlights()
  local wins = pickable_windows(opts and opts.include_current)
  local by_label = {}
  local closers = {}
  for i, win in ipairs(wins) do
    local char = PICK_CHARS:sub(i, i)
    if char == "" then break end -- more windows than labels; the rest go unlabelled
    by_label[char] = win
    table.insert(closers, overlay(win, " " .. char:upper() .. " ", "WindowPickerLabel"))
  end
  table.insert(closers, overlay(nil, PICK_HINT, "WindowPickerHint"))

  vim.cmd("redraw")
  local ok, char = pcall(vim.fn.getcharstr)
  for _, close in ipairs(closers) do
    close()
  end
  vim.cmd("redraw")

  if not ok or char == "" or char == "\27" or char == "q" then
    return nil
  end
  if by_label[char:lower()] then
    return { win = by_label[char:lower()] }
  end
  if char == "\22" then -- <C-v>
    vim.cmd("vsplit")
  elseif char == "\24" then -- <C-x>
    vim.cmd("split")
  elseif char == "\20" then -- <C-t>
    vim.cmd("tabnew")
  elseif char == "\6" then -- <C-f>
    return { float = true }
  else
    return nil
  end
  return { win = vim.api.nvim_get_current_win(), created = true }
end

local function goto_line(win, line, col)
  if line then
    pcall(vim.api.nvim_win_set_cursor, win, { line, col or 0 })
    vim.api.nvim_win_call(win, function() vim.cmd("normal! zz") end)
  end
end

--- Show `buf` in a target returned by `M.pick`, optionally jumping to `line`.
--- A nil target (cancelled pick) is a no-op.
---@param target core.window_picker.Target|nil
---@param buf integer
---@param line? integer
---@param col? integer 0-based
---@return integer|nil win the window now showing `buf`
---@return integer|nil displaced the buffer pushed out of a borrowed window, if any
M.show_buf = function(target, buf, line, col)
  if not target then
    return
  end

  if target.float then
    local name = vim.api.nvim_buf_get_name(buf)
    local float = Snacks.win({
      buf = buf,
      position = "float",
      border = "rounded",
      title = name ~= "" and (" " .. vim.fn.fnamemodify(name, ":t") .. " ") or nil,
      enter = true,
      -- No backdrop: it is a second window with its own lifetime, which leaks
      -- when a caller closes the float directly.
      backdrop = false,
      minimal = false,
      fixbuf = false, -- allow jumping to other files from within the float
      width = 0.95,
      height = 0.95,
      on_win = function(self) goto_line(self.win, line, col) end,
    })
    return float.win
  end

  local win = target.win
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  local prev = not target.created and vim.api.nvim_win_get_buf(win) or nil
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_set_current_win(win)
  goto_line(win, line, col)
  return win, prev
end

--- Open `path` in a target returned by `M.pick`, optionally jumping to `line`.
--- A nil target (cancelled pick) is a no-op.
---@param target core.window_picker.Target|nil
---@param path string
---@param line? integer
---@param col? integer 0-based
M.open_file = function(target, path, line, col)
  if not target then
    return
  end

  if target.float then
    -- Load the buffer ourselves: Snacks.win's own `file` handling marks the
    -- buffer readonly and nomodifiable.
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    M.show_buf(target, buf, line, col)
    return
  end

  if target.win and vim.api.nvim_win_is_valid(target.win) then
    vim.api.nvim_set_current_win(target.win)
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  goto_line(0, line, col)
end

return M
