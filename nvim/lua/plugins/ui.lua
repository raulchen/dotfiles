local function setup_nvimtree(_, _)
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  require("nvim-tree").setup({
    view = {
      float = {
        enable = true,
        open_win_config = function()
          -- Leave some space below the floating window
          local height = math.min(40, vim.opt.lines:get()) - 5
          height = math.max(height, 1)
          return {
            relative = 'editor',
            border = 'rounded',
            width = 50,
            height = height,
            row = 1,
            col = 1,
          }
        end,
      },
    }
  })
end

local function setup_whichkey(_, _)
  local wk = require("which-key")
  wk.setup()
  wk.register({
    b = { name = "buffers" },
    c = {
      name = "code",
      g = { "goto" },
      p = { "prewview" },
      w = { "workspace" },
    },
    d = { name = "debug" },
    f = { name = "find" },
    g = { name = "git" },
    s = { name = "sessions" },
    t = { name = "tabs" },
    u = { name = "ui" },
    w = { name = "windows" },
  }, { prefix = "<leader>" })
end

local lualine_opts = {
  options = {
    section_separators = "",
    component_separators = "|",
  },
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
        "copilot",
        show_colors = true,
      },
      {
        "filetype",
      },
    },
  },
}

local function setup_indent_blankline(_, _)
  require("ibl").setup {
    indent = { char = "▏" },
    scope = { enabled = true },
  }
end

return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = setup_nvimtree,
    keys = {
      { "<leader>n", "<cmd>NvimTreeFindFileToggle!<cr>", desc = "Toggle nvim-tree" },
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = setup_indent_blankline,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = setup_whichkey,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      {
        -- Show current code context.
        "SmiteshP/nvim-navic",
        opts = {
          lsp = {
            auto_attach = true,
          },
        },
      },
      {
        'AndreM222/copilot-lualine',
      },
    },
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
    opts = {},
    keys = {
      { '<c-w>z', '<cmd>NeoZoomToggle<cr>', desc = "Toggle zoom" },
      { '<leader>wz', '<cmd>NeoZoomToggle<cr>', desc = "Toggle zoom" },
    },
  },
  {
    'simrat39/symbols-outline.nvim',
    opts = {},
    keys = {
      { '<leader>uo', '<cmd>SymbolsOutline<cr>', desc = "Toggle symbols outline" },
    },
    cmd = {
      'SymbolsOutline',
    },
  },
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    config = function(_, _)
      require("dressing").setup()
      -- Set Emacs-like keybindings for `vim.input`.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "DressingInput",
        callback = function()
          local keymap = function(lhs, rhs)
            vim.api.nvim_buf_set_keymap(0, 'i', lhs, rhs, { noremap = true, silent = true })
          end
          -- start of line
          keymap('<C-A>', '<Home>')
          -- back one character
          keymap('<C-B>', '<Left>')
          -- delete character under cursor
          keymap('<C-D>', '<Del>')
          -- end of line
          keymap('<C-E>', '<End>')
          -- forward one character
          keymap('<C-F>', '<Right>')
        end
      })
    end,
  },
}
