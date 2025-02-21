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

local function save_copilot_chat(name)
  -- Generate save name with timestamp if not provided
  local save_name = name
  if not save_name then
    local timestamp = os.date("%Y%m%d_%H%M%S")
    save_name = "chat_" .. timestamp
  end

  -- Save current chat
  vim.cmd("CopilotChatSave " .. save_name)

  -- Cleanup old saves
  local max_saves = 20
  local save_dir = vim.fn.stdpath("data") .. "/copilotchat_history/"

  local files = vim.fn.glob(save_dir .. "chat_*", false, true)
  table.sort(files, function(a, b)
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)

  -- Remove oldest files if exceeding max_saves
  for i = max_saves + 1, #files do
    vim.fn.delete(files[i])
  end
end

local function load_copilot_chat()
  require("snacks").picker({
    title = "Copilot: Load chat",
    finder = function()
      -- Get list of json files from the chat save directory
      local save_dir = vim.fn.stdpath("data") .. "/copilotchat_history"
      local files = vim.fn.glob(save_dir .. "/*.json", false, true)
      -- Sort files by modification time
      table.sort(files, function(a, b)
        return vim.fn.getftime(a) > vim.fn.getftime(b)
      end)

      local choices = {}
      for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        table.insert(choices, {
          text = name,
          file = file,
        })
      end
      return choices
    end,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      vim.cmd("CopilotChatLoad " .. item.text)
      vim.cmd("CopilotChatOpen")
    end,
  })
end

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
  {
    "<leader>aL",
    load_copilot_chat,
    desc = "CopilotChat: Load chat",
    ft = "copilot-chat",
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
    callback = function(response, source)
      -- Automatically save chat session on each response.
      local bufnr = source.bufnr
      local session_name
      local ok = pcall(function()
        session_name = vim.api.nvim_buf_get_var(bufnr, "copilot_chat_session_name")
      end)

      if not ok then
        local timestamp = os.date("%Y%m%d_%H%M%S")
        session_name = "chat_" .. timestamp
        vim.api.nvim_buf_set_var(bufnr, "copilot_chat_session_name", session_name)
      end
      save_copilot_chat(session_name)
    end,
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
