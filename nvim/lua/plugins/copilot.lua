return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  keys = {
    {
      "<leader>cc",
      function() require("copilot.suggestion").toggle_auto_trigger() end,
      desc = "Toggle Copilot auto trigger",
    },
  },
  opts = {
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
  },
}
