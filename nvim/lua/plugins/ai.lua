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

local transcript = require("util.agent_transcript")

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
        layout = "bottom",
        float = {
          border = "single",
          width = 0.95,
          height = 0.95,
        },
        wo = {
          winfixwidth = false,
          winfixheight = false,
        },
        split = {
          width = 0, -- 0 = default split width (right/left layout)
          height = 0.8, -- 80% high for bottom/top layout
        },
        keys = {
          buffers = { "<c-]><c-b>", "buffers", mode = "nt", desc = "open buffer picker" },
          files = { "<c-]><c-f>", "files", mode = "nt", desc = "open file picker" },
          prompt = { "<c-]><c-p>", "prompt", mode = "nt", desc = "insert prompt or context" },
          hide_ctrl_q = false, -- Disable hiding the terminal with Ctrl-Q in normal mode.
          hide_ctrl_z = false, -- Disable moving focus away from the terminal with Ctrl-Z.
          stopinsert = false, -- Disable entering terminal-normal mode with Ctrl-Q.
          nav_left = false, -- Disable navigating to the left window with Ctrl-H.
          nav_right = false, -- Disable navigating to the right window with Ctrl-L.
          nav_up = false, -- Disable navigating to the window above with Ctrl-K.
          nav_down = false, -- Disable navigating to the window below with Ctrl-J.
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
          -- A bare shell, opened manually when a second CLI is needed in a dir
          -- that already has a managed session (sidekick allows one per tool+dir).
          --
          -- cmd: `exec -a` starts a normal interactive zsh, but names it
          -- "zsh-sidekick" in `ps`. Keep the "zsh" prefix: with any other argv0,
          -- zsh starts in sh emulation and skips .zshrc.
          --
          -- is_proc: how sidekick re-finds this pane after nvim restarts. Without
          -- it the pane matches whatever AI tool runs inside (e.g. claude), whose
          -- sid won't equal the tmux session name (zsh-<hash>-<dir>), so sidekick
          -- flags the session "external" and never opens a window.
          --
          -- Match argv0 rather than a marker env var: sidekick runs is_proc on
          -- every process in every tmux pane, and reading a process env forks
          -- `ps` each time, while argv is already in its process snapshot.
          cmd = { "zsh", "-c", "exec -a zsh-sidekick zsh" },
          is_proc = "^zsh-sidekick$",
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
      "<c-]><c-h>",
      transcript.open,
      mode = { "n", "t" },
      ft = "sidekick_terminal",
      desc = "Open agent transcript snapshot",
    },
    {
      "<c-]><c-v>",
      function()
        local State = require("sidekick.cli.state")
        local states = State.get({ terminal = true })
        for _, state in ipairs(states) do
          if state.terminal then
            local opts = state.terminal.opts
            opts.layout = ({ bottom = "right", right = "float", float = "bottom" })[opts.layout] or "bottom"
            if state.terminal:is_open() then
              state.terminal:hide()
              state.terminal:show()
              state.terminal:focus()
              vim.schedule(vim.cmd.startinsert)
            end
          end
        end
      end,
      mode = { "n", "t" },
      ft = "sidekick_terminal",
      desc = "Cycle sidekick layout: bottom/right/float",
    },
  },
  config = function(_, opts)
    require("sidekick").setup(opts)

    -- Prefix tmux session names with the cwd basename for readability.
    -- The hash is kept so distinct dirs sharing a basename don't collide,
    -- and the override stays deterministic so re-attach matching still works.
    --
    -- PLUGIN-PATCH(sidekick.nvim): overrides internal Session.sid.
    local Session = require("sidekick.cli.session")
    local orig_sid = Session.sid
    function Session.sid(o)
      -- orig_sid returns "<tool> <hash>"; reshape to "<tool>-<hash>-<dir>".
      -- tmux disallows "." and ":" in session names.
      local sid = orig_sid(o):gsub(" ", "-")
      local dir = vim.fn.fnamemodify(Session.cwd(o), ":t"):gsub("[.:]", "_")
      return ("%s-%s"):format(sid, dir)
    end

    -- Send absolute paths in every location context ({file}, {line}, {this},
    -- {position}, {buffers}, diagnostics, quickfix, ...).
    --
    -- They all go through Loc.get, which makes the path relative to ctx.cwd.
    -- Setting cwd to the file itself makes relpath return ".", which Loc.get
    -- treats as "keep the name as is".
    --
    -- PLUGIN-PATCH(sidekick.nvim): overrides internal Loc.get. Drop once
    -- folke/sidekick.nvim#293 (cli.absolute_paths option) is merged.
    local Loc = require("sidekick.cli.context.location")
    local orig_loc_get = Loc.get
    function Loc.get(ctx, loc_opts)
      local name = ctx.name or (ctx.buf and vim.api.nvim_buf_get_name(ctx.buf))
      if name and name ~= "" then
        name = vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
        ctx = vim.tbl_extend("force", ctx, { name = name, cwd = name })
      end
      return orig_loc_get(ctx, loc_opts)
    end

    -- Refocus the CLI window in the mode it was left in, and in normal mode
    -- also at the same scrollback position.
    --
    -- Normal mode shows a scrollback snapshot buffer, which sidekick wipes
    -- on hide and rebuilds (scrolled to the bottom) on the next open. Hide
    -- now keeps that buffer and its view, and focus puts both back.
    -- Terminal:focus() always enters terminal mode; :stopinsert cancels that.
    --
    -- PLUGIN-PATCH(sidekick.nvim): overrides internal Terminal:hide and
    -- Terminal:focus.
    local Terminal = require("sidekick.cli.terminal")

    local orig_hide = Terminal.hide
    function Terminal:hide()
      local sb = self.scrollback
      -- close() also calls hide(), after setting self.closed: don't keep
      -- anything for a terminal that is going away.
      if sb and sb:is_open() and not self.closed then
        vim.bo[sb.buf].bufhidden = "hide"
        self.kept_scrollback = {
          buf = sb.buf,
          view = vim.api.nvim_win_call(self.win, vim.fn.winsaveview),
        }
      end
      return orig_hide(self)
    end

    local orig_focus = Terminal.focus
    function Terminal:focus()
      local normal_mode = self.normal_mode
      local kept = self.kept_scrollback
      self.kept_scrollback = nil
      orig_focus(self)

      local restore = kept and vim.api.nvim_buf_is_valid(kept.buf)
      if normal_mode and self:is_focused() then
        vim.cmd.stopinsert()
        self.normal_mode = true
        if restore then
          vim.api.nvim_win_set_buf(self.win, kept.buf)
          vim.fn.winrestview(kept.view)
          vim.bo[kept.buf].bufhidden = "wipe"
          return self
        end
      end
      if restore then
        -- Not going back to normal mode: drop the kept snapshot. Deleting it
        -- fires TermClose, which sets scrollback.term_buf; clear that, or the
        -- scrollback's WinEnter check would force terminal mode later.
        vim.api.nvim_buf_delete(kept.buf, { force = true })
        if self.scrollback then
          self.scrollback.term_buf = nil
        end
      end
      return self
    end

    -- Sidekick renders normal mode in a temporary scrollback terminal. Copy
    -- the live terminal's title when that buffer opens.
    --
    -- PLUGIN-PATCH(sidekick.nvim): drop once the scrollback terminal keeps
    -- the live terminal's title.
    local title_group = vim.api.nvim_create_augroup("SidekickTerminalTitle", { clear = true })
    vim.api.nvim_create_autocmd("TermOpen", {
      group = title_group,
      callback = function(event)
        local win = vim.fn.bufwinid(event.buf)
        local session_id = win ~= -1 and vim.w[win].sidekick_session_id
        local terminal = session_id and require("sidekick.cli.terminal").get(session_id)
        if terminal and terminal.scrollback and terminal.scrollback.buf == event.buf
            and vim.api.nvim_buf_is_valid(terminal.buf) then
          vim.b[event.buf].term_title = vim.b[terminal.buf].term_title
        end
      end,
    })

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
