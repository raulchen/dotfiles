local vim_tmux_navigator = {
  "christoomey/vim-tmux-navigator",
  keys = {
    { "<C-M-H>", "<cmd>TmuxNavigateLeft<cr>", mode = { "n", "t", "i" }, desc = "TmuxNavigateLeft" },
    { "<C-M-J>", "<cmd>TmuxNavigateDown<cr>", mode = { "n", "t", "i" }, desc = "TmuxNavigateDown" },
    { "<C-M-K>", "<cmd>TmuxNavigateUp<cr>", mode = { "n", "t", "i" }, desc = "TmuxNavigateUp" },
    { "<C-M-L>", "<cmd>TmuxNavigateRight<cr>", mode = { "n", "t", "i" }, desc = "TmuxNavigateRight" },
    { "<C-M-\\>", "<cmd>TmuxNavigatePrevious<cr>", mode = { "n", "t", "i" }, desc = "TmuxNavigatePrevious" },
  },
  init = function()
    vim.cmd([[
        let g:tmux_navigator_no_mappings = 1
      ]])
  end,
}

local vim_sleuth = {
  "tpope/vim-sleuth",
  event = "VeryLazy",
}

local vim_oscyank = {
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
}

local which_key = {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
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
  end,
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "List buffer local keymaps",
    },
  },
}

local flash = {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {},
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
}

local mini_cursorword = {
  'echasnovski/mini.cursorword',
  version = '*',
  event = "VeryLazy",
  opts = {},
}

local mini_splitjoin = {
  'echasnovski/mini.splitjoin',
  version = '*',
  event = "VeryLazy",
  opts = {},
}

local mini_surround = {
  "echasnovski/mini.surround",
  version = "*",
  event = "VeryLazy",
  opts = {
    mappings = {
      add = "gsa", -- Add surrounding in Normal and Visual modes
      delete = "gsd", -- Delete surrounding
      find = "gsf", -- Find surrounding (to the right)
      find_left = "gsF", -- Find surrounding (to the left)
      highlight = "gsh", -- Highlight surrounding
      replace = "gsr", -- Replace surrounding
      update_n_lines = "gsn", -- Update `n_lines`
    },
  },
  keys = {
    { "gs", "", desc = "+surround" },
  }
}

local mini_ai = {
  "echasnovski/mini.ai",
  version = "*",
  event = "VeryLazy",
  opts = function()
    local ai = require("mini.ai")
    return {
      n_lines = 500,
      custom_textobjects = {
        o = ai.gen_spec.treesitter({ -- code block
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }),
        f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
        c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
        t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
        d = { "%f[%d]%d+" }, -- digits
        e = { -- Word with case
          {
            "%u[%l%d]+%f[^%l%d]",
            "%f[%S][%l%d]+%f[^%l%d]",
            "%f[%P][%l%d]+%f[^%l%d]",
            "^[%l%d]+%f[^%l%d]",
          },
          "^().*()$",
        },
        g = function() -- Whole buffer, similar to `gg` and 'G' motion
          local from = { line = 1, col = 1 }
          local to = {
            line = vim.fn.line("$"),
            col = math.max(vim.fn.getline("$"):len(), 1),
          }
          return { from = from, to = to }
        end,
        u = ai.gen_spec.function_call(), -- u for "Usage"
        U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
      },
    }
  end,
  config = function(_, opts)
    require("mini.ai").setup(opts)
  end,
}

return {
  vim_tmux_navigator,
  vim_sleuth,
  vim_oscyank,
  which_key,
  flash,
  mini_cursorword,
  mini_splitjoin,
  mini_surround,
  mini_ai,
}
