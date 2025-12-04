local copilot_keys = {
  {
    "<leader>ac",
    function() require("copilot.suggestion").toggle_auto_trigger() end,
    desc = "Copilot: Toggle auto suggestion",
  },
}

local copilot_opts = {
  suggestion = {
    -- keymaps are managed by blink
    keymap = {
      accept = false,
      next = false,
      prev = false,
      dismiss = false,
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

local sidekick = {
  "folke/sidekick.nvim",
  opts = {
    nes = {
      diff = {
        inline = false,
      },
    },
    cli = {
      win = {
        split = {
          width = 0,  -- set to 0 for default split width
          height = 0, -- set to 0 for default split height
        },
        keys = {
          buffers = { "<leader>ab", "buffers", mode = "n", desc = "open buffer picker" },
          files = { "<leader>af", "files", mode = "n", desc = "open file picker" },
          prompt = { "<leader>ap", "prompt", mode = "n", desc = "insert prompt or context" },
          hide_ctrl_z = false,
          nav_left = false,
          nav_right = false,
          nav_up = false,
          nav_down = false,
          disable_ctrl_c = {
            "<c-c>",
            "",
            mode = { "n", "i", "t", "x" },
            desc = "Disable Ctrl-C to prevent accidental exits",
          }
        },
      },
      mux = {
        backend = "tmux",
        enabled = true,
      },
    },
  },
  keys = {
    {
      "<leader>an",
      function()
        local nes = require("sidekick.nes")
        if not nes.have() then
          nes.update()
        else
          require("sidekick").nes_jump_or_apply()
        end
      end,
      expr = true,
      desc = "Request/Goto/Apply Next Edit Suggestion",
    },
    {
      "<c-.>",
      function() require("sidekick.cli").toggle() end,
      desc = "Sidekick Toggle",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>aa",
      function() require("sidekick.cli").toggle() end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function() require("sidekick.cli").select() end,
      -- Or to select only installed tools:
      -- require("sidekick.cli").select({ filter = { installed = true } })
      desc = "Select CLI",
    },
    {
      "<leader>ad",
      function() require("sidekick.cli").close() end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>at",
      function() require("sidekick.cli").send({ msg = "{this}" }) end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function() require("sidekick.cli").send({ msg = "{file}" }) end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function() require("sidekick.cli").send({ msg = "{selection}" }) end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function() require("sidekick.cli").prompt() end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
  },
  config = function(_, opts)
    require("sidekick").setup(opts)
    Snacks.toggle({
      name = "Sidekick NES",
      get = function()
        return require("sidekick.nes").enabled
      end,
      set = function(state)
        require("sidekick.nes").enable(state)
      end,
    }):map("<leader>aN")
  end,
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
  sidekick,
}
