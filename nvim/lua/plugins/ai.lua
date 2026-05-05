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
  keys = copilot_keys,
  opts = copilot_opts,
}

local function jump_to_prompt(direction)
  -- Match prompt patterns: "❯ " (claude), "› " (codex), " ┌────" (cursor), " >" (gemini)
  local pattern = [[^\(❯ \|› \| ┌────\| >\)]]
  local count = vim.v.count1
  -- the upper case 'W' disables wrapping around the file
  local flags = direction == "next" and "W" or "bW"
  for _ = 1, count do
    vim.fn.search(pattern, flags)
  end
end

local function select_prompt()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local items = {}
  for i, line in ipairs(lines) do
    local text
    if line:find("^❯ ") then
      text = line:sub(#"❯ " + 1)
    elseif line:find("^› ") then
      text = line:sub(#"› " + 1)
    elseif line:find("^ ┌────") then
      -- cursor: prompt content lives inside the box on the following line
      local next_line = lines[i + 1] or ""
      text = next_line:gsub("^[%s│]+", ""):gsub("[%s│]+$", "")
    elseif line:find("^ >") then
      text = line:sub(3):gsub("^%s+", "")
    end
    if text then
      table.insert(items, 1, {
        buf = buf,
        text = text == "" and "(empty)" or text,
        pos = { i, 0 },
      })
    end
  end

  if #items == 0 then
    vim.notify("No prompts found", vim.log.levels.INFO)
    return
  end

  Snacks.picker.pick({
    source = "prompts",
    items = items,
    format = function(item)
      local lnum = string.format("%4d", item.pos[1])
      return {
        { lnum, "SnacksPickerIdx" },
        { "  " },
        { item.text },
      }
    end,
    layout = { preset = "default" },
    jump = { match = true },
    sort = { fields = { "score:desc", "idx" } },
  })
end

local sidekick = {
  "folke/sidekick.nvim",
  opts = {
    nes = {
      enabled = false,
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
          buffers = { "<c-]><c-b>", "buffers", mode = "nt", desc = "open buffer picker" },
          files = { "<c-]><c-f>", "files", mode = "nt", desc = "open file picker" },
          prompt = { "<c-]><c-p>", "prompt", mode = "nt", desc = "insert prompt or context" },
          hide_ctrl_z = false,
          nav_left = false,
          nav_right = false,
          nav_up = false,
          nav_down = false,
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
      tools = {
        zsh = {
          cmd = { "zsh" },
        },
        claude = {
          cmd = { "claude", "--allow-dangerously-skip-permissions" },
        },
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
      "<leader>aj",
      select_prompt,
      ft = "sidekick_terminal",
      desc = "Jump to prompt",
    },
    {
      "<c-]><c-j>",
      function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
        vim.schedule(select_prompt)
      end,
      mode = "t",
      ft = "sidekick_terminal",
      desc = "Jump to prompt",
    },
    {
      "<c-]><c-v>",
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
              vim.schedule(vim.cmd.startinsert)
            end
          end
        end
      end,
      mode = "t",
      ft = "sidekick_terminal",
      desc = "Toggle sidekick layout views",
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

return {
  copilot,
  sidekick,
}
