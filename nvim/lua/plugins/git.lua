local fugitive_keys = {
  { "<leader>gg", "<cmd>Git<CR>", desc = "Git status" },
}

local function setup_gitsigns()
  require('gitsigns').setup {
    signcolumn = false,
    numhl = true,
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc, opts)
        opts = opts or {}
        opts.desc = desc
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal({ ']c', bang = true })
        else
          gs.nav_hunk('next')
        end
      end, "Next change/hunk", { expr = true })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal({ '[c', bang = true })
        else
          gs.nav_hunk('prev')
        end
      end, "Previous change/hunk", { expr = true })

      -- Actions
      map('n', '<leader>gs', gs.stage_hunk, "Stage hunk")
      map('n', '<leader>gu', gs.undo_stage_hunk, "Undo stage hunk")
      map('n', '<leader>gr', gs.reset_hunk, "Reset hunk")
      map('v', '<leader>gs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Stage hunk")
      map('v', '<leader>gr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Reset hunk")
      map('n', '<leader>gS', gs.stage_buffer, "Stage buffer")
      map('n', '<leader>gR', gs.reset_buffer, "Reset buffer")
      map('n', '<leader>gp', gs.preview_hunk, "Preview hunk")
      map('n', '<leader>gb', function() gs.blame_line { full = true } end, "Blame line")
      map('n', '<leader>gB', gs.blame, "Blame buffer")
      map('n', '<leader>gq', gs.setqflist, "Show buffer hunks in quickfix")
      map('n', '<leader>gQ', function() gs.setqflist('all') end, "Show all hunks in quickfix")

      -- Text object
      map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', "Git hunk")
    end
  }
end

local function toggle_diffview()
  if vim.g.diffview_open then
    vim.cmd("DiffviewClose")
    return
  end

  -- Define the diff options with their corresponding action functions
  local diff_options = {
    {
      name = "Index (Working tree)",
      action = function() vim.cmd("DiffviewOpen") end
    },
    {
      name = "master",
      action = function() vim.cmd("DiffviewOpen master") end
    },
    {
      name = "Merge-base with master",
      action = function()
        vim.fn.jobstart({ 'git', 'merge-base', 'HEAD', 'master' }, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            if data and data[1] and data[1] ~= "" then
              local merge_base = data[1]:gsub("%s+$", "") -- Trim whitespace
              vim.schedule(function()
                vim.cmd("DiffviewOpen " .. merge_base)
              end)
            end
          end,
          on_stderr = function(_, data)
            if data and data[1] and data[1] ~= "" then
              vim.schedule(function()
                vim.notify("Error getting merge-base: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
              end)
            end
          end
        })
      end
    },
    {
      name = "HEAD~1",
      action = function() vim.cmd("DiffviewOpen HEAD~1") end
    },
    {
      name = "HEAD~2",
      action = function() vim.cmd("DiffviewOpen HEAD~2") end
    },
    {
      name = "HEAD~3",
      action = function() vim.cmd("DiffviewOpen HEAD~3") end
    },
    {
      name = "Specify git-rev manually",
      action = function() vim.api.nvim_feedkeys(":DiffviewOpen ", "c", true) end
    }
  }

  -- Get the names for the selector
  local options = {}
  for _, option in ipairs(diff_options) do
    table.insert(options, option.name)
  end

  -- Show the selector
  vim.ui.select(options, {
    prompt = "Select git revision for diff:",
    format_item = function(item) return item end,
  }, function(choice, idx)
    if not choice then return end

    -- Execute the action function directly
    diff_options[idx].action()
  end)
end

local diffview_keys = {
  { '<leader>gd', mode = 'n', toggle_diffview, desc = "Toggle diff view" },
  { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', mode = 'n', desc = 'Current file history' },
  { '<leader>gh', ':DiffviewFileHistory<CR>', mode = 'x', desc = 'File range history' },
  { '<leader>gl', '<cmd>DiffviewFileHistory<CR>', mode = 'n', desc = 'Git log' },
}

local diffview_opts = {
  file_panel = {
    win_config = {
      type = "split",
      position = "bottom",
      height = 16,
    },
  },
  hooks = {
    ---@diagnostic disable-next-line
    view_enter = function(view)
      -- Save the current view
      vim.g.diffview_open = true
    end,
    ---@diagnostic disable-next-line
    view_leave = function(view)
      vim.g.diffview_open = false
    end,
  }
}

local function setup_octo()
  local mappings = {}

  for _, buf_type in pairs({ "issue", "pull_request" }) do
    mappings[buf_type] = {
      reload = { lhs = "<localleader>or" },
      open_in_browser = { lhs = "<localleader>ob" },
      copy_url = { lhs = "<localleader>oy" },
    }
  end

  for _, buf_type in pairs({ "review_thread", "review_diff", "file_panel" }) do
    mappings[buf_type] = {
      -- Disable closing review tabs with ctrl-c.
      close_review_tab = { lhs = "" },
      -- Use "tab" and "s-tab" to navigate between files.
      select_next_entry = { lhs = "<tab>" },
      select_prev_entry = { lhs = "<s-tab>" },
    }
  end

  require("octo").setup({
    enable_builtin = true,
    picker = "snacks",
    default_merge_method = "squash",
    mappings = mappings,
    suppress_missing_scope = {
      projects_v2 = true,
    },
  })
  vim.treesitter.language.register('markdown', 'octo')

  local function set_which_key(buf)
    require('which-key').add({
      buffer = buf,
      { "<localleader>a", group = "assignee", icon = { icon = " ", color = "blue" }, },
      { "<localleader>c", group = "comment", icon = { icon = " ", color = "blue" }, },
      { "<localleader>g", group = "goto", icon = { icon = " ", color = "blue" }, },
      { "<localleader>i", group = "issue", icon = { icon = " ", color = "blue" }, },
      { "<localleader>l", group = "label", icon = { icon = "󰌕 ", color = "blue" }, },
      { "<localleader>o", group = "operation", icon = { icon = " ", color = "blue" }, },
      { "<localleader>p", group = "pr", icon = { icon = " ", color = "blue" }, },
      { "<localleader>r", group = "react", icon = { icon = "󰞅 ", color = "blue" }, },
      { "<localleader>s", group = "suggest", icon = { icon = "󱀡 ", color = "blue" }, },
      { "<localleader>v", group = "review", icon = { icon = " ", color = "blue" }, },
    })
  end

  -- For PR review buffers ("octo") and file panel buffers ("octo_panel").
  -- NOTE: "octo://*" file name pattern can also match the PR review buffers.
  -- But that will lead to a weird behavior where the <localleader> mappings
  -- are not usable until <leader> is pressed once.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "octo", "octo_panel" },
    callback = function(ev) set_which_key(ev.buf) end,
  })

  -- For file review buffers.
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = { "octo://*/review/*" },
    callback = function(ev)
      if not vim.b[ev.buf].octo_setup_done then
        vim.b[ev.buf].octo_setup_done = true
        --- Disable snacks.scroll as it conflicts with the comment buffers
        vim.b[ev.buf].snacks_scroll = false
        set_which_key(ev.buf)
      end
    end,
  })
end

local octo_keys = {
  {
    "<leader>gO",
    "",
    desc = "+octo",
  },
  {
    "<leader>gOp",
    "<cmd>Octo pr search author:@me<CR>",
    desc = "Search repo: my PRs",
  },
  {
    "<leader>gOr",
    "<cmd>Octo pr search is:open assignee:@me<CR>",
    desc = "Search repo: PRs to review",
  },
  {
    "<leader>gOi",
    "<cmd>Octo issue search author:@me<CR>",
    desc = "Search repo: issues created by me",
  },
  {
    "<leader>gOa",
    "<cmd>Octo issue search is:open assignee:@me<CR>",
    desc = "Search repo: open issues assigned to me",
  },
  {
    "<leader>gOP",
    "<cmd>Octo search is:pr author:@me<CR>",
    desc = "Search global: my PRs",
  },
  {
    "<leader>gOR",
    "<cmd>Octo search is:pr is:open assignee:@me<CR>",
    desc = "Search global: PRs to review",
  },
  {
    "<leader>gOI",
    "<cmd>Octo search is:issue author:@me<CR>",
    desc = "Search global: issues created by me",
  },
  {
    "<leader>gOA",
    "<cmd>Octo search is:issue is:open assignee:@me<CR>",
    desc = "Search global: open issues assigned to me",
  },
}

return {
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G" },
    keys = fugitive_keys,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = setup_gitsigns,
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewFileHistory",
    },
    keys = diffview_keys,
    opts = diffview_opts,
  },
  {
    'pwntester/octo.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    cmd = { "Octo" },
    keys = octo_keys,
    config = setup_octo,
  },
}
