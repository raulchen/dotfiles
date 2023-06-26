local function setup_neotree(_, opts)
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  vim.keymap.set("n", "<leader>n", "<cmd>Neotree toggle<cr>", { noremap = true, desc = "Toggle Neotree" })
  require("neo-tree").setup(opts)
end

local function setup_whichkey(_, _)
  local wk = require("which-key")
  wk.setup()
  wk.register({
    b = { name = "code" },
    c = { name = "code" },
    d = { name = "debug" },
    f = { name = "find" },
    t = { name = "terminal" },
    u = { name = "ui" },
  }, { prefix = "<leader>" })
end

local lualine_opts = {
  sections = {
    lualine_c = {
      {
        "filename",
        path = 1,
      },
      {
        "navic",
      },
    },
    lualine_x = {
      {
        "filetype",
      },
    },
  },
}

local function setup_toggleterm(_, _)
  local opts = {
    open_mapping = [[<c-t>]],
    size = function(term)
      if term.direction == "horizontal" then
        return vim.o.lines * 0.3
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.3
      end
    end,
    float_opts = {
      border = 'curved',
    },
  }
  require("toggleterm").setup(opts)

  -- Keymaps
  local keymap = vim.keymap.set
  keymap("n", "<leader>tt", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
  keymap("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Toggle horizontal terminal" })
  keymap("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Toggle vertical terminal" })

  function _G.set_terminal_keymaps()
    local keymap_opts = { buffer = 0 }
    keymap('t', '<esc>', [[<C-\><C-n>]], keymap_opts)
    keymap('t', '<C-M-h>', [[<Cmd>wincmd h<CR>]], keymap_opts)
    keymap('t', '<C-M-j>', [[<Cmd>wincmd j<CR>]], keymap_opts)
    keymap('t', '<C-M-k>', [[<Cmd>wincmd k<CR>]], keymap_opts)
    keymap('t', '<C-M-l>', [[<Cmd>wincmd l<CR>]], keymap_opts)
    keymap('t', '<C-w>', [[<C-\><C-n><C-w>]], keymap_opts)
  end

  -- if you only want these mappings for toggle term use term://*toggleterm#* instead
  vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v2.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      enable_diagnostics = false,
      filesystem = {
        follow_current_file = true,
        use_libuv_file_watcher = true,
      },
    },
    config = setup_neotree,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    opts = {
      show_current_context = true,
      show_current_context_start = false,
    },
  },
  {
    "folke/which-key.nvim",
    config = setup_whichkey,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signcolumn = false,
      numhl = true,
    },
  },
  {
    -- Show current code context.
    "SmiteshP/nvim-navic",
    dependencies = "neovim/nvim-lspconfig",
    opts = {
      lsp = {
        auto_attach = true,
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = lualine_opts,
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = {
        numbers = "ordinal",
      },
    },
  },
  {
    "nyngwang/NeoZoom.lua",
    config = function()
      require("neo-zoom").setup()
      vim.keymap.set('n', '<leader>uz', function() vim.cmd('NeoZoomToggle') end, { desc = "Toggle zoom" })
      vim.keymap.set('n', '<c-w>z', function() vim.cmd('NeoZoomToggle') end, { desc = "Toggle zoom" })
    end
  },
  {
    'kevinhwang91/nvim-bqf',
  },
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    config = setup_toggleterm,
  }
}
