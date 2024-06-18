local copilot_keys = {
  {
    "<leader>as",
    function() require("copilot.suggestion").toggle_auto_trigger() end,
    desc = "Copilot: Toggle auto suggestion",
  },
}

local copilot_opts = {
  suggestion = {
    keymap = {
      accept = false,
      next = "<c-s>",
      prev = false,
    },
  },
  filetypes = {
    gitcommit = true,
  }
}

local copilot_chat_keys = {
  {
    "<leader>aa",
    function()
      local input = vim.fn.input("Ask AI: ")
      if input ~= "" then
        require("CopilotChat").ask(input)
      end
    end,
    desc = "CopilotChat: Ask AI",
    mode = { "n", "x" },
  },
  {
    "<leader>aw",
    "<cmd>CopilotChatToggle<cr>",
    desc = "CopilotChat: Toggle chat window.",
    mode = { "n", "x" },
  },
  {
    "<leader>ad",
    function()
      local actions = require("CopilotChat.actions").help_actions()
      if actions == nil then
        vim.notify("No help actions found.", "warn")
      else
        require("CopilotChat.integrations.fzflua").pick(actions)
      end
    end,
    desc = "CopilotChat: Diagnostic help actions",
    mode = { "n", "x" },
  },
  {
    "<leader>ap",
    function()
      local actions = require("CopilotChat.actions").prompt_actions()
      require("CopilotChat.integrations.fzflua").pick(actions)
    end,
    desc = "CopilotChat: Prompt actions",
    mode = { "n", "x" },
  },
}

local function setup_copilot_chat()
  local opts = {
    context = "buffer",
    mappings = {
      close = {
        insert = '', -- disable <ctrl-c> to close window
      },
      reset = {      -- disable <c-l> to reset chat.
        normal = '',
        insert = ''
      },
    },
    prompts = {
      BetterNamings = "Please provide better names for the following variables and functions.",
      Summarize = "Please summarize the following text.",
      Spelling = "Please correct any grammar and spelling errors in the following text.",
      Wording = "Please improve the grammar and wording of the following text.",
      Concise = "Please rewrite the following text to make it more concise.",
    },
  }
  require("CopilotChat").setup(opts)
end

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
    keys = copilot_chat_keys,
    config = setup_copilot_chat,
  },
}
