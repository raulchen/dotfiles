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

local function picker_dirs(opts)
  opts = opts or {}
  -- Set default for hidden if not specified
  if opts.hidden == nil then
    opts.hidden = false
  end
  local search_dir
  if not opts.cwd then
    local oil_dir = oil_current_dir()
    if oil_dir then
      search_dir = oil_dir
    else
      local callback = function(dir)
        opts.cwd = dir
        picker_dirs(opts)
      end
      if prompt_for_search_dir(callback) then
        return
      else
        search_dir = vim.fn.getcwd()
      end
    end
    opts.cwd = search_dir
  end
  opts.title = "Directories in " .. (search_dir or opts.cwd)
  opts.win = {
    input = {
      keys = {
        ["<c-g>"] = { "toggle_hidden", mode = { "i", "n" } },
      },
    },
  }
  opts.actions = {
    toggle_hidden = function(picker)
      picker.opts.hidden = not (picker.opts.hidden or false)
      if picker.opts.hidden then
        vim.notify("Showing hidden directories")
      else
        vim.notify("Hiding hidden directories")
      end
      picker:find()
    end,
  }
  local search_cwd = opts.cwd -- Capture cwd in closure
  opts.finder = function(filter, ctx)
    local cmd, args

    -- Get current picker options (includes toggled hidden state)
    local picker_opts = ctx.picker.opts

    -- Simple command selection
    if vim.fn.executable("fd") == 1 then
      cmd = "fd"
      args = { "--type", "d", "--color", "never", "-E", ".git", ".", search_cwd }
    elseif vim.fn.executable("fdfind") == 1 then
      cmd = "fdfind"
      args = { "--type", "d", "--color", "never", "-E", ".git", ".", search_cwd }
    else
      cmd = "find"
      args = { search_cwd, "-type", "d", "-not", "-path", "*/.*" }
    end

    -- Handle hidden directories toggle
    if picker_opts.hidden then
      if cmd == "fd" or cmd == "fdfind" then
        table.insert(args, #args, "--hidden") -- Insert before path
      elseif cmd == "find" then
        -- Remove the hidden exclusion for find
        for i = #args, 1, -1 do
          if args[i] == "*/.*" and args[i - 1] == "-path" and args[i - 2] == "-not" then
            table.remove(args, i)
            table.remove(args, i - 1)
            table.remove(args, i - 2)
            break
          end
        end
      end
    end

    return require("snacks.picker.source.proc").proc({
      picker_opts,
      {
        cmd = cmd,
        args = args,
        notify = not picker_opts.live,
        transform = function(item)
          item.file = item.text
          item.dir = true
        end,
      },
    }, ctx)
  end
  require("snacks.picker")(opts)
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
    { "<leader>fd", function() picker_dirs() end, desc = "Find directories" },
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
    { "<leader>fn", function() p().notifications() end, desc = "Find notifications" },
    { "<leader>fh", function() p().help() end, desc = "Find help" },
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
        ["<c-w><c-w>"] = {
          "cycle_win",
          mode = { "n" },
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
  },
  formatters = {
    file = {
      truncate = 80,
    },
  },
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

local terminal_opts = {
  auto_insert = false,
  start_insert = true,
  win = {
    wo = {
      winhighlight = "NormalFloat:Normal",
      winbar = "%{b:snacks_terminal.id}: %{b:term_title}",
    },
    keys = {
      q = false,           -- disable q to hide
      term_normal = false, -- disable double esc to normal mode
      hide_slash = { "<C-/>", "hide", desc = "Hide Terminal", mode = { "t", "n" } },
      hide_underscore = { "<c-_>", "hide", desc = "which_key_ignore", mode = { "t", "n" } },
    },
  },
}

-- Remember the last Snacks terminal instance so <c-/> can reopen it.
---@type snacks.terminal?
local last_terminal

-- Find the Snacks terminal that owns the given buffer.
local function terminal_from_buf(buf)
  if last_terminal and last_terminal:buf_valid() and last_terminal.buf == buf then
    return last_terminal
  end
  for _, term in ipairs(Snacks.terminal.list()) do
    if term:buf_valid() and term.buf == buf then
      return term
    end
  end
end

local function set_last_terminal(term)
  if term and term:buf_valid() then
    last_terminal = term
  end
end

-- Update the cached terminal whenever we enter a Snacks terminal buffer.
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("SnacksRememberTerminal", { clear = true }),
  callback = function(event)
    if vim.bo[event.buf].filetype == "snacks_terminal" then
      set_last_terminal(terminal_from_buf(event.buf))
    end
  end,
})

-- Toggle the last terminal (or create one) while honoring manual counts.
local function toggle_terminal(count)
  count = count or (vim.v.count > 0 and vim.v.count)
  -- If a count is provided, toggle that terminal.
  if count then
    local terminal = Snacks.terminal.toggle(nil, { count = count })
    set_last_terminal(terminal)
    return
  end

  -- Otherwise, toggle the last used terminal if it exists.
  if last_terminal and last_terminal:buf_valid() then
    last_terminal:toggle()
    set_last_terminal(last_terminal)
    return
  end

  -- Fallback: toggle a new terminal.
  local terminal = Snacks.terminal.toggle(nil, {})
  set_last_terminal(terminal)
end

local terminal_keys = {
  { "<c-/>", toggle_terminal, desc = "Toggle terminal", mode = { "n", "t" } },
  { "<c-_>", toggle_terminal, desc = "Toggle terminal", mode = { "n", "t" } },
  -- <c-\><c-n>: return to normal mode, <c-w>z: zoom, i: enter insert mode
  { "<c-z><c-z>", [[<c-\><c-n><c-w>zi]], desc = "Zoom", mode = "t", remap = true },
  { "<leader>bt", function() Snacks.terminal.colorize() end, desc = "Parse terminal color codes" },
  { "<leader>ft", "<cmd>TermPick<cr>", desc = "Pick a Snacks terminal" },
}

-- Map <A-1> to <A-9> to toggle terminals 1 to 9.
for i = 1, 9 do
  table.insert(terminal_keys, {
    "<A-" .. i .. ">",
    function() toggle_terminal(i) end,
    desc = "Toggle terminal " .. i,
    mode = { "n" },
    remap = false,
  })
  table.insert(terminal_keys, {
    "<A-" .. i .. ">",
    function() toggle_terminal(i) end,
    desc = "Toggle terminal " .. i,
    mode = { "t" },
    remap = false,
  })
end

for _, key in ipairs(terminal_keys) do
  table.insert(snacks_keys, key)
end

-- Convenience commands for opening shared layouts that also update the cache.
for _, term in ipairs({
  { name = "Term", position = "current" },
  { name = "TermRight", position = "right" },
  { name = "TermFloat", position = "float" },
  { name = "TermBottom", position = "bottom" },
}) do
  vim.api.nvim_create_user_command(term.name, function(opts)
    local cmd = opts.args ~= "" and opts.args or nil
    local count = (opts.count or 0) > 0 and opts.count or nil
    local terminal = Snacks.terminal(cmd, {
      count = count,
      win = {
        bo = {
          buflisted = term.position == "current",
        },
        position = term.position,
      },
    })
    set_last_terminal(terminal)
  end, { nargs = "*", complete = "shellcmd", count = 0 })
end

-- Present existing Snacks terminals in a simple picker.
vim.api.nvim_create_user_command("TermPick", function()
  local items = {}
  for _, term in ipairs(Snacks.terminal.list()) do
    if term:buf_valid() then
      local ok, info = pcall(vim.api.nvim_buf_get_var, term.buf, "snacks_terminal")
      local id = ok and info and info.id or term.id
      local title = vim.b[term.buf].term_title
      items[#items + 1] = {
        text = string.format("%s: %s", id or "?", title),
        term = term,
      }
    end
  end

  if vim.tbl_isempty(items) then
    Snacks.notify.warn("No Snacks terminals found")
    return
  end

  Snacks.picker({
    title = "Terminals",
    focus = "list",
    items = items,
    format = "text",
    layout = { hidden = { "preview" } },
    confirm = function(picker, item)
      if not item or not item.term then
        return
      end
      local term = item.term
      set_last_terminal(term)
      term:show()
      picker:close()
    end,
  })
end, { nargs = 0 })

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
    terminal = terminal_opts,
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

        Snacks.toggle.zoom():map("<leader>wz"):map("<c-w>z"):map("<c-z><c-z>", { mode = { "n", "v", "i" } })
        Snacks.toggle.zen():map("<leader>uz")
        Snacks.toggle.option("spell", { name = "spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "wrap" }):map("<leader>uw")
        Snacks.toggle.new({
          id = "dark_theme",
          name = "dark theme",
          get = function()
            return vim.g.colors_name == "onedark"
          end,
          set = function(state)
            vim.cmd(state and "colorscheme onedark" or "colorscheme onelight")
            -- laststatus gets reset when changing colorscheme,
            -- set it to 3 again
            vim.opt.laststatus = 3
          end,
        }):map(
          "<leader>uT")
      end,
    })
  end,
}
