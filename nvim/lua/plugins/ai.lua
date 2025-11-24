local copilot_keys = {
  {
    "<leader>ac",
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

local copilot = {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  keys = copilot_keys,
  opts = copilot_opts,
}

if os.getenv("NVIM_DEV") == "0" then
  return {}
end

local use_copilot = os.getenv("NVIM_USE_COPILOT") ~= "0"
if not use_copilot then
  return {}
end

return { copilot }
