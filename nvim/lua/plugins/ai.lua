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
      dismiss = "<c-e>",
    },
  },
  filetypes = {
    gitcommit = true,
  }
}

local function copilot_accept()
  if require("copilot.suggestion").is_visible() then
    require("copilot.suggestion").accept()
    return true
  else
    return false
  end
end

local copilot = {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  keys = copilot_keys,
  opts = copilot_opts,
}

local function save_copilot_chat(name)
  -- Save current chat
  require("CopilotChat").save(name)

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

local CHAT_TITLE_PROMPT = [[
Generate a short title (maximum 10 words) for the following chat.
Use a filepath-friendly format, replace all spaces with underscores.
Output only the title and nothing else in your response.

```
%s
```
]]

local function auto_save_copilot_chat(response, source)
  if vim.g.copilot_chat_title then
    save_copilot_chat(vim.g.copilot_chat_title)
  else
    -- use AI to generate chat title based on first AI response to user question
    require("CopilotChat").ask(vim.trim(CHAT_TITLE_PROMPT:format(response)), {
      callback = function(gen_response)
        vim.print("Generated chat title: " .. gen_response)
        -- Prefix the title with timestamp in format YYYYMMDD_HHMMSS
        local timestamp = os.date("%Y%m%d_%H%M%S")
        vim.g.copilot_chat_title = timestamp .. "_" .. vim.trim(gen_response)
        save_copilot_chat(vim.g.copilot_chat_title)
      end,
      -- disable updating chat buffer and history with this question
      headless = true,
    })
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
      local chat = require("CopilotChat")
      chat.load(item.text)
      chat.open()
      vim.g.copilot_chat_title = item.text
    end,
    preview = function(ctx)
      local file = io.open(ctx.item.file, "r")
      if not file then
        ctx.preview:set_lines({ "Unable to read file" })
        return
      end

      local content = file:read("*a")
      file:close()

      local ok, messages = pcall(vim.json.decode, content, {
        luanil = {
          object = true,
          array = true,
        },
      })

      if not ok then
        ctx.preview:set_lines({ "vim.fn.json_decode error" })
        return
      end

      local config = require("CopilotChat.config")
      local preview = { ctx.item.text, "", }
      for _, message in ipairs(messages or {}) do
        local header = message.role == "user" and config.question_header or config.answer_header
        table.insert(preview, header .. config.separator .. "\n")
        table.insert(preview, message.content .. "\n")
      end

      ctx.preview:highlight({ ft = "copilot-chat" })
      ctx.preview:set_lines(preview)
    end,
  })
end

local copilot_chat_keys = {
  { "<c-s>", "<CR>", ft = "copilot-chat", desc = "Submit prompt", remap = true },
  {
    "<leader>aa",
    function()
      -- If not in visual mode, clear the marks.
      -- So the chat selection will be empty.
      local mode = vim.api.nvim_get_mode().mode
      if not (mode:sub(1, 1) == "v" or mode:sub(1, 1) == "V" or mode == "\22") then
        local bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_mark(bufnr, '<', 0, 0, {})
        vim.api.nvim_buf_set_mark(bufnr, '>', 0, 0, {})
      end
      -- Toggle CopilotChat
      local chat = require("CopilotChat")
      chat.toggle()
    end,
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
      vim.g.copilot_chat_title = nil
      return require("CopilotChat").reset()
    end,
    desc = "CopilotChat: Reset",
    mode = { "n", "v" },
  },
  {
    "<leader>ap",
    function()
      require("CopilotChat").select_prompt()
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
  {
    "<c-c>",
    function()
      require("CopilotChat").stop()
    end,
    desc = "CopilotChat: stop",
    ft = "copilot-chat",
  },
}

local function setup_copilot_chat()
  require("CopilotChat").setup({
    model = "claude-3.7-sonnet-thought",
    question_header = "  User ",
    answer_header = "  Copilot ",
    error_header = "   Error ",
    selection = require("CopilotChat.select").visual,
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
    callback = auto_save_copilot_chat,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "copilot-chat",
    callback = function()
      vim.opt_local.relativenumber = false
      vim.opt_local.number = false
    end,
  })
end


local copilot_chat = {
  "CopilotC-Nvim/CopilotChat.nvim",
  version = "*",
  keys = copilot_chat_keys,
  cmd = {
    "CopilotChat",
  },
  config = setup_copilot_chat,
}

local avante = {
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
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua",
  },
}

local code_companion = {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    strategies = {
      chat = {
        keymaps = {
          send = {
            modes = { n = { "<C-s>", "<CR>" }, i = "<C-s>" },
            opts = {},
          },
          close = {
            modes = { n = "<f13>", i = "<f13>" },
            opts = {},
          },
        },
      },
    },
  },
  keys = {
    {
      "<leader>aa",
      function()
        require("codecompanion").toggle()
      end,
      desc = "CodeCompanion: Toggle chat",
      mode = { "n", "x" },
    },
    {
      "<leader>ai",
      function()
        vim.api.nvim_feedkeys(":CodeCompanion ", "n", false)
      end,
      desc = "CodeCompanion: inline assistant",
      mode = { "x" },
    }
  },
  cmd = {
    "CodeCompanion",
    "CodeCompanionActions",
    "CodeCompanionChat",
    "CodeCompanionCmd",
  },
}

local use_copilot = os.getenv("NVIM_USE_COPILOT") ~= "0"
if not use_copilot then
  return {}
end

local use_code_companion = os.getenv("NVIM_USE_CODE_COMPANION") ~= "0"
local use_avante = os.getenv("NVIM_USE_AVANTE") ~= "0"

if use_code_companion then
  return {
    copilot,
    code_companion,
    copilot_accept = copilot_accept,
  }
elseif use_avante then
  return {
    copilot,
    avante,
    copilot_accept = copilot_accept,
  }
else
  return {
    copilot,
    copilot_chat,
    copilot_accept = copilot_accept,
  }
end
