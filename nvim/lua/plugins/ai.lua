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
    main = { current = true },
    sort = { fields = { "score:desc", "idx" } },
  })
end

local function find_focused_terminal()
  local Terminal = require("sidekick.cli.terminal")
  local current_buf = vim.api.nvim_get_current_buf()
  for _, t in pairs(Terminal.sessions()) do
    if t.buf == current_buf or t:is_focused() then return t end
  end
end

-- Pick a non-float, non-excluded window: prefer the previous window,
-- then scan the tabpage.
local function find_borrow_win(exclude)
  local function suitable(w)
    return w and w > 0 and w ~= exclude
        and vim.api.nvim_win_get_config(w).relative == ""
  end
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if suitable(prev) then return prev end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if suitable(w) then return w end
  end
end

-- Per-terminal scrollback state, keyed by terminal id.
-- { buf = number, cursor = { lnum, col }, close = fun? }
-- `close` is non-nil only while the scrollback is currently open.
--
-- Why module-level: the buf survives close/reopen via bufhidden=hide, and its
-- buffer-local autocmds survive with it. The autocmds need shared state with
-- future open_scrollback invocations — a per-invocation local would orphan
-- the cursor inside the original closure scope.
local scrollbacks = {}

local function open_scrollback()
  -- Toggle: if invoked from inside an open scrollback buf, close it.
  local current_buf = vim.api.nvim_get_current_buf()
  for _, state in pairs(scrollbacks) do
    if state.close and state.buf == current_buf then
      state.close()
      return
    end
  end

  local terminal = find_focused_terminal()
  if not (terminal and terminal.parent and terminal.parent.dump) then
    vim.notify("No focused sidekick terminal with scrollback", vim.log.levels.WARN)
    return
  end

  -- Toggle: if this terminal's scrollback is open, close it.
  if scrollbacks[terminal.id] and scrollbacks[terminal.id].close then
    scrollbacks[terminal.id].close()
    return
  end

  local cache
  local function render_dump()
    local text = terminal.parent:dump()
    if not text or text == "" then return nil end
    text = text:gsub("\n$", "")
    local buf = vim.api.nvim_create_buf(true, true)
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].filetype = "sidekick_terminal"
    local tool = terminal.tool and terminal.tool.name or "sidekick"
    local name = ("Scrollback: %s"):format(tool)
    if not pcall(vim.api.nvim_buf_set_name, buf, name) then
      pcall(vim.api.nvim_buf_set_name, buf, ("%s #%d"):format(name, buf))
    end
    vim.api.nvim_chan_send(vim.api.nvim_open_term(buf, {}), text)
    -- HACK: force a refresh of the terminal rendering
    vim.bo[buf].scrollback = 9999
    vim.bo[buf].scrollback = 9998
    -- Terminal-typed bufs have two built-in focus behaviors we have to undo
    -- for a static snapshot:
    --   1. mode propagation — if the previously-focused buf was in terminal-
    --      insert mode, this buf auto-enters terminal-insert too.
    --   2. cursor snap — the editor cursor snaps to the live terminal cursor
    --      position (end of the dump for us).
    -- Override: save cursor on leave, on enter force normal mode synchronously
    -- (pre-empts (1)), then vim.schedule a cursor restore that runs after
    -- nvim's snap (which happens inside the focus event itself) to undo (2).
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
      buffer = buf,
      callback = function()
        if vim.api.nvim_get_current_buf() == buf then
          cache.cursor = vim.api.nvim_win_get_cursor(0)
        end
      end,
    })
    -- Block manual entry into terminal-mode (e.g. pressing `i`/`a`). The
    -- BufEnter handler below only blocks the auto-entry on focus.
    vim.api.nvim_create_autocmd("TermEnter", {
      buffer = buf,
      callback = function()
        vim.cmd.stopinsert()
        vim.notify("Scrollback is read-only", vim.log.levels.INFO)
      end,
    })
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
      buffer = buf,
      callback = function()
        vim.cmd.stopinsert()
        if cache.cursor then
          vim.schedule(function()
            if vim.api.nvim_get_current_buf() ~= buf then return end
            local total = vim.api.nvim_buf_line_count(buf)
            pcall(vim.api.nvim_win_set_cursor, 0, {
              math.min(cache.cursor[1], total),
              cache.cursor[2] or 0,
            })
          end)
        end
      end,
    })
    return buf
  end

  -- Re-render on every open so content is fresh; keep the cache entry so
  -- cache.cursor persists across close/reopen.
  cache = scrollbacks[terminal.id]
  local old_buf = cache and cache.buf
  local new_buf = render_dump()
  if not new_buf then
    vim.notify("Scrollback is empty", vim.log.levels.INFO)
    return
  end
  if cache then
    cache.buf = new_buf
  else
    cache = { buf = new_buf }
    scrollbacks[terminal.id] = cache
  end
  if old_buf and old_buf ~= new_buf and vim.api.nvim_buf_is_valid(old_buf) then
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
  end

  local win = find_borrow_win(terminal.win)
  local split_restore
  if win then
    split_restore = {
      buf = vim.api.nvim_win_get_buf(win),
      view = vim.api.nvim_win_call(win, vim.fn.winsaveview),
    }
    vim.api.nvim_win_set_buf(win, cache.buf)
    vim.api.nvim_set_current_win(win)
  else
    local layout = terminal.opts.layout
    local cmd = (layout == "bottom" or layout == "top") and "topleft split" or "topleft vsplit"
    vim.cmd(cmd)
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, cache.buf)
  end

  local function place_cursor()
    local total = vim.api.nvim_buf_line_count(cache.buf)
    local lnum = cache.cursor and math.min(cache.cursor[1], total) or total
    local col = cache.cursor and cache.cursor[2] or 0
    local h = vim.api.nvim_win_get_height(win)
    vim.api.nvim_win_call(win, function()
      pcall(vim.fn.winrestview, {
        topline = math.max(1, lnum - math.floor(h / 2)),
        lnum = lnum,
        col = col,
      })
    end)
  end
  place_cursor()

  -- For top/bottom sidekick, flip to 8:2 — scrollback gets the larger share.
  local stacked = terminal.opts.layout == "bottom" or terminal.opts.layout == "top"
  if stacked then
    pcall(vim.api.nvim_win_set_height, terminal.win, math.floor(vim.o.lines * 0.2))
  end

  local close, refresh
  local function bind_keys(buf)
    vim.keymap.set("n", "q", close, { buffer = buf, desc = "Close snapshot" })
    vim.keymap.set("n", "<esc>", close, { buffer = buf, desc = "Close snapshot" })
    vim.keymap.set("n", "r", refresh, { buffer = buf, desc = "Refresh snapshot" })
  end

  close = function()
    if vim.api.nvim_win_is_valid(win) then
      if split_restore then
        pcall(vim.api.nvim_win_set_buf, win, split_restore.buf)
        pcall(vim.api.nvim_win_call, win, function()
          pcall(vim.fn.winrestview, split_restore.view)
        end)
      else
        vim.api.nvim_win_close(win, true)
      end
    end
    if stacked then
      pcall(vim.api.nvim_win_set_height, terminal.win, math.floor(vim.o.lines * 0.8))
    end
    pcall(function()
      if terminal:win_valid() then terminal:focus() end
    end)
    cache.close = nil
  end

  refresh = function()
    if not vim.api.nvim_win_is_valid(win) then return end
    local new_buf = render_dump()
    if not new_buf then return end
    local old_buf = cache.buf
    cache.buf = new_buf
    vim.api.nvim_win_set_buf(win, new_buf)
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
    bind_keys(new_buf)
    place_cursor()
  end

  cache.close = close
  bind_keys(cache.buf)

  vim.cmd.stopinsert()
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
        layout = "bottom",
        split = {
          width = 0, -- 0 = default split width (right/left layout)
          height = 0.8, -- 80% high for bottom/top layout
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
      "<c-]><c-j>",
      function()
        if vim.fn.mode():sub(1, 1) == "t" then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
          vim.schedule(select_prompt)
        else
          select_prompt()
        end
      end,
      mode = { "n", "t" },
      ft = "sidekick_terminal",
      desc = "Jump to prompt",
    },
    {
      "<c-]><c-h>",
      open_scrollback,
      mode = { "n", "t" },
      ft = "sidekick_terminal",
      desc = "Open scrollback snapshot",
    },
    {
      "<c-]><c-v>",
      function()
        local State = require("sidekick.cli.state")
        local states = State.get({ terminal = true })
        for _, state in ipairs(states) do
          if state.terminal then
            local opts = state.terminal.opts
            opts.layout = opts.layout == "right" and "bottom" or "right"
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
