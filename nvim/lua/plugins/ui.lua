local function setup_nvimtree(_, _)
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  vim.keymap.set("n", "<leader>n", "<cmd>NvimTreeFindFileToggle!<cr>", { noremap = true, desc = "Toggle nvim-tree" })
  require("nvim-tree").setup()
end

local function setup_whichkey(_, _)
  local wk = require("which-key")
  wk.setup()
  wk.register({
    b = { name = "code" },
    c = { name = "code" },
    d = { name = "debug" },
    f = { name = "find" },
    g = { name = "git" },
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
local function setup_indent_blankline(_, _)
  require("ibl").setup {
    indent = { char = "▏" },
    scope = { enabled = true },
  }
end

local function setup_neozoom()
  require("neo-zoom").setup()
  vim.keymap.set('n', '<c-w>z', function() vim.cmd('NeoZoomToggle') end, { desc = "Toggle zoom" })
  vim.keymap.set('n', '<leader>uz', function() vim.cmd('NeoZoomToggle') end, { desc = "Toggle zoom" })
end

return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = setup_nvimtree,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    config = setup_indent_blankline,
  },
  {
    "folke/which-key.nvim",
    config = setup_whichkey,
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
    config = setup_neozoom,
  },
  {
    'kevinhwang91/nvim-bqf',
    opts = {
      preview = {
        -- Do not make the preview window transparent.
        winblend = 0,
      },
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
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    config = function(_, _)
      local color = require("onedarkpro.helpers")
      local colors = {
        red     = '#ff5c57',
        green   = '#5af78e',
        yellow  = '#f3f99d',
        blue    = '#57c7ff',
        magenta = '#ff6ac1',
        cyan    = '#9aedfe',
        purple  = color.lighten("purple", 15, "onedark"),
        orange  = color.brighten("orange", 15, "onedark"),
        comment = color.lighten("comment", 5, "onedark"),
        fg      = color.brighten("fg", 5, "onedark"),
        light_red = color.lighten("red", 15, "onedark"),
      }

      local highlights = {
        Identifier = { fg = "${cyan}", extend = true },
        ["@variable"] = { link = "Identifier" },
        ["@variable.parameter"] = { link = "Identifier" },
        ["@variable.member"] = { link = "Identifier" },
        ["@odp.interpolation.python"] = { link = "Identifier" }, -- Variables in f-strings.
        ["@property"] = { fg = "${cyan}", extend = true },
        String = { fg = "${yellow}", extend = true },
        pythonString = { link = "String", extend = true },
        Character = { fg = "${yellow}", extend = true },
        ["@string"] = { fg = "${yellow}", extend = true },
        Constant = { fg = "${green}", extend = true },
        ["@constant"] = { fg = "${green}", extend = true },
        ["@constant.builtin"] = { link = "Constant" },
        SpellBad = { undercurl = true, sp = "${red}" },
        DiagnosticUnderlineError = { undercurl = true, sp = "${red}" },
      }

      local styles = {
        comments = "italic",
      }

      require("onedarkpro").setup({
        colors = colors,
        highlights = highlights,
        styles = styles,
        options = {
          cursorline = true,
          highlight_inactive_windows = false,
        }
      })
      vim.cmd [[colorscheme onedark]]
    end,
  },
}
