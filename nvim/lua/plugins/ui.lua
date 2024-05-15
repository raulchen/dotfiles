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

local function setup_alpha()
  local alpha = require("alpha")
  local startify = require("alpha.themes.startify")
  local fzf = require("plugins.fzf")

  startify.section.top_buttons.val = {
    startify.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
    ---@diagnostic disable-next-line: param-type-mismatch
    startify.button("f", "󰈞  Find files", fzf.fzf_files),
    ---@diagnostic disable-next-line: param-type-mismatch
    startify.button("h", "󰋚  Find current dir file history", fzf.fzf_oldfiles),
    startify.button("s", "  Restore current dir session", "<cmd>SessionManager load_current_dir_session<CR>"),
    startify.button("q", "󰅚  Quit Neovim", ":qa<CR>"),
  }
  startify.section.bottom_buttons.val = {}
  alpha.setup(startify.opts)
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
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        override = {
          -- override the default lsp markdown formatter with Noice
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          -- override the lsp markdown formatter with Noice
          ["vim.lsp.util.stylize_markdown"] = true,
          -- override cmp documentation with Noice (requires nvim-cmp)
          ["cmp.entry.get_documentation"] = true,
        },
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "rcarriga/nvim-notify",
        opts = {
          stages = "fade",
        },
      }
    }
  },
  {
    'goolord/alpha-nvim',
    event = "VimEnter",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = setup_alpha,
  },
}
