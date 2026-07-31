-- Ask where to put something: label each window in place, and let a chord make
-- a new split, tab, or float instead.

local M = {}

-- Left-hand keys label the windows; the right hand acts. No char appears in
-- both sets, so a label can never shadow an action.
local PICK_CHARS = "asdfgqwerzxcv"
local PICK_HINT = " Pick window  HJKL: split  T: tab  ;: float  <Esc>: cancel "

-- Splits placed relative to the window we're in, ignoring splitright/splitbelow.
local SPLITS = {
  h = "leftabove vsplit",
  j = "belowright split",
  k = "aboveleft split",
  l = "rightbelow vsplit",
}

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
end

-- Draw `text` centered in `win`, in highlight group `hl`. Returns a closer.
local function label_overlay(win, text, hl)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

  local ok, float = pcall(vim.api.nvim_open_win, buf, false, {
    relative = "win",
    win = win,
    row = math.max(0, math.floor(vim.api.nvim_win_get_height(win) / 2) - 1),
    col = math.max(0, math.floor((vim.api.nvim_win_get_width(win) - #text) / 2)),
    width = #text,
    height = 1,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 250,
    noautocmd = true,
  })
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
--- split or tab (created on the spot), or a float. Only <Esc> cancels;
--- unrecognised keys are ignored.
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
    table.insert(closers, label_overlay(win, " " .. char:upper() .. " ", "WindowPickerLabel"))
  end
  table.insert(closers, require("core.utils").hint_float(PICK_HINT, "WindowPickerLabel"))

  vim.cmd("redraw")

  -- Read until a key means something. What it means is captured as a thunk
  -- rather than run here, so a split lands in the layout the labels described
  -- instead of shifting windows out from under them.
  local resolve
  while true do
    local ok, char = pcall(vim.fn.getcharstr)
    -- Bail on a failed read too, or an interrupt would spin here forever.
    if not ok or char == "" or char == "\27" then
      break
    end
    -- Labels and actions are both shown uppercase, so accept either case.
    local key = char:lower()
    local made = function()
      return { win = vim.api.nvim_get_current_win(), created = true }
    end
    if by_label[key] then
      local win = by_label[key]
      resolve = function() return { win = win } end
    elseif SPLITS[key] then
      local cmd = SPLITS[key]
      resolve = function()
        vim.cmd(cmd)
        return made()
      end
    elseif key == "t" then
      resolve = function()
        vim.cmd("tabnew")
        return made()
      end
    elseif key == ";" then
      resolve = function() return { float = true } end
    end
    if resolve then break end
  end

  for _, close in ipairs(closers) do
    close()
  end
  vim.cmd("redraw")

  if not resolve then
    return nil
  end
  return resolve()
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
