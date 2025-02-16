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

return M
