local copilot_keys = {
  {
    "<leader>cc",
    function() require("copilot.suggestion").toggle_auto_trigger() end,
    desc = "Toggle Copilot auto trigger",
  },
}

local copilot_opts = {
  suggestion = {
    keymap = {
      accept = false,
      next = "<c-_>",
      prev = false,
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
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    opts = {},
  },
}
