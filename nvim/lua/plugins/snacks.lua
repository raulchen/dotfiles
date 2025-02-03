local function picker()
  return require("snacks").picker
end

local snacks_keys = {}


-- snacks.picker configurations --

local function oil_current_dir()
  local exists, oil = pcall(require, "oil")
  if not exists then
    return nil
  end
  return oil.get_current_dir()
end

local function picker_files(opts)
  opts = opts or {}

  local oil_dir = oil_current_dir()
  if oil_dir then
    opts.dirs = { oil_dir }
  end
  picker().files(opts)
end

local picker_keys = {
  { "<leader>fa", function() picker().pickers() end, desc = "Search all snacks.picker commands" },
  { "<leader>fr", function() picker().resume() end, desc = "Resume last snacks.picker command" },
  -- Buffers and files.
  { "<leader>ff", function() picker_files() end, desc = "Find files" },
  { "<leader>fm", function() picker().smart() end, desc = "Smart jump" },
  { "<leader>fh", function() picker().recent({ filter = { cwd = true } }) end, desc = "Find CWD file history" },
  { "<leader>fH", function() picker().recent() end, desc = "Find file history" },
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
for _, key in ipairs(picker_keys) do
  table.insert(snacks_keys, key)
end

vim.api.nvim_create_user_command(
  "Rg",
  function(opts)
    Snacks.picker.grep({
      search = opts.args,
      live = false,
      supports_live = true,
    })
  end,
  { nargs = "?" }
)

---@class snacks.picker.Config
local picker_opts = {}

-- End of snacks.picker configurations --

local gitbrowse_keys = {
  { "<leader>go", function() Snacks.gitbrowse.open() end, desc = "Browse git files" },
}

for _, key in ipairs(gitbrowse_keys) do
  table.insert(snacks_keys, key)
end

local explorer_keys = {
  { "<leader>ut", function() Snacks.explorer() end, desc = "Toggle file explorer" },
}

for _, key in ipairs(explorer_keys) do
  table.insert(snacks_keys, key)
end

--@type snacks.dashboard.Config
local dashboard_opts = {
  preset = {
    keys = {
      { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
      { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
      { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
      { icon = " ", key = "h", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
      { icon = " ", key = "s", desc = "Restore Session", section = "session" },
      { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    },
  },
  sections = {
    { section = "header" },
    { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
    {
      icon = " ",
      pane = 2,
      title = "Recent Files",
      section = "recent_files",
      indent = 2,
      padding = 1,
      cwd = true,
      limit = 10,
    },
    {
      icon = " ",
      pane = 2,
      title = "Projects",
      section = "projects",
      indent = 2,
      padding = 1,
    },

    {
      icon = " ",
      pane = 2,
      title = "Git Status",
      section = "terminal",
      enabled = function()
        return Snacks.git.get_root() ~= nil
      end,
      cmd = "git status --short --branch --renames",
      height = 5,
      padding = 1,
      ttl = 5 * 60,
      indent = 3,
    },
    { section = "startup" },
  },
}

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    picker = picker_opts,
    indent = {},
    notifier = {},
    bigfile = {},
    scroll = {},
    gitbrowse = {},
    explorer = {},
    dashboard = dashboard_opts,
  },
  keys = snacks_keys,
}
