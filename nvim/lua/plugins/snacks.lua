local snacks_keys = {}

-- snacks.picker configurations --

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
  opts.title = opts.cwd
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
    cycle_search_dirs = function(picker)
      if #search_dirs.dirs == 1 then
        return
      end
      search_dirs.current_index = (search_dirs.current_index + 1) % #search_dirs.dirs
      picker.opts.cwd = search_dirs.dirs[search_dirs.current_index + 1]
      vim.notify("Searching " .. picker.opts.cwd)
      picker:find()
    end,
  }

  ---@diagnostic disable-next-line: undefined-field
  require("snacks.picker").smart(opts)
end

local function picker_recent(opts)
  opts = opts or {}
  if not opts.filter then
    opts.filter = { cwd = false, }
  end
  if not opts.matcher then
    opts.matcher = { cwd_bonus = true, sort_empty = true }
  end
  opts.win = {
    input = {
      keys = {
        ["<c-g>"] = { "toggle_cwd", mode = { "i", "n" } },
      },
    },
  }
  opts.actions = {
    toggle_cwd = function(picker)
      picker.opts.filter.cwd = not picker.opts.filter.cwd
      if picker.opts.filter.cwd then
        vim.notify("Searching " .. vim.fn.getcwd())
      else
        vim.notify("Searching global")
      end
      picker:find()
    end,
  }
  require("snacks.picker").recent(opts)
end

local function picker_grep(opts)
  opts = opts or {}
  if not opts.dirs then
    local oil_dir = oil_current_dir()
    if oil_dir then
      opts.cwd = oil_dir
    else
      local callback = function(dir)
        opts.dirs = { dir }
        picker_grep(opts)
      end
      if prompt_for_search_dir(callback) then
        return
      end
    end
  end
  require("snacks.picker").grep(opts)
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
  require("snacks.picker").grep_word(opts)
end

local function picker_keys()
  local function p()
    return require("snacks.picker")
  end
  return {
    { "<leader>fa", function() p().pickers() end, desc = "Search all snacks.picker commands" },
    { "<leader>fR", function() p().resume() end, desc = "Resume last snacks.picker command" },
    -- Buffers and files.
    { "<leader>ff", function() picker_smart_files() end, desc = "Smart find files" },
    { "<leader>fF", function() p().files() end, desc = "Find files" },
    { "<leader>fr", function() picker_recent() end, desc = "Find recent files" },
    { "<leader>fb", function() p().buffers() end, desc = "Find buffers" },
    -- Search
    { "<leader>fS", function() picker_grep() end, desc = "Search" },
    { "<leader>fs", function() picker_grep_word() end, desc = "Search word or visual selection", mode = { "n", "x" } },
    -- Lines
    { "<leader>fl", function() p().lines() end, desc = "Search lines" },
    { "<leader>fL", function() p().grep_buffers() end, desc = "Search lines from all buffers" },
    --  Misc
    { "<leader>fu", function() p().undo() end, desc = "Find undo history" },
    { "<leader>f:", function() p().command_history() end, desc = "Find command history" },
    { "<leader>f/", function() p().search_history() end, desc = "Find search history" },
    { "<leader>f\"", function() p().registers() end, desc = "Find registers" },
    { "<leader>f'", function() p().marks() end, desc = "Find marks" },
    { "<leader>fj", function() p().jumps() end, desc = "Find jump list" },
    -- git
    { "<leader>fga", function() p().git_stash() end, desc = "Git stash" },
    { "<leader>fgb", function() p().git_branches() end, desc = "Git branches" },
    { "<leader>fgf", function() p().git_files() end, desc = "Git files" },
    { "<leader>fgh", function() p().git_log_file() end, desc = "Git file history" },
    { "<leader>fgH", function() p().git_log_line() end, desc = "Git line history" },
    { "<leader>fgl", function() p().git_log() end, desc = "Git log" },
    { "<leader>fgs", function() p().git_status() end, desc = "Git status" },
    { "<leader>fgd", function() p().git_diff() end, desc = "Git diffs" },
    --  quickfix
    { "<leader>ff", function() p().qflist() end, desc = "Search quickfix", ft = "qf" },
    -- LSP
    { "<leader>ft", function() p().lsp_symbols() end, desc = "Search LSP symbols" },
    { "<leader>fT", function() p().lsp_workspace_symbols() end, desc = "Search LSP symbols in workspace" },
  }
end

for _, key in ipairs(picker_keys()) do
  table.insert(snacks_keys, key)
end

vim.api.nvim_create_user_command(
  "Rg",
  function(opts)
    picker_grep({
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
  win = {
    input = {
      keys = {
        ["<c-a>"] = {
          "go_to_beginning_or_select_all",
          mode = { "n", "i" },
        },
        ["<c-e>"] = {
          "go_to_end",
          mode = { "i" },
        },
      },
    },
  },
  actions = {
    go_to_beginning_or_select_all = function(picker)
      -- If in insert mode, go to beginning of line.
      -- Otherwise, select all.
      local m = vim.api.nvim_get_mode().mode
      if m == "i" then
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Home>", true, false, true),
          "i",
          true
        )
      else
        picker:action("select_all")
      end
    end,
    go_to_end = function(picker)
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<End>", true, false, true),
        "i",
        true
      )
    end,
  }
}

-- End of snacks.picker configurations --

local gitbrowse_keys = {
  { "<leader>go", function() Snacks.gitbrowse.open() end, desc = "Git browse", mode = { "n", "x" }, },
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
      { icon = " ", key = "r", desc = "Recent Files", action = function() picker_recent() end },
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

local terminal_keys = {
  { "<c-/>", function() Snacks.terminal.toggle() end, desc = "Toggle terminal", mode = { "n", "t" } },
  { "<c-_>", function() Snacks.terminal.toggle() end, desc = "Toggle terminal", mode = { "n", "t" } },
  -- <c-\><c-n>: return to normal mode, <c-w>z: zoom, i: enter insert mode
  { "<c-z><c-z>", [[<c-\><c-n><c-w>zi]], desc = "Zoom", mode = "t", remap = true },
  { "<leader>bt", function() Snacks.terminal.colorize() end, desc = "Parse terminal color codes" },
}

for _, key in ipairs(terminal_keys) do
  table.insert(snacks_keys, key)
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    picker = picker_opts,
    indent = {},
    notifier = {},
    bigfile = {},
    scroll = {},
    gitbrowse = {
      what = "permalink",
    },
    explorer = {},
    dashboard = dashboard_opts,
    scope = {},
    terminal = {
      win = {
        wo = { winhighlight = "NormalFloat:Normal" },
      },
    },
    image = {
      doc = {
        inline = false,
        float = true,
        max_width = 200,
        max_height = 200,
      }
    },
    zen = {
      win = {
        width = 0.9,
        border = "hpad",
        backdrop = {
          transparent = false,
        },
      },
    },
  },
  keys = snacks_keys,
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        Snacks.toggle.zoom():map("<leader>wz"):map("<c-w>z")
        Snacks.toggle.zen():map("<leader>uz")
      end,
    })
  end,
}
