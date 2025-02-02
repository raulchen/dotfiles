local function picker()
  return require("snacks").picker
end


local function oil_current_dir()
  local exists, oil = pcall(require, "oil")
  if not exists then
    return nil
  end
  return oil.get_current_dir()
end

local function picker_files(opts)
  opts = opts or {}

  -- If cwd is not provided, use oil current dir or vim cwd.
  ---@diagnostic disable-next-line: undefined-field
  local cwd = opts.cwd or oil_current_dir() or vim.uv.cwd()
  opts.cwd = cwd
  picker().files(opts)
end

local picker_keys = {
  { "<leader>fa", function() picker().pickers() end, desc = "Search all snacks.picker commands" },
  { "<leader>fr", function() picker().resume() end, desc = "Resume last snacks.picker command" },
  -- Buffers and files.
  { "<leader>ff", function() picker_files() end, desc = "Find files" },
  { "<leader>fh", function() picker().recent() end, desc = "Find file history" },
  { "<leader>fb", function() picker().buffers() end, desc = "Find buffers" },
  -- Search
  { "<leader>fs", function() picker().grep() end, desc = "Search" },
  { "<leader>fw", function() picker().grep_word() end, desc = "Search word or visual selection", mode = { "n", "x" } },
  { "<leader>fs", function() picker().grep_word() end, desc = "Search visual selection", mode = { "x" } },
  --  Misc
  { "<leader>f:", function() picker().command_history() end, desc = "Find command history" },
  { "<leader>f/", function() picker().search_history() end, desc = "Find search history" },
  { "<leader>f\"", function() picker().registers() end, desc = "Find registers" },
  { "<leader>f'", function() picker().marks() end, desc = "Find marks" },
  { "<leader>fj", function() picker().jumps() end, desc = "Find jump list" },
  -- git
  { "<leader>fga", function() picker().git_stash() end, desc = "Git stash" },
  { "<leader>fgb", function() picker().git_branches() end, desc = "Git branches" },
  { "<leader>fgf", function() picker().git_files() end, desc = "Git files" },
  { "<leader>fgh", function() picker().git_log_file() end, desc = "Git file history" },
  { "<leader>fgl", function() picker().git_log() end, desc = "Git log" },
  { "<leader>fgs", function() picker().git_status() end, desc = "Git status" },
  { "<leader>fgd", function() picker().git_diff() end, desc = "Git diffs" },
  --  quickfix
  { "<leader>ff", function() picker().qflist() end, desc = "Search quickfix", ft = "qf" },
}

---@class snacks.picker.Config
local picker_opts = {}


return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    picker = picker_opts,
    ---@class snacks.indent.Config
    indent = {},
    ---@class snacks.notifier.Config
    notifier = {},
  },
  keys = picker_keys,
}
