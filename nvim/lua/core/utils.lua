local M = {}

local _last_executed_fn = nil

_G.repeat_last_fn = function()
  if _last_executed_fn ~= nil then
    _last_executed_fn()
  end
end

-- Make the input function dot-repeatable.
-- Reference: https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
M.dot_repeatable_fn = function(input_fn)
  local function wrapper_fn()
    _last_executed_fn = input_fn
    vim.go.operatorfunc = "v:lua.repeat_last_fn"
    return "g@l"
  end
  return wrapper_fn
end

-- Make the given lazy.nvim-style keymap options dot-repeatable
M.dot_repeatable_keymap = function(keymap_opts)
  assert(type(keymap_opts[2]) == "function", "The rhs must be a function")
  keymap_opts[2] = M.dot_repeatable_fn(keymap_opts[2])
  keymap_opts.expr = true
  if keymap_opts.desc ~= nil then
    keymap_opts.desc = keymap_opts.desc .. " (repeatable)"
  end
  return keymap_opts
end

M.yank_to_register = function(value)
  local reg = vim.v.register == '"' and '+' or vim.v.register
  vim.fn.setreg(reg, value)
  vim.notify(string.format('Copied to "%s: %s', reg, value), vim.log.levels.INFO)
end

-- Window picker -------------------------------------------------------------

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

-- Draw `text` centered in `win` (or, for a nil `win`, at the bottom right of
-- the editor). Returns a closer for the overlay.
local function overlay(win, text)
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
  vim.wo[float].winhighlight = "Normal:ModeMsg,FloatBorder:ModeMsg"
  return function()
    pcall(vim.api.nvim_win_close, float, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

---@class core.utils.PickTarget
---@field win? integer window to open in (already created for split/tab picks)
---@field float? boolean open in a floating window instead
---@field created? boolean the pick made this window, so nothing in it predates
---   us and it is ours to close

--- Ask where to open something: an existing window (labelled in place), a new
--- split or tab (created on the spot), or a float.
---@param opts? { include_current?: boolean } also label the window we're in,
---   for operations that can sensibly target it (default: false)
---@return core.utils.PickTarget|nil target nil when cancelled
M.pick_window = function(opts)
  local wins = pickable_windows(opts and opts.include_current)
  local by_label = {}
  local closers = {}
  for i, win in ipairs(wins) do
    local char = PICK_CHARS:sub(i, i)
    if char == "" then break end -- more windows than labels; the rest go unlabelled
    by_label[char] = win
    table.insert(closers, overlay(win, " " .. char:upper() .. " "))
  end
  table.insert(closers, overlay(nil, PICK_HINT))

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

local function goto_line(win, line)
  if line then
    pcall(vim.api.nvim_win_set_cursor, win, { line, 0 })
    vim.api.nvim_win_call(win, function() vim.cmd("normal! zz") end)
  end
end

--- Show `buf` in a target returned by `M.pick_window`, optionally jumping to
--- `line`. A nil target (cancelled pick) is a no-op.
---@param target core.utils.PickTarget|nil
---@param buf integer
---@param line? integer
---@return integer|nil win the window now showing `buf`
---@return fun()|nil dismiss undo the placement: close a window the pick created,
---   or hand a borrowed one back to the buffer it was showing
M.show_buf_in_target = function(target, buf, line)
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
      on_win = function(self) goto_line(self.win, line) end,
    })
    return float.win, function() float:close() end
  end

  local win = target.win
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  local prev = not target.created and vim.api.nvim_win_get_buf(win) or nil
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_set_current_win(win)
  goto_line(win, line)

  return win, function()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    if prev and vim.api.nvim_buf_is_valid(prev) then
      vim.api.nvim_win_set_buf(win, prev)
    else
      -- Ours to close, or borrowed from a buffer that is gone. pcall since it
      -- may be a tabpage's last window.
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

--- Open `path` in a target returned by `M.pick_window`, optionally jumping to
--- `line`. A nil target (cancelled pick) is a no-op.
---@param target core.utils.PickTarget|nil
---@param path string
---@param line? integer
M.open_file_in_target = function(target, path, line)
  if not target then
    return
  end

  if target.float then
    -- Load the buffer ourselves: Snacks.win's own `file` handling marks the
    -- buffer readonly and nomodifiable.
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    M.show_buf_in_target(target, buf, line)
    return
  end

  if target.win and vim.api.nvim_win_is_valid(target.win) then
    vim.api.nvim_set_current_win(target.win)
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  goto_line(0, line)
end

return M
