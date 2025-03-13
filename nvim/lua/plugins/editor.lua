local tmux_navigator_keys = {
  { "<C-M-H>", "<cmd>TmuxNavigateLeft<cr>", desc = "TmuxNavigateLeft" },
  { "<C-M-J>", "<cmd>TmuxNavigateDown<cr>", desc = "TmuxNavigateDown" },
  { "<C-M-K>", "<cmd>TmuxNavigateUp<cr>", desc = "TmuxNavigateUp" },
  { "<C-M-L>", "<cmd>TmuxNavigateRight<cr>", desc = "TmuxNavigateRight" },
  { "<C-M-H>", "<c-\\><c-n><cmd>TmuxNavigateLeft<cr>", mode = "t", desc = "TmuxNavigateLeft" },
  { "<C-M-J>", "<c-\\><c-n><cmd>TmuxNavigateDown<cr>", mode = "t", desc = "TmuxNavigateDown" },
  { "<C-M-K>", "<c-\\><c-n><cmd>TmuxNavigateUp<cr>", mode = "t", desc = "TmuxNavigateUp" },
  { "<C-M-L>", "<c-\\><c-n><cmd>TmuxNavigateRight<cr>", mode = "t", desc = "TmuxNavigateRight" },
}

local function setup_whichkey(_, _)
  local wk = require("which-key")
  ---@diagnostic disable-next-line: missing-fields
  wk.setup({
    preset = "modern",
  })
  wk.add({
    { "<leader>a", group = "ai" },
    { "<leader>b", group = "buffers" },
    { "<leader>c", group = "code" },
    { "<leader>d", group = "debug" },
    { "<leader>f", group = "find" },
    { "<leader>fg", group = "git" },
    { "<leader>g", group = "git" },
    { "<leader>os", group = "search" },
    { "<leader>s", group = "sessions" },
    { "<leader>t", group = "tabs" },
    { "<leader>u", group = "ui" },
    { "<leader>w", group = "windows" },
  })
end

local flash_keys = {
  { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
  { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
  { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
  { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
}

local mini_surround_opts = {
  mappings = {
    add = "gsa",            -- Add surrounding in Normal and Visual modes
    delete = "gsd",         -- Delete surrounding
    find = "gsf",           -- Find surrounding (to the right)
    find_left = "gsF",      -- Find surrounding (to the left)
    highlight = "gsh",      -- Highlight surrounding
    replace = "gsr",        -- Replace surrounding
    update_n_lines = "gsn", -- Update `n_lines`
  },
}

return {
  {
    "christoomey/vim-tmux-navigator",
    keys = tmux_navigator_keys,
    init = function()
      vim.cmd([[
        let g:tmux_navigator_no_mappings = 1
      ]])
    end,
  },
  {
    "tpope/vim-sleuth",
    event = "VeryLazy",
  },
  {
    "ojroques/vim-oscyank",
    event = "VeryLazy",
    init = function()
      vim.cmd([[
        let g:oscyank_silent = 1
        " Automatically copy text that was yanked to register +.
        autocmd TextYankPost *
            \ if v:event.operator is 'y' && v:event.regname is '+' |
            \ execute 'OSCYankRegister +' |
            \ endif
      ]])
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = setup_whichkey,
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "List buffer local keymaps",
      },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    keys = flash_keys,
  },
  {
    'echasnovski/mini.cursorword',
    version = '*',
    event = "VeryLazy",
    opts = {},
  },
  {
    'echasnovski/mini.splitjoin',
    version = '*',
    event = "VeryLazy",
    opts = {},
  },
  {
    "echasnovski/mini.surround",
    version = "*",
    event = "VeryLazy",
    opts = mini_surround_opts,
  },
}
