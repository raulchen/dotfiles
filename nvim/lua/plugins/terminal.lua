local function toggle_terminal(count)
  local ergoterm = require("ergoterm")

  -- Check if current buffer is already a terminal
  local current_term = ergoterm.identify()
  if current_term then
    -- Hide the current terminal
    current_term:close()
    return
  end

  -- Otherwise, open the terminal named $count
  count = count or (vim.v.count > 0 and vim.v.count) or 1
  local term_name = tostring(count)
  local term = ergoterm.get_by_name(term_name)

  if term then
    -- Terminal exists, focus it
    if term:is_active() then
      term:focus()
    else
      -- Terminal was cleaned up, restart it
      term:start()
      term:focus()
    end
  else
    -- Create new terminal with the given name
    term = ergoterm:new({
      name = term_name,
      layout = "below",
      title = "123",
    })
    term:start()
  end
end

local ergoterm_keys = {
  { "<c-/>", toggle_terminal, desc = "Toggle terminal", mode = { "n", "t" } },
  { "<c-_>", toggle_terminal, desc = "Toggle terminal", mode = { "n", "t" } },
  { "<leader>ft", "<cmd>TermSelect<cr>", desc = "Pick a terminal" },
}

-- Map <A-1> to <A-9> to toggle terminals 1 to 9
for i = 1, 9 do
  table.insert(ergoterm_keys, {
    "<A-" .. i .. ">",
    function() toggle_terminal(i) end,
    desc = "Toggle terminal " .. i,
    mode = { "n" },
    remap = false,
  })
  table.insert(ergoterm_keys, {
    "<A-" .. i .. ">",
    function() toggle_terminal(i) end,
    desc = "Toggle terminal " .. i,
    mode = { "t" },
    remap = false,
  })
end

local ergoterm_opts = {
  terminal_defaults = {
    float_winblend = 0,
    size = {
      right = "40%",
      below = "40%",
    },
    -- Set winbar to show terminal name and current directory (skip floating terminals)
    on_open = function(term)
      -- Don't set winbar for floating terminals
      if term._state.layout == "float" then
        return
      end
      vim.schedule(function()
        local win = vim.fn.bufwinid(term._state.bufnr)
        if win ~= -1 then
          local name = term.name or "terminal"
          local dir = term._state.dir or vim.fn.getcwd()
          local home = vim.fn.expand("~")
          if vim.startswith(dir, home) then
            dir = "~" .. dir:sub(#home + 1)
          end
          vim.api.nvim_set_option_value(
            "winbar",
            string.format(" %s  %s", name, dir),
            { scope = "local", win = win }
          )
        end
      end)
    end,
  },
}

return {
  "waiting-for-dev/ergoterm.nvim",
  keys = ergoterm_keys,
  cmd = {
    "TermNew",
    "TermSelect",
    "TermSend",
    "TermUpdate",
    "TermInspect",
    "TermToggleUniversalSelection",
  },
  opts = ergoterm_opts,
}
