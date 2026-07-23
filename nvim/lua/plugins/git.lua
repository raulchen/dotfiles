local fugitive = {
  "tpope/vim-fugitive",
  cmd = { "Git", "G" },
  keys = { "<leader>gg", "<cmd>Git<CR>", desc = "Git status" },
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
          return ']c'
        else
          gs.nav_hunk('next')
          return ''
        end
      end, "Next change/hunk", { expr = true })

      map('n', '[c', function()
        if vim.wo.diff then
          return '[c'
        else
          gs.nav_hunk('prev')
          return ''
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

local gitsigns = {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = setup_gitsigns,
}

-- Fuzzy file switcher shared by the Octo PR review layout and Diffview, built
-- on snacks.picker. Both plugins expose an ordered list of changed files and a
-- "jump to this file" call; this wraps them in a fuzzy picker so you can hop
-- straight to any file instead of cycling with <tab>/<s-tab> or [q/]q.
--
-- `opts.items` is a list of { file, path, status, additions, deletions } and
-- `opts.on_choice` receives the chosen item to perform the jump.
local function changed_file_picker(opts)
  if #opts.items == 0 then
    vim.notify("No changed files", vim.log.levels.WARN)
    return
  end

  local devicons = require("nvim-web-devicons")
  local status_hl = { A = "Added", D = "Removed", M = "Changed", R = "Changed" }

  for i, item in ipairs(opts.items) do
    item.idx = i
    item.text = item.path -- fuzzy-match/sort against the repo-relative path
  end

  require("snacks.picker").pick({
    title = opts.title,
    items = opts.items,
    preview = "none",
    layout = "select",
    format = function(item)
      local ret = {}
      local ext = item.path:match("%.([^./]+)$")
      local icon, icon_hl = devicons.get_icon(item.path, ext, { default = true })
      local parent, basename = item.path:match("^(.*/)([^/]+)$")
      basename = basename or item.path

      -- Marker for the file currently open in the review / diff.
      ret[#ret + 1] = { item.current and "● " or "  ", "Special" }
      ret[#ret + 1] = { item.status or " ", status_hl[item.status] or "Comment" }
      ret[#ret + 1] = { " " .. icon .. " ", icon_hl }
      if parent then
        ret[#ret + 1] = { parent, "SnacksPickerDir" }
      end
      ret[#ret + 1] = { basename }
      if (item.additions or 0) > 0 then
        ret[#ret + 1] = { "  +" .. item.additions, "Added" }
      end
      if (item.deletions or 0) > 0 then
        ret[#ret + 1] = { " -" .. item.deletions, "Removed" }
      end
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        opts.on_choice(item)
      end
    end,
    -- Start the cursor on the file currently open in the review / diff.
    on_show = function(picker)
      for i, item in ipairs(picker:items()) do
        if item.current then
          picker.list:view(i)
          Snacks.picker.actions.list_scroll_center(picker)
          break
        end
      end
    end,
  })
end

-- Build a picker item from a plugin's file entry. `entry` is kept by reference
-- because both plugins match the selected file by object identity.
local function make_file_item(entry, stats)
  return {
    file = entry,
    path = entry.path,
    status = (entry.status and entry.status ~= " ") and entry.status or nil,
    additions = stats and stats.additions,
    deletions = stats and stats.deletions,
  }
end

-- Fuzzy switch between files in the current Octo PR review layout.
local function pick_octo_review_file()
  local ok, reviews = pcall(require, "octo.reviews")
  if not ok then return end
  local review = reviews.get_current_review()
  if not review or not review.layout then
    vim.notify("No active Octo review", vim.log.levels.WARN)
    return
  end
  local layout = review.layout
  local current = layout:get_current_file()

  local items = {}
  for _, f in ipairs(layout.files) do
    local item = make_file_item(f, f.stats)
    item.current = f == current
    items[#items + 1] = item
  end

  changed_file_picker({
    title = "PR review files",
    items = items,
    on_choice = function(item)
      layout:set_current_file(item.file)
    end,
  })
end

-- Fuzzy switch between files in the current Diffview.
local function pick_diffview_file()
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then return end
  local DiffView = require("diffview.scene.views.diff.diff_view").DiffView
  local view = lib.get_current_view()
  if not (view and view:instanceof(DiffView)) then
    vim.notify("No active Diffview", vim.log.levels.WARN)
    return
  end

  local current = view.panel and view.panel.cur_file
  local items = {}
  for _, f in view.files:iter() do
    local item = make_file_item(f, f.stats)
    item.current = f == current
    items[#items + 1] = item
  end

  changed_file_picker({
    title = "Diffview files",
    items = items,
    on_choice = function(item)
      view:set_file(item.file, true, true) -- focus diff buffers + highlight in panel
    end,
  })
end

local function open_diffview()
  -- Define the diff options with their corresponding action functions
  local diff_options = {
    {
      name = "Index (Working tree)",
      action = function() vim.cmd("DiffviewOpen") end
    },
    {
      name = "Branch changes (working tree)",
      action = function()
        local base = vim.fn.trim(vim.fn.system("git merge-base HEAD origin/HEAD"))
        vim.cmd("DiffviewOpen " .. base)
      end
    },
    {
      name = "Branch changes (committed)",
      action = function() vim.cmd("DiffviewOpen origin/HEAD...HEAD") end
    },
    {
      name = "Pick a commit",
      action = function()
        require("snacks.picker").git_log({
          title = "Select commit for diff",
          confirm = function(picker, item)
            picker:close()
            vim.cmd("DiffviewOpen " .. item.commit)
          end,
        })
      end
    },
    {
      name = "Manually specify",
      action = function() vim.api.nvim_feedkeys(":DiffviewOpen ", "c", true) end
    }
  }

  -- Show the selector
  vim.ui.select(diff_options, {
    prompt = "Select git revision for diff:",
    format_item = function(item) return item.name end,
  }, function(choice, idx)
    if not choice then return end

    -- Execute the action function
    choice.action()
  end)
end

local diffview_keys = {
  { '<leader>gd', mode = 'n', open_diffview, desc = "Toggle diff view" },
  { '<leader>gh', '<cmd>DiffviewFileHistory % --max-count=1000<CR>', mode = 'n', desc = 'Current file history' },
  { '<leader>gh', ':DiffviewFileHistory --max-count=1000<CR>', mode = 'x', desc = 'File range history' },
  { '<leader>gl', '<cmd>DiffviewFileHistory --max-count=1000<CR>', mode = 'n', desc = 'Git log' },
}

local function setup_diffview()
  local keymaps = require("diffview.config").defaults.keymaps
  keymaps = vim.deepcopy(keymaps)

  for _, v in pairs(keymaps) do
    if type(v) == "table" then
      for _, keymap in ipairs(v) do
        if keymap[2] and keymap[2]:find("<leader>") then
          keymap[2] = keymap[2]:gsub("<leader>", "<localleader>")
        end
      end
    end
  end
  keymaps.disable_defaults = true

  -- Add [q/]q to switch files and [Q/]Q to jump to the first/last file,
  -- across the diff windows, the file panel, and the file-history panel.
  local actions = require("diffview.actions")
  local file_nav = {
    { "n", "]q", actions.select_next_entry,  { desc = "Open the diff for the next file" } },
    { "n", "[q", actions.select_prev_entry,  { desc = "Open the diff for the previous file" } },
    { "n", "]Q", actions.select_last_entry,  { desc = "Open the diff for the last file" } },
    { "n", "[Q", actions.select_first_entry, { desc = "Open the diff for the first file" } },
  }
  for _, ctx in ipairs({ "view", "file_panel", "file_history_panel" }) do
    for _, m in ipairs(file_nav) do
      table.insert(keymaps[ctx], m)
    end
  end

  -- Fuzzy file switcher across the diff windows and the file panel.
  for _, ctx in ipairs({ "view", "file_panel" }) do
    table.insert(keymaps[ctx],
      { "n", "<leader>ff", pick_diffview_file, { desc = "Fuzzy switch changed file" } })
  end

  local diffview_opts = {
    file_panel = {
      win_config = {
        type = "split",
        position = "bottom",
        height = 12,
      },
    },
    keymaps = keymaps,
    hooks = {
      diff_buf_read = function(bufnr)
        -- Disable snacks.scroll
        vim.b[bufnr].snacks_scroll = false
      end,
      ---@diagnostic disable-next-line
      view_enter = function(view)
        -- Save the current view
        vim.g.diffview_open = true
      end,
      ---@diagnostic disable-next-line
      view_leave = function(view)
        vim.g.diffview_open = false
      end,
    },
  }
  require("diffview").setup(diffview_opts)
end

local diffview = {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewOpen",
    "DiffviewFileHistory",
  },
  keys = diffview_keys,
  config = setup_diffview,
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

  -- Octo defaults to "]q"/"[q" for file navigation. Octo only allows a single
  -- lhs per action, so add "<tab>"/"<s-tab>" as extra keys alongside them.
  local function set_file_nav_keys(buf)
    local m = require("octo.mappings")
    vim.keymap.set("n", "<tab>", m.select_next_entry,
      { silent = true, noremap = true, buffer = buf, desc = "Select next changed file" })
    vim.keymap.set("n", "<s-tab>", m.select_prev_entry,
      { silent = true, noremap = true, buffer = buf, desc = "Select previous changed file" })
    vim.keymap.set("n", "<leader>ff", pick_octo_review_file,
      { silent = true, noremap = true, buffer = buf, desc = "Fuzzy switch changed file" })
  end

  -- Extra keymaps for the PR overview buffer, beyond octo's builtins.
  local function set_pr_keys(buf)
    -- Octo has no builtin mapping for "Octo review browse" (open the review
    -- layout read-only, without starting a pending review on GitHub). Bind it
    -- alongside the builtin <localleader>vs (start) / <localleader>vr (resume).
    vim.keymap.set("n", "<localleader>vb", "<cmd>Octo review browse<CR>",
      { silent = true, noremap = true, buffer = buf, desc = "Browse review (no pending review)" })
  end

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
    callback = function(ev)
      set_which_key(ev.buf)
      -- Only the file panel navigates between files, not the PR overview.
      if vim.bo[ev.buf].filetype == "octo_panel" then
        set_file_nav_keys(ev.buf)
      end
      -- Extra keymaps for the PR overview buffer.
      if vim.api.nvim_buf_get_name(ev.buf):match("octo://.*/pull/") then
        set_pr_keys(ev.buf)
      end
    end,
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
        set_file_nav_keys(ev.buf)
      end
    end,
  })

  -- Octo's diff placeholder ("null") buffer for the empty side of an
  -- added/deleted file is created as a real, file-backed buffer named
  -- "octo/null" (relative to cwd), so nvim tries to write a swapfile for it.
  -- Its name is constant (unlike the "octo://.../<review-id>/..." diff
  -- buffers), so any two nvim instances doing an Octo review collide on that
  -- one swapfile. Disable the swapfile so it is never created.
  vim.api.nvim_create_autocmd("BufFilePost", {
    pattern = { "octo/null", "*/octo/null" },
    callback = function(ev)
      vim.bo[ev.buf].swapfile = false
    end,
  })

  -- Re-enable wrap when diff mode is enabled in review buffers.
  -- When Octo calls :diffthis, it automatically sets wrap=false.
  -- This autocmd triggers when diff is enabled and overrides that behavior.
  vim.api.nvim_create_autocmd("OptionSet", {
    pattern = "diff",
    callback = function()
      local bufname = vim.api.nvim_buf_get_name(0)
      if bufname:match("octo://.*review") and vim.wo.diff then
        vim.wo.wrap = true
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

local octo = {
  'pwntester/octo.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  cmd = { "Octo" },
  keys = octo_keys,
  config = setup_octo,
}

return {
  fugitive,
  gitsigns,
  diffview,
  octo,
}
