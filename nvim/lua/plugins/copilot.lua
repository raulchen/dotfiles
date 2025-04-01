local copilot_keys = {
  {
    "<leader>as",
    function() require("copilot.suggestion").toggle_auto_trigger() end,
    desc = "Copilot: Toggle auto suggestion",
  },
}

local copilot_opts = {
  copilot_model = "gpt-4o-copilot",
  suggestion = {
    keymap = {
      accept = false,
      next = "<c-s>",
      prev = "<c-s-s>",
      accept_line = "<c-e>",
    },
  },
  filetypes = {
    gitcommit = true,
  }
}



return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    keys = copilot_keys,
    opts = copilot_opts,
  },

  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    opts = {
      provider = "copilot",
      -- auto_suggestions_provider = "copilot",
      file_selector = {
        provider = "snacks",
      },
      copilot = {
        model = "claude-3.7-sonnet",
      },
      windows = {
        width = 40,
        sidebar_header = {
          rounded = false,
        },
        ask = {
          start_insert = false,
        },
      },
      hints = {
        enabled = false,
      },
    },
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua",
    },
  },
}
