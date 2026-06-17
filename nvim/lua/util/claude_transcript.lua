-- Read, render, and view Claude Code session transcripts (the .jsonl files
-- under ~/.claude/projects/<slug>/). The lower half is pure data (parse a
-- transcript to markdown + folds); the lower-UI half (M.open) renders it into a
-- read-only buffer borrowed next to the focused sidekick terminal.

local M = {}

local uv = vim.uv or vim.loop

-- Read exactly `len` bytes at `offset` (or fewer at EOF), looping over short
-- reads since uv.fs_read may return less than requested.
local function read_at(fd, len, offset)
  local parts, got = {}, 0
  while got < len do
    local chunk = uv.fs_read(fd, len - got, offset + got)
    if not chunk or chunk == "" then break end
    parts[#parts + 1] = chunk
    got = got + #chunk
  end
  return table.concat(parts)
end

-- Resolve the Claude Code transcript (.jsonl) for a session running in `cwd`.
-- Claude stores them at ~/.claude/projects/<slug>/<uuid>.jsonl, where <slug> is
-- the cwd with "/" and "." replaced by "-"; the active session is the
-- most-recently-modified one.
local function session_jsonl(cwd)
  local slug = (vim.fs.normalize(cwd):gsub("[/.]", "-"))
  local dir = vim.fn.expand("~/.claude/projects/" .. slug)
  local ok, entries = pcall(vim.fn.readdir, dir)
  if not ok then return nil end
  local newest, newest_mt = nil, -1
  for _, name in ipairs(entries) do
    if name:match("%.jsonl$") then
      local full = dir .. "/" .. name
      local st = uv.fs_stat(full)
      if st and st.mtime.sec > newest_mt then
        newest, newest_mt = full, st.mtime.sec
      end
    end
  end
  return newest
end

-- Read only the transcript tail: bytes after the last `compact_boundary` line,
-- or the whole file if it was never compacted. Walks backward in chunks so the
-- (possibly huge) pre-compaction bulk is never read; each marker is confirmed
-- by decoding its line, so the string appearing in message content (as in this
-- very session) can't trigger a false cut.
local function transcript_tail(path)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then return nil end
  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil
  end

  -- Offset just past the last verified compact_boundary line in `buf`, or nil.
  local function boundary_cut(buf)
    local from, cut = 1, nil
    while true do
      local s = buf:find("compact_boundary", from, true)
      if not s then break end
      from = s + 1
      local le = buf:find("\n", s, true) or (#buf + 1)
      -- A real boundary line is small; skip giant content lines that merely
      -- mention the marker (this also bounds the line-start lookback below,
      -- which would otherwise be O(s^2) for a marker deep in a huge JSON line).
      if le - s < 4096 then
        local lb, ls, p = math.max(1, s - 4096), nil, math.max(1, s - 4096)
        while true do
          local n = buf:find("\n", p, true)
          if not n or n >= s then break end
          ls, p = n + 1, n + 1
        end
        local ok, ev = pcall(vim.json.decode, buf:sub(ls or lb, le - 1))
        if ok and type(ev) == "table" and ev.type == "system"
            and ev.subtype == "compact_boundary" then
          cut = le + 1
        end
      end
    end
    return cut
  end

  -- Walk backward in chunks, scanning each chunk plus a right-overlap (so a
  -- boundary line split across a chunk edge is still seen), tracking only the
  -- last boundary's absolute offset. Then read the post-boundary range once.
  local CHUNK, OVERLAP = 1024 * 1024, 64 * 1024
  local size, pos, carry, cut_abs = stat.size, stat.size, "", nil
  while pos > 0 do
    local rlen = math.min(CHUNK, pos)
    pos = pos - rlen
    local chunk = read_at(fd, rlen, pos) -- file bytes [pos, pos+rlen)
    local cw = boundary_cut(chunk .. carry) -- window covers [pos, pos+rlen+#carry)
    if cw then
      cut_abs = pos + (cw - 1) -- window index -> absolute file offset
      break
    end
    carry = chunk:sub(1, OVERLAP) -- this chunk's left edge sits right of the next
  end
  local from = cut_abs or 0
  local data = from < size and read_at(fd, size - from, from) or ""
  uv.fs_close(fd)
  return data
end

-- Render a transcript .jsonl (tail only) into markdown and a list of foldable
-- {start, end} line ranges. Every tool call / result — and the carried
-- compaction summary — is returned as a fold so only the conversation prose
-- stays open. Each tool block is a one-line `▸` summary + a fenced body.
-- Thinking blocks and bodyless turns are skipped.
local function render_transcript(path)
  local text = transcript_tail(path)
  if not text then return nil end
  local out, folds = {}, {}
  -- Append `s` to `target` as lines, dropping ANSI/CR control bytes.
  local function push(target, s)
    s = s:gsub("\27%[[0-9;?]*[ -/]*[@-~]", ""):gsub("\r", "")
    vim.list_extend(target, vim.split(s, "\n", { plain = true }))
  end
  local function summary(s)
    return (tostring(s):gsub("\27%[[0-9;?]*[ -/]*[@-~]", ""):match("[^\r\n]*")):sub(1, 120)
  end
  -- Fenced body for a tool_use: Edit/MultiEdit become a unified diff, everything
  -- else shows its command / content / inspected input. Returns (lang, text).
  local function tool_render(name, i)
    local function diff(a, b)
      local ok, d = pcall(vim.diff, (a or "") .. "\n", (b or "") .. "\n", { ctxlen = 3 })
      return (ok and d ~= "" and d) or vim.inspect({ old = a, new = b })
    end
    if name == "Edit" and i.new_string ~= nil then
      return "diff", diff(i.old_string, i.new_string)
    elseif name == "MultiEdit" and type(i.edits) == "table" then
      local parts = {}
      for _, e in ipairs(i.edits) do
        parts[#parts + 1] = diff(e.old_string, e.new_string)
      end
      return "diff", table.concat(parts, "\n")
    end
    return name, tostring(i.command or i.content or i.file_text or vim.inspect(i))
  end
  for line in vim.gsplit(text, "\n", { plain = true }) do
    local ok, ev = pcall(vim.json.decode, line)
    if ok and type(ev) == "table" and ev.message
        and (ev.type == "user" or ev.type == "assistant") then
      local content = ev.message.content
      local blocks = type(content) == "string"
          and { { type = "text", text = content } } or content
      if type(blocks) == "table" then
        local body, has_text, body_folds = {}, false, {}
        -- Record a fold over body lines [bs, #body] (one per tool block).
        local function fold_block(bs)
          body_folds[#body_folds + 1] = { bs, #body }
        end
        for _, b in ipairs(blocks) do
          if b.type == "text" and b.text and b.text ~= "" then
            has_text = true
            push(body, b.text)
          elseif b.type == "tool_use" then
            local i, bs = b.input or {}, #body + 1
            local hint = summary(i.command or i.file_path or i.path or i.pattern
              or i.query or i.skill or i.description or i.url or i.prompt
              or i.content or i.file_text or "")
            local name = b.name or "tool"
            push(body, hint ~= "" and ("▸ %s  %s"):format(name, hint) or ("▸ %s"):format(name))
            local lang, code = tool_render(name, i)
            push(body, "```" .. lang)
            push(body, code)
            body[#body + 1] = "```"
            fold_block(bs)
          elseif b.type == "tool_result" then
            local c = b.content
            if type(c) == "table" then
              local parts = {}
              for _, p in ipairs(c) do parts[#parts + 1] = p.text or "" end
              c = table.concat(parts, "\n")
            end
            if type(c) == "string" and c ~= "" then
              local bs = #body + 1
              push(body, ("▸ result  %s"):format(summary(c)))
              body[#body + 1] = "```"
              push(body, c)
              body[#body + 1] = "```"
              fold_block(bs)
            end
          end
        end
        -- Injected context (skills/reminders via isMeta) and the carried
        -- compaction summary aren't live conversation: collapse each behind one
        -- `▸ context` line, with no turn divider.
        local aux = ev.isMeta or ev.isCompactSummary
        if aux and #body > 0 then
          local label = ev.isCompactSummary and "context summary (compacted)"
            or ("context  " .. summary(body[1] or ""))
          table.insert(body, 1, "▸ " .. label)
          body_folds = { { 1, #body } }
        end
        if #body > 0 then
          if not aux then
            -- Setext h2: the speaker name underlined by a rule — native markdown
            -- that reads as a titled divider, distinct from `##` content headings.
            -- The underline must sit directly under the name (no blank line).
            local who = ev.type == "assistant" and "Claude" or (has_text and "You" or nil)
            if who then
              out[#out + 1] = who
              out[#out + 1] = string.rep("-", 48)
            end
          end
          local base = #out -- body line k lands at out[base + k]
          vim.list_extend(out, body)
          for _, f in ipairs(body_folds) do
            folds[#folds + 1] = { base + f[1], base + f[2] }
          end
          out[#out + 1] = ""
        end
      end
    end
  end
  return out, folds
end

-- Render the active Claude transcript for `cwd`: (lines, folds) or nil.
local function render(cwd)
  local path = session_jsonl(cwd)
  if not path then return nil end
  return render_transcript(path)
end

-- ── viewer (sidekick UI) ─────────────────────────────────────────────────────

-- Per-terminal viewer state, keyed by sidekick terminal id.
-- { buf = number, cursor = { lnum, col }, close = fun?, folds = table? }
-- Module-level so the buf (bufhidden=hide) and its buffer-local autocmds share
-- cursor state with future M.open invocations across close/reopen.
local transcripts = {}

local function find_focused_terminal()
  local Terminal = require("sidekick.cli.terminal")
  local current_buf = vim.api.nvim_get_current_buf()
  for _, t in pairs(Terminal.sessions()) do
    if t.buf == current_buf or t:is_focused() then return t end
  end
end

-- Pick a non-float, non-excluded window: prefer the previous window, then scan.
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

-- Close manual folds over the given {start, end} line ranges in `win`.
local function apply_folds(win, folds)
  if not folds or #folds == 0 then return end
  vim.api.nvim_win_call(win, function()
    vim.wo.foldmethod = "manual"
    vim.wo.foldenable = true
    for _, f in ipairs(folds) do
      pcall(vim.cmd, ("%d,%dfold"):format(f[1], f[2]))
    end
    vim.wo.foldlevel = 0
  end)
end

-- Open (or toggle) the focused sidekick terminal's Claude transcript in a
-- read-only markdown buffer borrowed in a neighbouring window.
function M.open()
  -- Toggle: if invoked from inside an open transcript buf, close it.
  local current_buf = vim.api.nvim_get_current_buf()
  for _, state in pairs(transcripts) do
    if state.close and state.buf == current_buf then
      state.close()
      return
    end
  end

  local terminal = find_focused_terminal()
  if not terminal then
    vim.notify("No focused sidekick terminal", vim.log.levels.WARN)
    return
  end
  local term_cwd = (terminal.parent and terminal.parent.cwd)
    or terminal.cwd or vim.fn.getcwd()

  -- Toggle: if this terminal's transcript is open, close it.
  if transcripts[terminal.id] and transcripts[terminal.id].close then
    transcripts[terminal.id].close()
    return
  end

  local cache
  local function build_buf()
    local lines, folds = render(term_cwd)
    if not lines or #lines == 0 then return nil end
    local buf = vim.api.nvim_create_buf(true, true)
    vim.bo[buf].bufhidden = "hide"
    -- Snacks' bigfile detection only fires on file-backed buffers, not this
    -- scratch one, so pick the filetype ourselves. render-markdown needs a
    -- treesitter parse, and tree-sitter's markdown grammar parses the WHOLE
    -- document on first parse (~20ms/1000 lines, range hints don't help) — a
    -- one-time open-time hit. Keep markdown (treesitter + render-markdown) while
    -- that stays ~100ms; past it fall back to `bigfile` (plain vim syntax, no
    -- treesitter) so opening a huge dump stays snappy.
    local big = #lines > 5000
    vim.bo[buf].filetype = big and "bigfile" or "markdown"
    local tool = terminal.tool and terminal.tool.name or "sidekick"
    local name = ("Transcript: %s"):format(tool)
    if not pcall(vim.api.nvim_buf_set_name, buf, name) then
      pcall(vim.api.nvim_buf_set_name, buf, ("%s #%d"):format(name, buf))
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
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
    return buf, folds
  end

  -- Re-render on every open so content is fresh; keep the cache entry so
  -- cache.cursor persists across close/reopen.
  cache = transcripts[terminal.id]
  local old_buf = cache and cache.buf
  local new_buf, new_folds = build_buf()
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
  cache.folds = new_folds
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
  apply_folds(win, cache.folds)

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

  -- For top/bottom sidekick, flip to 8:2 — transcript gets the larger share.
  local stacked = terminal.opts.layout == "bottom" or terminal.opts.layout == "top"
  if stacked then
    pcall(vim.api.nvim_win_set_height, terminal.win, math.floor(vim.o.lines * 0.2))
  end

  local close, refresh
  local function bind_keys(buf)
    vim.keymap.set("n", "q", close, { buffer = buf, desc = "Close transcript" })
    vim.keymap.set("n", "<esc>", close, { buffer = buf, desc = "Close transcript" })
    vim.keymap.set("n", "r", refresh, { buffer = buf, desc = "Refresh transcript" })
    -- Jump between turn titles (works whether or not it's a bigfile, and
    -- targets speaker dividers rather than `##` content headings).
    vim.keymap.set("n", "]]", function() vim.fn.search([[\v^(You|Claude)$]], "W") end,
      { buffer = buf, desc = "Next turn" })
    vim.keymap.set("n", "[[", function() vim.fn.search([[\v^(You|Claude)$]], "bW") end,
      { buffer = buf, desc = "Prev turn" })
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
    local rb, rf = build_buf()
    if not rb then return end
    local prev = cache.buf
    cache.buf, cache.folds = rb, rf
    vim.api.nvim_win_set_buf(win, rb)
    pcall(vim.api.nvim_buf_delete, prev, { force = true })
    bind_keys(rb)
    apply_folds(win, rf)
    place_cursor()
  end

  cache.close = close
  bind_keys(cache.buf)

  vim.cmd.stopinsert()
end

return M
