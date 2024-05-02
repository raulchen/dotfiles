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
  { '<leader>gH', '<cmd>DiffviewFileHistory<CR>', mode = 'n', desc = 'Repo history' },
}

local diffview_opts = {
  hooks = {
    view_enter = function(view)
      -- Save the current view
      vim.g.diffview_open = true
    end,
    view_leave = function(view)
      vim.g.diffview_open = false
    end,
  }
}

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
}
