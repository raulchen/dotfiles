local function setup_neotree(_, opts)
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  vim.keymap.set("n", "<leader>n", "<cmd>Neotree toggle<cr>", { noremap = true, desc = "Toggle Neotree" })
  require("neo-tree").setup(opts)
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
    opts = {},
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
    opts = {
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
    },
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
}
