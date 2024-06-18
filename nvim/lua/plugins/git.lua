-- Needed for the "GBrowse" command from "vim-fugitive".
vim.api.nvim_create_user_command(
  'Browse',
  function(opts)
    vim.fn.system { 'open', opts.fargs[1] }
  end,
  { nargs = 1 }
)

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
      map('n', ']g', function()
        if vim.wo.diff then return ']g' end
        vim.schedule(function() gs.next_hunk() end)
        return '<Ignore>'
      end, "Next git hunk", { expr = true })

      map('n', '[g', function()
        if vim.wo.diff then return '[g' end
        vim.schedule(function() gs.prev_hunk() end)
        return '<Ignore>'
      end, "Previous git hunk", { expr = true })

      -- Actions
      map('n', '<leader>gs', gs.stage_hunk, "Stage hunk")
      map('n', '<leader>gr', gs.reset_hunk, "Reset hunk")
      map('v', '<leader>gs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Stage hunk")
      map('v', '<leader>gr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Reset hunk")
      map('n', '<leader>gS', gs.stage_buffer, "Stage buffer")
      map('n', '<leader>gu', gs.undo_stage_hunk, "Undo stage hunk")
      map('n', '<leader>gR', gs.reset_buffer, "Reset buffer")
      map('n', '<leader>gp', gs.preview_hunk, "Preview hunk")
      map('n', '<leader>gb', function() gs.blame_line { full = true } end, "Blame line")

      -- Text object
      map({ 'o', 'x' }, 'ig', ':<C-U>Gitsigns select_hunk<CR>', "Git hunk")
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
      mapping.lhs = string.gsub(mapping.lhs, "^<space>", "<leader>")
      mapping.lhs = string.gsub(mapping.lhs, "^<leader>", "<leader>o")
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

  require("octo").setup({
    enable_builtin = true,
    picker = "fzf-lua",
    default_merge_method = "squash",
    mappings_disable_default = true,
    mappings = mappings,
    suppress_missing_scope = {
      projects_v2 = true,
    },
  })
  -- Set which-key hints.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "octo",
    callback = function(ev)
      local wk = require('which-key')
      local keys = {
        name = "octo",
        a = { name = "assignee", },
        c = { name = "comment", },
        g = { name = "goto", },
        i = { name = "issue", },
        l = { name = "label", },
        o = { name = "operation", },
        r = { name = "react", },
        v = { name = "review", },
        s = { name = "suggest", },
      }
      if string.match(ev.file, "pull") then
        keys.p = {
          name = "pr",
          m = { name = "merge" },
        }
      end
      wk.register(
        {
          ['<leader>o'] = keys,
        },
        {
          buffer = ev.buf,
        }
      )
    end,
  })
end

return {
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
      'ibhagwan/fzf-lua',
      'nvim-tree/nvim-web-devicons',
    },
    cmd = { "Octo" },
    config = setup_octo,
  },
}
