local snacks_keys = {}

-- snacks.picker configurations --

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

local function prompt_for_search_dir(callback)
  -- If buffer is not under cwd, prompt for the search directory.
  local buffer_dir = vim.fn.expand("%:p:h")
  local cwd = vim.fn.getcwd()
  if vim.startswith(buffer_dir, "/") and not vim.startswith(buffer_dir, cwd) then
    vim.ui.input({
      prompt = "Search directory: ",
      default = buffer_dir .. "/",
      completion = "dir",
    }, function(dir)
      if not dir then
        return
      end
      callback(dir)
    end)
    return true
  else
    return false
  end
end

local function picker_smart_files(opts)
  opts = opts or {}
  if not opts.cwd then
    local oil_dir = oil_current_dir()
    if oil_dir then
      opts.cwd = oil_dir
    else
      local callback = function(dir)
        opts.cwd = dir
        picker_smart_files(opts)
      end
      if prompt_for_search_dir(callback) then
        return
      else
        opts.cwd = vim.fn.getcwd()
      end
    end
  end
  if not opts.filter then
    opts.filter = { cwd = true, }
  end
  -- Search dirs to cycle through.
  local search_dirs = {
    dirs = {
      opts.cwd,
    },
    current_index = 0
  }
  local buffer_dir = vim.fn.expand("%:p:h")
  if vim.startswith(buffer_dir, "/") and buffer_dir ~= opts.cwd then
    table.insert(search_dirs.dirs, buffer_dir)
  end

  opts.win = {
    input = {
      keys = {
        ["<c-g>"] = { "cycle_search_dirs", mode = { "i", "n" } },
      },
    },
  }
  opts.actions = {
    cycle_search_dirs = function(p)
      if #search_dirs.dirs == 1 then
        return
      end
      search_dirs.current_index = (search_dirs.current_index + 1) % #search_dirs.dirs
      p.opts.cwd = search_dirs.dirs[search_dirs.current_index + 1]
      vim.notify("Searching " .. p.opts.cwd)
      p:find()
    end,
  }

  ---@diagnostic disable-next-line: undefined-field
  picker().smart(opts)
end

local function picker_recent(opts)
  opts.win = {
    input = {
      keys = {
        ["<c-g>"] = { "toggle_cwd", mode = { "i", "n" } },
      },
    },
  }
  opts.actions = {
    toggle_cwd = function(p)
      p.opts.filter.cwd = not p.opts.filter.cwd
      if p.opts.filter.cwd then
        vim.notify("Searching " .. vim.fn.getcwd())
      else
        vim.notify("Searching global")
      end
      p:find()
    end,
  }
  picker().recent(opts)
end

local function picker_grep(opts)
  opts = opts or {}
  if not opts.dirs then
    local callback = function(dir)
      opts.dirs = { dir }
      picker_grep(opts)
    end
    if prompt_for_search_dir(callback) then
      return
    end
  end
  picker().grep(opts)
end

local function picker_grep_word(opts)
  opts = opts or {}
  if not opts.dirs then
    local callback = function(dir)
      opts.dirs = { dir }
      picker_grep_word(opts)
    end
    if prompt_for_search_dir(callback) then
      return
    end
  end
  picker().grep_word(opts)
end

local picker_keys = {
  { "<leader>fa", function() picker().pickers() end, desc = "Search all snacks.picker commands" },
  { "<leader>fR", function() picker().resume() end, desc = "Resume last snacks.picker command" },
  -- Buffers and files.
  { "<leader>ff", function() picker_smart_files() end, desc = "Smart find files" },
  { "<leader>fF", function() picker().files() end, desc = "Find files" },
  { "<leader>fr", function() picker_recent({ filter = { cwd = true } }) end, desc = "Find recent files" },
  { "<leader>fb", function() picker().buffers() end, desc = "Find buffers" },
  -- Search
  { "<leader>fs", function() picker_grep() end, desc = "Search" },
  { "<leader>fw", function() picker_grep_word() end, desc = "Search word or visual selection", mode = { "n", "x" } },
  { "<leader>fs", function() picker_grep_word() end, desc = "Search visual selection", mode = { "x" } },
  -- Lines
  { "<leader>fl", function() picker().lines() end, desc = "Search lines" },
  { "<leader>fL", function() picker().grep_buffers() end, desc = "Search lines from all buffers" },
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
  { "<leader>fgH", function() picker().git_log_line() end, desc = "Git line history" },
  { "<leader>fgl", function() picker().git_log() end, desc = "Git log" },
  { "<leader>fgs", function() picker().git_status() end, desc = "Git status" },
  { "<leader>fgd", function() picker().git_diff() end, desc = "Git diffs" },
  --  quickfix
  { "<leader>ff", function() picker().qflist() end, desc = "Search quickfix", ft = "qf" },
  -- LSP
  { "<leader>ft", function() picker().lsp_symbols() end, desc = "Search LSP symbols" },
  { "<leader>fT", function() picker().lsp_workspace_symbols() end, desc = "Search LSP symbols in workspace" },
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
local picker_opts = {
  layouts = {
    default = {
      layout = {
        width = 0.9,
        height = 0.9,
      },
    },
  },
}

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
      { icon = " ", key = "f", desc = "Find File", action = function() picker_smart_files() end },
      { icon = " ", key = "r", desc = "Recent Files", action = function() picker_recent({ filter = { cwd = true } }) end },
      { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
      { icon = " ", key = "S", desc = "Search Text", action = function() picker_grep() end },
      { icon = " ", key = "s", desc = "Restore Session", section = "session" },
      { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    },
    header = table.concat({
      [[                               __                ]],
      [[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
      [[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
      [[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
      [[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
      [[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
    }, "\n"),
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
      indent = 2,
      padding = 1,
      height = 5,
      ttl = 10,
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
