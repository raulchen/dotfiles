return {
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "Shatur/neovim-session-manager",
    config = function()
      local config = require('session_manager.config')
      local session_manager = require("session_manager")
      session_manager.setup({
        autoload_mode = config.AutoloadMode.Disabled,
        autosave_ignore_dirs = { "~" },
      })
      local keymap = vim.keymap.set
      keymap('n', '<leader>sl', function() session_manager.load_current_dir_session() end, { desc = "Load CWD session" })
      keymap('n', '<leader>sL', function() session_manager.load_session() end, { desc = "Load session" })
      keymap('n', '<leader>sr', function() session_manager.load_last_session() end, { desc = "Load most recent session" })
      keymap('n', '<leader>sd', function() session_manager.delete_current_dir__session() end,
        { desc = "Delete CWD session" })
      keymap('n', '<leader>sD', function() session_manager.delete_session() end, { desc = "Delete session" })
    end,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  }
}
