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

local diffview_keys = {
  {
    '<leader>gd',
    function()
      if vim.g.diffview_open then
        vim.cmd("DiffviewClose")
      else
        vim.api.nvim_feedkeys(":DiffviewOpen ", "c", true)
      end
    end,
    mode = 'n',
    desc = "Toggle diff view"
  },
  { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', mode = 'n', desc = 'Current file history' },
  { '<leader>gh', ':DiffviewFileHistory<CR>', mode = 'x', desc = 'File range history' },
  { '<leader>gl', '<cmd>DiffviewFileHistory<CR>', mode = 'n', desc = 'Git log' },
}

local diffview_opts = {
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
  -- Replace "<leader>" with "<leader>o" in the predefined mappings.
  local mappings = require("octo.config").get_default_values().mappings
  for _, func_mappings in pairs(mappings) do
    for _, mapping in pairs(func_mappings) do
      mapping.lhs = string.gsub(mapping.lhs, "^<localleader>", "<leader>o")
    end
  end
  -- Update some mappings.
  mappings.pull_request.squash_and_merge_pr.lhs = "<leader>opms"
  mappings.pull_request.rebase_and_merge_pr.lhs = "<leader>opmr"

  for _, buf_type in pairs({ "issue", "pull_request" }) do
    mappings[buf_type].reload.lhs = "<leader>oor"
    mappings[buf_type].open_in_browser.lhs = "<leader>oob"
    mappings[buf_type].copy_url.lhs = "<leader>ooy"
  end

  for _, buf_type in pairs({ "review_thread", "review_diff", "file_panel" }) do
    -- Disable closing review tabs with ctrl-c.
    mappings[buf_type].close_review_tab.lhs = ""
    -- Use "tab" and "s-tab" to navigate between files.
    mappings[buf_type].select_next_entry.lhs = "<tab>"
    mappings[buf_type].select_prev_entry.lhs = "<s-tab>"
  end
  mappings.review_thread.add_suggestion.lhs = "<leader>oSa"
  mappings.review_diff.add_review_suggestion.lhs = "<leader>oSa"

  require("octo").setup({
    enable_builtin = true,
    default_merge_method = "squash",
    mappings_disable_default = true,
    mappings = mappings,
    suppress_missing_scope = {
      projects_v2 = true,
    },
  })
  vim.treesitter.language.register('markdown', 'octo')
  -- Set which-key hints.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "octo",
    callback = function(ev)
      local wk = require('which-key')
      local keys = {
        buffer = ev.buf,
        { "<leader>oa", group = "assignee" },
        { "<leader>oc", group = "comment" },
        { "<leader>og", group = "goto" },
        { "<leader>oi", group = "issue" },
        { "<leader>ol", group = "label" },
        { "<leader>oo", group = "operation" },
        { "<leader>or", group = "react" },
        { "<leader>ov", group = "review" },
        { "<leader>os", group = "search" },
        { "<leader>oS", group = "suggest" },
      }
      if string.match(ev.file, "pull") then
        table.insert(keys, { "<leader>op", group = "pr" })
        table.insert(keys, { "<leader>om", group = "merge" })
      end
      wk.add(keys)
    end,
  })
end

local octo_keys = {
  {
    "<leader>osp",
    "<cmd>Octo pr search author:@me<CR>",
    desc = "Search repo: my PRs",
  },
  {
    "<leader>osr",
    "<cmd>Octo pr search is:open assignee:@me<CR>",
    desc = "Search repo: PRs to review",
  },
  {
    "<leader>osi",
    "<cmd>Octo issue search author:@me<CR>",
    desc = "Search repo: issues created by me",
  },
  {
    "<leader>osa",
    "<cmd>Octo issue search is:open assignee:@me<CR>",
    desc = "Search repo: open issues assigned to me",
  },
  {
    "<leader>osP",
    "<cmd>Octo search is:pr author:@me<CR>",
    desc = "Search global: my PRs",
  },
  {
    "<leader>osR",
    "<cmd>Octo search is:pr is:open assignee:@me<CR>",
    desc = "Search global: PRs to review",
  },
  {
    "<leader>osI",
    "<cmd>Octo search is:issue author:@me<CR>",
    desc = "Search global: issues created by me",
  },
  {
    "<leader>osA",
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
