local session_manaer_keys = {
  { "<leader>sl", function() require("session_manager").load_current_dir_session() end, desc = "Load CWD session" },
  { "<leader>sL", function() require("session_manager").load_session(false) end, desc = "Load session" },
  { "<leader>sr", function() require("session_manager").load_last_session() end, desc = "Load most recent session" },
  { "<leader>sd", function() require("session_manager").delete_current_dir_session() end, desc = "Delete CWD session" },
  { "<leader>sD", function() require("session_manager").delete_session() end, desc = "Delete session" },
}

local function session_manager_opts()
  local config = require('session_manager.config')
  return {
    autoload_mode = config.AutoloadMode.Disabled,
    autosave_ignore_dirs = { "~" },
  }
end

return {
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "Shatur/neovim-session-manager",
    event = "VeryLazy",
    commands = { "SessionManager" },
    keys = session_manaer_keys,
    opts = session_manager_opts,
  },
}
