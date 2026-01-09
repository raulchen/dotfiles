-- Helper function to focus or start a terminal
local function focus_or_start_terminal(term)
  if term:is_active() then
    term:focus()
  else
    term:start()
    term:focus()
  end
end

-- Helper function to create, start, and focus a new terminal
local function create_and_focus_terminal(name, layout)
  local ergoterm = require("ergoterm")
  local term = ergoterm:new({
    name = name,
    layout = layout,
  })
  term:start()
  term:focus()
end

local function create_new_terminal()
  local ergoterm = require("ergoterm")
  local num = 1
  while ergoterm.get_by_name(tostring(num)) do
    num = num + 1
  end
  create_and_focus_terminal(tostring(num), "float")
end

local function cycle_terminal(direction)
  local ergoterm = require("ergoterm")

  local all_terms = vim.tbl_filter(function(term)
    return term:is_active()
  end, ergoterm.get_all())

  if #all_terms < 2 then
    return
  end

  -- Sort by name
  table.sort(all_terms, function(a, b)
    return tonumber(a.name) < tonumber(b.name)
  end)

  -- Find current terminal index
  local current_term = ergoterm.identify()
  local current_idx
  for i, term in ipairs(all_terms) do
    if term.id == current_term.id then
      current_idx = i
      break
    end
  end

  if not current_idx then
    return
  end

  -- Calculate next index
  local next_idx
  if direction == "next" then
    next_idx = current_idx % #all_terms + 1
  else
    next_idx = (current_idx - 2) % #all_terms + 1
  end

  focus_or_start_terminal(all_terms[next_idx])
end

local function toggle_terminal(count)
  local ergoterm = require("ergoterm")

  -- Check if current buffer is already a terminal
  local current_term = ergoterm.identify()
  if current_term then
    current_term:close()
    return
  end

  -- If both count and vim.v.count are absent, toggle the last used terminal
  if not count and (not vim.v.count or vim.v.count == 0) then
    local last_term = ergoterm.get_state("last_focused")
    if last_term then
      focus_or_start_terminal(last_term)
      return
    end
  end

  -- Otherwise, open the terminal named $count
  count = count or (vim.v.count > 0 and vim.v.count) or 1
  local term_name = tostring(count)
  local term = ergoterm.get_by_name(term_name)

  if term then
    focus_or_start_terminal(term)
  else
    create_and_focus_terminal(term_name, "float")
  end
end

local ergoterm_keys = {
  { "<c-/>", toggle_terminal, desc = "Toggle terminal", mode = { "n", "t" } },
  { "<c-_>", toggle_terminal, desc = "Toggle terminal", mode = { "n", "t" } },
  { "<c-\\><c-n>", function() cycle_terminal("next") end, desc = "Next terminal", ft = "ergoterm", mode = "t" },
  { "<c-\\><c-p>", function() cycle_terminal("prev") end, desc = "Previous terminal", ft = "ergoterm", mode = "t" },
  { "<c-\\><c-c>", create_new_terminal, desc = "Create new terminal", ft = "ergoterm", mode = "t" },
  { "<leader>ft", "<cmd>TermSelect<cr>", desc = "Pick a terminal" },
}

-- Map <A-1> to <A-9> to toggle terminals 1 to 9
for i = 1, 9 do
  table.insert(ergoterm_keys, {
    "<A-" .. i .. ">",
    function() toggle_terminal(i) end,
    desc = "Toggle terminal " .. i,
    mode = { "n", "t" },
  })
end

local ergoterm_opts = {
  terminal_defaults = {
    float_winblend = 0,
    size = {
      right = "50%",
      below = "45%",
    },
    persist_mode = true,
    on_open = function(term)
      -- Set winbar for non-floating terminals
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
            string.format("  %s   %s", name, dir),
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
