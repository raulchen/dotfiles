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

local claude_code = {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude: Toggle window" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Claude: Continue last conversation" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: Send selection" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Claude: Add file",
      ft = { "oil" },
    },
  },
  opts = {
    terminal = {
      split_width_percentage = 0.4,
    }
  },
}

if os.getenv("NVIM_DEV") == "0" then
  return {}
end

local use_copilot = os.getenv("NVIM_USE_COPILOT") ~= "0"
if not use_copilot then
  return {}
end

return {
  copilot,
  claude_code,
  copilot_accept = copilot_accept,
}
