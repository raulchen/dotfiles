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
      prev = "<c-s-s>",
      accept_line = "<c-e>",
    },
  },
  filetypes = {
    gitcommit = true,
  }
}

local copilot_chat_keys = {
  { "<c-s>", "<CR>", ft = "copilot-chat", desc = "Submit prompt", remap = true },
  {
    "<leader>aa",
    "<cmd>CopilotChatToggle<cr>",
    desc = "CopilotChat: Toggle chat window",
    mode = { "n", "x" },
  },
  {
    "<leader>aq",
    function()
      vim.ui.input({ prompt = "Ask AI: " }, function(input)
        if input ~= nil and input ~= "" then
          require("CopilotChat").ask(input)
        end
      end)
    end,
    desc = "CopilotChat: Quick chat",
    mode = { "n", "x" },
  },
  {
    "<leader>ax",
    function()
      return require("CopilotChat").reset()
    end,
    desc = "CopilotChat: Reset",
    mode = { "n", "v" },
  },
  {
    "<leader>ap",
    function()
      local actions = require("CopilotChat.actions")
      require("CopilotChat.integrations.snacks").pick(actions.prompt_actions())
    end,
    desc = "CopilotChat: Prompt actions",
    mode = { "n", "x" },
  },
}

local function setup_copilot_chat()
  local opts = {
    model = "claude-3.5-sonnet",
    question_header = "  User ",
    answer_header = "  Copilot ",
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

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "copilot-chat",
    callback = function()
      vim.opt_local.relativenumber = false
      vim.opt_local.number = false
    end,
  })
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
    version = "*",
    keys = copilot_chat_keys,
    cmd = {
      "CopilotChat",
    },
    config = setup_copilot_chat,
  },
}
