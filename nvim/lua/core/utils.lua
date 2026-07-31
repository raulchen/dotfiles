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

--- A bordered one-line hint along the bottom centre of the editor, for modes
--- that read keys directly and so can't rely on the message area.
---@param text string
---@param hl? string highlight for the text and border (default: ModeMsg)
---@return fun() close
M.hint_float = function(text, hl)
  hl = hl or "ModeMsg"
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

  -- Anchored bottom-right, so `col` is the right edge; put that half a width
  -- past centre and the box lands centred.
  local ok, win = pcall(vim.api.nvim_open_win, buf, false, {
    relative = 'editor',
    anchor = 'SE',
    row = vim.o.lines - vim.o.cmdheight - 1,
    col = math.floor((vim.o.columns + #text) / 2),
    width = #text,
    height = 1,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    zindex = 250,
    noautocmd = true,
  })
  if not ok then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    return function() end
  end
  vim.wo[win].winhighlight = ('Normal:%s,FloatBorder:%s'):format(hl, hl)

  return function()
    pcall(vim.api.nvim_win_close, win, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

M.yank_to_register = function(value)
  local reg = vim.v.register == '"' and '+' or vim.v.register
  vim.fn.setreg(reg, value)
  vim.notify(string.format('Copied to "%s: %s', reg, value), vim.log.levels.INFO)
end

return M
