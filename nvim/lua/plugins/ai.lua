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

local function jump_to_prompt(direction)
  -- Match prompt patterns: "❯ " (claude), "› " (codex), " ┌────" (cursor)
  -- \v enables "very magic" mode where special regex chars don't need escaping
  local pattern = "\\v^(❯ |› | ┌────)"
  local count = vim.v.count1
  -- the upper case 'W' disables wrapping around the file
  local flags = direction == "next" and "W" or "bW"
  for _ = 1, count do
    vim.fn.search(pattern, flags)
  end
end

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
        float = {
          border = "rounded",
          width = 0.9,
          height = 0.9,
        },
        split = {
          width = 0, -- set to 0 for default split width
          height = 0, -- set to 0 for default split height
        },
        keys = {
          buffers = { "<c-\\><c-b>", "buffers", mode = "nt", desc = "open buffer picker" },
          files = { "<c-\\><c-f>", "files", mode = "nt", desc = "open file picker" },
          prompt = { "<c-\\><c-p>", "prompt", mode = "nt", desc = "insert prompt or context" },
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
          },
          send_selection = {
            "<leader>av",
            function()
              -- Get visual selection boundaries
              local mode = vim.fn.mode()
              local start_pos = vim.fn.getpos("v") -- where visual selection started
              local end_pos = vim.fn.getpos(".") -- current cursor position
              local lines = vim.fn.getregion(start_pos, end_pos, { type = mode })
              -- Exit visual mode
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
              -- Send selection to CLI
              require("sidekick.cli").send({ msg = table.concat(lines, "\n") })
            end,
            mode = "x",
            desc = "Send visual selection",
          },
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
      "<leader>al",
      function() require("sidekick.cli").send({ msg = "{line}" }) end,
      mode = { "n", "x" },
      desc = "Send Line(s)",
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
    {
      "<leader>aP",
      function()
        local tools = require("sidekick.config").cli.tools
        local tool_flags = {
          claude = { cmd = { "claude" }, flag = "--dangerously-skip-permissions" },
          codex = { cmd = { "codex" }, flag = "--full-auto" },
          ["cursor-agent"] = { cmd = { "cursor-agent" }, flag = "--force" },
        }
        local states = {}
        for name, cfg in pairs(tool_flags) do
          tools[name] = tools[name] or {}
          local enabled = vim.tbl_contains(tools[name].cmd or {}, cfg.flag)
          if enabled then
            tools[name].cmd = cfg.cmd
          else
            tools[name].cmd = vim.list_extend(vim.deepcopy(cfg.cmd), { cfg.flag })
          end
          states[name] = not enabled
        end
        local status = vim.iter(states):map(function(k, v) return k .. ":" .. (v and "ON" or "OFF") end):totable()
        vim.notify("Skip permissions: " .. table.concat(status, ", "))
      end,
      desc = "Toggle CLI skip permissions",
    },
    {
      "<leader>aL",
      function()
        local State = require("sidekick.cli.state")
        local states = State.get({ terminal = true })
        for _, state in ipairs(states) do
          if state.terminal then
            local opts = state.terminal.opts
            opts.layout = opts.layout == "float" and "right" or "float"
            if state.terminal:is_open() then
              state.terminal:hide()
              state.terminal:show()
              state.terminal:focus()
            end
          end
        end
      end,
      desc = "Toggle sidekick float layout",
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

    -- Map [[ ]] for jumping between prompts in sidekick terminal buffers
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "sidekick_terminal",
      callback = function(event)
        -- Defer to ensure we override the default keymaps
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(event.buf) then return end
          vim.keymap.set("n", "]]", function() jump_to_prompt("next") end, {
            buffer = event.buf,
            noremap = true,
            desc = "Jump to next prompt",
          })
          vim.keymap.set("n", "[[", function() jump_to_prompt("prev") end, {
            buffer = event.buf,
            noremap = true,
            desc = "Jump to previous prompt",
          })
        end)
      end,
    })
  end,
}

if os.getenv("NVIM_DEV") == "0" then
  return {}
end

local use_copilot = os.getenv("NVIM_USE_COPILOT") ~= "0"
if not use_copilot then
  return {
    sidekick,
  }
else
  return {
    copilot,
    sidekick,
  }
end
