-- View agent transcripts using a shared Sidekick UI. Format modules own
-- transcript discovery and JSONL decoding; this module owns presentation.

local M = {}

local uv = vim.uv or vim.loop
local win_picker = require("core.window_picker")

function M.read_at(fd, len, offset)
  local parts, got = {}, 0
  while got < len do
    local chunk = uv.fs_read(fd, len - got, offset + got)
    if not chunk or chunk == "" then break end
    parts[#parts + 1] = chunk
    got = got + #chunk
  end
  return table.concat(parts)
end

-- Read the whole file, or only the range beginning at the latest boundary
-- reported by `find_cut(window, at_file_start, window_offset)`. Windows are
-- scanned backward in bounded chunks, with overlap for records crossing an
-- edge; the absolute window offset lets stateful finders de-duplicate it.
function M.tail(path, find_cut)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then return nil end
  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil
  end

  local from = 0
  if find_cut then
    local chunk_size, overlap = 1024 * 1024, 64 * 1024
    local pos, carry = stat.size, ""
    while pos > 0 do
      local len = math.min(chunk_size, pos)
      pos = pos - len
      local chunk = M.read_at(fd, len, pos)
      local cut = find_cut(chunk .. carry, pos == 0, pos)
      if cut then
        from = pos + cut - 1
        break
      end
      carry = chunk:sub(1, overlap)
    end
  end

  local data = from < stat.size and M.read_at(fd, stat.size - from, from) or ""
  uv.fs_close(fd)
  return data
end

local function clean(value)
  return tostring(value):gsub("\27%[[0-9;?]*[ -/]*[@-~]", ""):gsub("\r", "")
end

function M.push(target, value)
  vim.list_extend(target, vim.split(clean(value), "\n", { plain = true }))
end

function M.summary(value)
  return (clean(value):match("[^\n]*")):sub(1, 120)
end

function M.fenced(lang, value)
  local lines = { "```" .. (lang or "") }
  M.push(lines, value)
  lines[#lines + 1] = "```"
  return lines
end

function M.content_text(content)
  if type(content) == "string" then return content end
  if type(content) ~= "table" then return "" end
  local parts = {}
  for _, item in ipairs(content) do
    if type(item) == "string" then
      parts[#parts + 1] = item
    elseif type(item) == "table" and item.text then
      parts[#parts + 1] = item.text
    end
  end
  return table.concat(parts, "\n")
end

function M.value_text(value)
  if type(value) == "string" then return value end
  if type(value) == "table" then
    local content = M.content_text(value)
    if content ~= "" then return content end
    local ok, encoded = pcall(vim.json.encode, value)
    return ok and encoded or vim.inspect(value)
  end
  return value == nil and "" or tostring(value)
end

function M.append_turn(out, blocks, role, body, body_blocks, has_text)
  if has_text then
    if #out > 0 and out[#out] ~= "" then out[#out + 1] = "" end
    out[#out + 1] = role == "user" and "You" or "Agent"
    out[#out + 1] = string.rep("-", 48)
  end
  local base = #out
  vim.list_extend(out, body)
  for _, block in ipairs(body_blocks or {}) do
    blocks[#blocks + 1] = { out = base + block[1], body = block[2] }
  end
  out[#out + 1] = ""
end

function M.append_block(out, blocks, label, body, opts)
  opts = opts or {}
  local line = "▸ " .. label
  if opts.preview and opts.preview ~= "" then
    line = line .. "  " .. M.summary(opts.preview)
  end
  out[#out + 1] = line
  if body and body ~= "" then
    blocks[#blocks + 1] = {
      out = #out,
      body = opts.raw_lines and body or M.fenced(opts.lang, body),
    }
  end
  if opts.blank ~= false then out[#out + 1] = "" end
end

function M.file_sig(path)
  local stat = path and uv.fs_stat(path)
  return stat and ("%s:%d:%d:%d"):format(
    path, stat.size, stat.mtime.sec, stat.mtime.nsec
  ) or nil
end

local transcript = M
local formats = {
  claude = require("util.claude_transcript"),
  codex = require("util.codex_transcript"),
}

-- Hooks for both agents write the same pane-root-PID record. The pane root is
-- the agent for a normal Sidekick tool and the long-lived shell for the zsh
-- tool, so it remains stable across startup, /resume, and agent process swaps.
local function pane_session(terminal, cwd)
  local pane = terminal and terminal.parent and terminal.parent.tmux_pid
  if not pane then return end
  local cache_root = vim.env.XDG_CACHE_HOME or vim.fn.expand("~/.cache")
  local file = ("%s/agent-sessions/%s.json"):format(cache_root, pane)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then return end
  local decoded, session = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded or type(session) ~= "table"
      or (session.agent ~= "claude" and session.agent ~= "codex")
      or tostring(session.pane_pid) ~= tostring(pane)
      or type(session.session_id) ~= "string" or session.session_id == ""
      or type(session.transcript_path) ~= "string"
      or not session.transcript_path:match("%.jsonl$")
      or vim.fs.normalize(session.cwd or "") ~= vim.fs.normalize(cwd) then
    return
  end
  return session
end

-- The registry normally identifies a zsh pane. Process inspection is only a
-- compatibility fallback for a session whose hooks have not run yet.
local function process_agent(terminal)
  local name = terminal and terminal.tool and terminal.tool.name
  if name == "claude" or name == "codex" then return name end
  local pane = terminal and terminal.parent and terminal.parent.tmux_pid
  if not pane then return "claude" end
  local procs = require("sidekick.cli.procs").new()
  local tools = require("sidekick.config").tools()
  local found
  procs:walk(pane, function(proc)
    for _, agent in ipairs({ "claude", "codex" }) do
      if tools[agent] and tools[agent]:is_proc(proc) then
        found = agent
        return true
      end
    end
  end)
  return found or "claude"
end

function M.resolve(terminal, cwd)
  local session = pane_session(terminal, cwd)
  if session then
    -- SessionStart may run before the transcript's first record is created.
    -- An exact but not-yet-materialised path must not fall back to a neighbour.
    local path = uv.fs_stat(session.transcript_path) and session.transcript_path or nil
    return path, false, session.agent
  end
  local name = process_agent(terminal)
  local path, guessed = formats[name].resolve(terminal, cwd, transcript)
  return path, guessed, name
end

-- ── viewer (sidekick UI) ─────────────────────────────────────────────────────

-- Per-terminal viewer state, keyed by sidekick terminal id.
-- { buf = number, cursor = { lnum, col }, blocks = table?, compact_windows = number }
-- `blocks` maps a `▸` summary line number -> its stashed body lines, which are
-- shown in a float on <CR> rather than living in the (immutable) buffer.
-- Module-level so the buf (bufhidden=hide) and its buffer-local autocmds share
-- cursor state with future M.open invocations across reopens.
local transcripts = {}

-- Namespace for the dim highlight on each `▸` summary line, so collapsed tool
-- blocks recede and the conversation prose stays prominent.
local ns = vim.api.nvim_create_namespace("agent_transcript")

local function find_focused_terminal()
  local Terminal = require("sidekick.cli.terminal")
  local current_buf = vim.api.nvim_get_current_buf()
  for _, t in pairs(Terminal.sessions()) do
    if t.buf == current_buf or t:is_focused() then return t end
  end
end

-- Open the focused sidekick terminal's agent transcript in a read-only markdown
-- buffer, shown wherever the window picker is pointed. `compact_windows` is the
-- number of completed windows to retain before the current one (default one).
-- Closing the buffer is the window's business, not ours.
function M.open(compact_windows)
  compact_windows = compact_windows == nil and 1 or compact_windows
  if type(compact_windows) ~= "number" or compact_windows < 0
      or compact_windows ~= math.floor(compact_windows) then
    vim.notify("compact_windows must be a non-negative integer", vim.log.levels.ERROR)
    return
  end
  local terminal = find_focused_terminal()
  if not terminal then
    vim.notify("No focused sidekick terminal", vim.log.levels.WARN)
    return
  end
  local term_cwd = (terminal.parent and terminal.parent.cwd)
      or terminal.cwd or vim.fn.getcwd()

  -- Signature of the session's current transcript, for the freshness check that
  -- decides whether a rebuild is needed at all (skipping both the tail re-parse
  -- and the one-time markdown treesitter parse).
  local function current_sig()
    local path = M.resolve(terminal, term_cwd)
    return transcript.file_sig(path)
  end

  local cache
  -- Returns (buf, blocks, sig). The signature is taken *before* the read and
  -- returned alongside the buffer, so the cache is always labelled with the
  -- content it actually holds: resolving a second time to sign it could pick up
  -- an append (or a different session) that this buffer doesn't contain, and
  -- that rebuild would then never happen.
  local function build_buf()
    local path, guessed, agent = M.resolve(terminal, term_cwd)
    if path and guessed then
      vim.notify("Couldn't identify this pane's session; showing the most recent transcript",
        vim.log.levels.WARN)
    end
    if not path then return nil end
    local sig = transcript.file_sig(path)
    local lines, blks = formats[agent].render(path, transcript, compact_windows)
    if not lines or #lines == 0 then return nil end
    local buf = vim.api.nvim_create_buf(true, true)
    vim.bo[buf].bufhidden = "hide"
    -- Snacks' bigfile detection only fires on file-backed buffers, not this
    -- scratch one, so pick the filetype ourselves. render-markdown needs a
    -- treesitter parse, and tree-sitter's markdown grammar parses the WHOLE
    -- document on first parse (~20ms/1000 lines, range hints don't help) — a
    -- one-time open-time hit. Collapsing tool bodies out of the buffer keeps
    -- this line count small, so markdown (treesitter + render-markdown) stays
    -- affordable; past 5000 lines fall back to `bigfile` (plain vim syntax, no
    -- treesitter) so opening a huge dump stays snappy.
    local big = #lines > 5000
    vim.bo[buf].filetype = big and "bigfile" or "markdown"
    local tool = terminal.tool and terminal.tool.name or "sidekick"
    local name = ("Transcript: %s"):format(tool)
    if not pcall(vim.api.nvim_buf_set_name, buf, name) then
      pcall(vim.api.nvim_buf_set_name, buf, ("%s #%d"):format(name, buf))
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- Map each `▸` summary line to its stashed body (the buffer never mutates,
    -- so the line number is a stable key; <CR> on the line pops the body in a
    -- float) and dim it so collapsed blocks recede beneath the prose. The high
    -- priority keeps the dim above render-markdown/treesitter highlights.
    vim.api.nvim_set_hl(0, "AgentTranscriptFold", { link = "Comment", default = true })
    local by_line = {}
    for _, blk in ipairs(blks) do
      by_line[blk.out] = blk.body
      vim.api.nvim_buf_set_extmark(buf, ns, blk.out - 1, 0, {
        end_col = #lines[blk.out],
        hl_group = "AgentTranscriptFold",
        priority = 200,
      })
    end
    vim.bo[buf].modifiable = false
    vim.bo[buf].modified = false
    -- bigfile blanks `syntax`; restore cheap markdown syntax so the dump stays
    -- readable (vim regex highlighting — treesitter/render-markdown stay off).
    if big then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.bo[buf].syntax = "markdown"
        end
      end)
    end
    -- A normal (non-terminal) buffer: no mode-propagation or cursor-snap to
    -- fight. Just persist the cursor across close/reopen and refresh.
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
      buffer = buf,
      callback = function()
        if vim.api.nvim_get_current_buf() == buf then
          cache.cursor = vim.api.nvim_win_get_cursor(0)
        end
      end,
    })
    return buf, by_line, sig
  end

  -- Reuse the cached buffer when the transcript file is unchanged; otherwise
  -- rebuild from fresh content. The cache entry also persists cache.cursor
  -- across close/reopen.
  cache = transcripts[terminal.id]
  local sig = current_sig()
  local fresh = cache and cache.buf and vim.api.nvim_buf_is_valid(cache.buf)
      and sig and cache.sig == sig and cache.compact_windows == compact_windows
  if not fresh then
    local old_buf = cache and cache.buf
    local new_buf, new_blocks, new_sig = build_buf()
    if not new_buf then
      vim.notify("Transcript is empty", vim.log.levels.INFO)
      return
    end
    if cache then
      cache.buf = new_buf
    else
      cache = { buf = new_buf }
      transcripts[terminal.id] = cache
    end
    cache.blocks = new_blocks
    cache.sig = new_sig
    cache.compact_windows = compact_windows
    if old_buf and old_buf ~= new_buf and vim.api.nvim_buf_is_valid(old_buf) then
      pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
    end
  end

  local target = win_picker.pick()
  if not target then return end
  local win = win_picker.show_buf(target, cache.buf)
  if not win then return end

  local function place_cursor(w)
    local total = vim.api.nvim_buf_line_count(cache.buf)
    local lnum = cache.cursor and math.min(cache.cursor[1], total) or total
    local col = cache.cursor and cache.cursor[2] or 0
    local h = vim.api.nvim_win_get_height(w)
    vim.api.nvim_win_call(w, function()
      pcall(vim.fn.winrestview, {
        topline = math.max(1, lnum - math.floor(h / 2)),
        lnum = lnum,
        col = col,
      })
    end)
  end
  place_cursor(win)

  -- Pop the body of the `▸` block on the cursor line into a centred float,
  -- loaded on demand (the bodies never live in the transcript buffer). The
  -- float is a markdown scratch buffer, so its fenced code — diffs included —
  -- highlights exactly as it would inline. q/<Esc>/<CR> dismiss it.
  local function peek()
    local body = cache.blocks and cache.blocks[vim.fn.line(".")]
    if not body then return end
    local fbuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(fbuf, 0, -1, false, body)
    vim.bo[fbuf].modifiable = false
    vim.bo[fbuf].filetype = "markdown"
    local wanted = 0
    for _, l in ipairs(body) do wanted = math.max(wanted, vim.fn.strdisplaywidth(l)) end
    local width = math.min(math.max(wanted + 1, 20), math.floor(vim.o.columns * 0.8))
    local height = math.min(#body, math.floor(vim.o.lines * 0.8))
    local fwin = vim.api.nvim_open_win(fbuf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "rounded",
    })
    vim.wo[fwin].wrap = false
    local function shut()
      if vim.api.nvim_win_is_valid(fwin) then vim.api.nvim_win_close(fwin, true) end
    end
    for _, k in ipairs({ "q", "<esc>", "<cr>" }) do
      vim.keymap.set("n", k, shut, { buffer = fbuf, desc = "Close peek" })
    end
    vim.api.nvim_create_autocmd("WinLeave", { buffer = fbuf, once = true, callback = shut })
  end

  -- Pick a turn and jump to it. Turns are rendered as a speaker name over a
  -- rule, so a `You`/agent heading followed by one is the anchor; the label
  -- is that turn's first line of prose. The speaker is part of `text` so typing
  -- "agent" or "you" narrows the list.
  local function select_message()
    local lines = vim.api.nvim_buf_get_lines(cache.buf, 0, -1, false)
    local items = {}
    for i, line in ipairs(lines) do
      if (line == "You" or line == "Agent")
          and (lines[i + 1] or ""):match("^%-%-%-") then
        -- The body starts right under the rule. A blank there means the turn
        -- has no prose, so don't reach further and borrow the next one's.
        local msg = vim.trim(lines[i + 2] or "")
        if msg == "" then msg = "(empty)" end
        table.insert(items, 1, {
          buf = cache.buf,
          who = line,
          msg = msg,
          text = line .. " " .. msg,
          pos = { i, 0 },
        })
      end
    end
    if #items == 0 then
      vim.notify("No messages found", vim.log.levels.INFO)
      return
    end

    Snacks.picker.pick({
      source = "messages",
      items = items,
      format = function(item)
        return {
          { string.format("%4d", item.pos[1]), "SnacksPickerIdx" },
          { "  " },
          -- Distinct hues: SnacksPickerLabel links to SnacksPickerSpecial, so the
          -- two speakers would otherwise render identically.
          { ("%-6s"):format(item.who), item.who == "You" and "MoreMsg" or "Special" },
          { "  " },
          { item.msg },
        }
      end,
      layout = { preset = "default" },
      jump = { match = true },
      main = { current = true },
      sort = { fields = { "score:desc", "idx" } },
    })
  end

  local refresh
  local function bind_keys(buf)
    vim.keymap.set("n", "r", refresh, { buffer = buf, desc = "Refresh transcript" })
    vim.keymap.set("n", "m", select_message, { buffer = buf, desc = "Search messages" })
    -- Peek the block under the cursor in a float, loaded on demand.
    vim.keymap.set("n", "<cr>", peek, { buffer = buf, desc = "Peek block" })
    -- Jump between turn titles (works whether or not it's a bigfile, and
    -- targets speaker dividers rather than `##` content headings).
    vim.keymap.set("n", "]]", function() vim.fn.search([[\v^(You|Agent)$]], "W") end,
      { buffer = buf, desc = "Next turn" })
    vim.keymap.set("n", "[[", function() vim.fn.search([[\v^(You|Agent)$]], "bW") end,
      { buffer = buf, desc = "Prev turn" })
  end

  refresh = function()
    -- Wherever the transcript is now, which need not be the window it opened in.
    local w = vim.fn.bufwinid(cache.buf)
    if w == -1 then return end
    local rb, rblocks, rsig = build_buf()
    if not rb then return end
    local prev = cache.buf
    cache.buf, cache.blocks, cache.sig = rb, rblocks, rsig
    vim.api.nvim_win_set_buf(w, rb)
    pcall(vim.api.nvim_buf_delete, prev, { force = true })
    bind_keys(rb)
    place_cursor(w)
  end

  bind_keys(cache.buf)

  vim.cmd.stopinsert()
end

return M
