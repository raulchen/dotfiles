-- Resolve and render Claude Code JSONL transcripts.

local M = {}

local uv = vim.uv or vim.loop

-- Claude stores transcripts at ~/.claude/projects/<slug>/<session-id>.jsonl,
-- where <slug> is the cwd with "/" and "." replaced by "-".
local function project_dir(cwd)
  local slug = (vim.fs.normalize(cwd):gsub("[/.]", "-"))
  return vim.fn.expand("~/.claude/projects/" .. slug)
end

-- A live Claude CLI registers itself at ~/.claude/sessions/<pid>.json as
-- { sessionId, cwd, … }, rewritten as the session changes. It's the one record
-- tying a *process* to a transcript, so it tells sessions sharing a cwd apart
-- and follows a pane through /clear (a new session id in the same process).
local function live_session(pid)
  local ok, lines = pcall(vim.fn.readfile, vim.fn.expand("~/.claude/sessions/" .. pid .. ".json"))
  if not ok then return nil end
  local decoded, s = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded and type(s) == "table" and s.sessionId and s.cwd) and s or nil
end

-- The newest transcript under `cwd`: the best guess left when no CLI running in
-- the terminal is registered (an exited session, a CLI too old to register, a
-- non-tmux backend, or a non-Claude tool).
local function newest_jsonl(cwd)
  local dir = project_dir(cwd)
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

-- Resolve the transcript (.jsonl) of the session running in `terminal`.
-- Returns (path, guessed), where `guessed` marks the newest-in-dir fallback:
-- it silently shows a *neighbouring* session when several share a cwd, which is
-- the one thing this resolution exists to avoid, so the caller says so.
function M.resolve(terminal, cwd)
  -- The tmux pane's process is the CLI itself for a sidekick-managed session,
  -- or its parent shell for the `zsh` tool that hosts a manually started one.
  local pane = terminal and terminal.parent and terminal.parent.tmux_pid
  local pids = pane and vim.list_extend({ pane }, vim.api.nvim_get_proc_children(pane)) or {}
  for _, pid in ipairs(pids) do
    local s = live_session(pid)
    if s then
      -- The file appears with the session's first message. Until then it has no
      -- transcript, and saying so beats falling back to a *different* session's.
      local path = ("%s/%s.jsonl"):format(project_dir(s.cwd), s.sessionId)
      return uv.fs_stat(path) and path or nil, false
    end
  end

  return newest_jsonl(cwd), true
end

-- Read only the transcript tail: bytes after the last `compact_boundary` line,
-- or the whole file if it was never compacted. Walks backward in chunks so the
-- (possibly huge) pre-compaction bulk is never read; each marker is confirmed
-- by decoding its line, so the string appearing in message content (as in this
-- very session) can't trigger a false cut.
local function transcript_tail(path, transcript)
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
  return transcript.tail(path, boundary_cut)
end

-- Render a transcript .jsonl (tail only) into markdown plus a list of
-- collapsible blocks. Only the conversation prose and a one-line `▸` summary
-- per tool call / result (and the carried compaction summary) go into the
-- returned lines; each block's fenced body is stashed in `blocks` as
-- { out = <1-based summary line in the lines>, body = { lines… } } to be
-- spliced into the buffer on demand. Thinking and bodyless turns are skipped.
function M.render(path, transcript)
  local text = transcript_tail(path, transcript)
  if not text then return nil end
  local out, blocks_out = {}, {}
  local push, summary = transcript.push, transcript.summary
  -- tool_use ids of subagent launches (Agent/Task), so their tool_result — the
  -- subagent's full report, which may arrive far from the launch for a
  -- background agent — can be recognised by tool_use_id and collapsed without
  -- previewing its body.
  local agent_ids = {}
  -- Fenced body for a tool_use: Edit/MultiEdit become a unified diff, everything
  -- else shows its command / content / inspected input. Returns (lang, text),
  -- where lang is a real treesitter language so the fence highlights (`diff`
  -- for edits, `bash` for shell commands) — never the tool name, which isn't a
  -- language and would just kill highlighting.
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
    local lang = i.command and "bash" or ""
    return lang, tostring(i.command or i.content or i.file_text or vim.inspect(i))
  end
  for line in vim.gsplit(text, "\n", { plain = true }) do
    local ok, ev = pcall(vim.json.decode, line)
    if ok and type(ev) == "table" and ev.message
        and (ev.type == "user" or ev.type == "assistant") then
      local content = ev.message.content
      local blocks = type(content) == "string"
          and { { type = "text", text = content } } or content
      if type(blocks) == "table" then
        -- `body` holds the turn's inlined lines (prose + one `▸` summary per
        -- tool block); `body_blocks` pairs each summary's body index with its
        -- stashed fenced body { <rel line in body>, { body lines… } }.
        local body, has_text, body_blocks = {}, false, {}
        for _, b in ipairs(blocks) do
          if b.type == "text" and b.text and b.text ~= "" then
            has_text = true
            push(body, b.text)
          elseif b.type == "tool_use" then
            local i = b.input or {}
            local hint = summary(i.command or i.file_path or i.path or i.pattern
              or i.query or i.skill or i.description or i.url or i.prompt
              or i.content or i.file_text or "")
            local name = b.name or "tool"
            if b.id and (name == "Agent" or name == "Task" or i.subagent_type) then
              agent_ids[b.id] = true
            end
            push(body, hint ~= "" and ("▸ %s  %s"):format(name, hint) or ("▸ %s"):format(name))
            local lang, code = tool_render(name, i)
            body_blocks[#body_blocks + 1] = { #body, transcript.fenced(lang, code) }
          elseif b.type == "tool_result" then
            local c = b.content
            if type(c) == "table" then
              local parts = {}
              for _, p in ipairs(c) do parts[#parts + 1] = p.text or "" end
              c = table.concat(parts, "\n")
            end
            if type(c) == "string" and c ~= "" then
              -- A subagent's report is collapsed with no body preview (its first
              -- line often leaks the whole gist); other tool results keep the
              -- one-line summary. Both stay peekable on <CR>.
              local label = (b.tool_use_id and agent_ids[b.tool_use_id])
                  and "▸ subagent response"
                  or ("▸ result  %s"):format(summary(c))
              push(body, label)
              body_blocks[#body_blocks + 1] = { #body, transcript.fenced("", c) }
            end
          end
        end
        local aux = ev.isMeta or ev.isCompactSummary
        if #body > 0 then
          if aux then
            -- Injected context (skills/reminders via isMeta) and the carried
            -- compaction summary aren't live conversation: collapse the whole
            -- turn behind one `▸ context` line (no divider). Materialise its
            -- tool bodies inline first (bottom-up, so earlier indices stay
            -- valid) so the single stashed block is self-contained.
            local label = ev.isCompactSummary and "context summary (compacted)"
                or ("context  " .. summary(body[1] or ""))
            table.sort(body_blocks, function(x, y) return x[1] > y[1] end)
            for _, sb in ipairs(body_blocks) do
              for k = #sb[2], 1, -1 do table.insert(body, sb[1] + 1, sb[2][k]) end
            end
            transcript.append_block(out, blocks_out, label, body, { raw_lines = true })
          else
            -- Setext h2: the speaker name underlined by a rule — native markdown
            -- that reads as a titled divider (distinct from `##` content
            -- headings) and the anchor for [[ / ]] turn navigation. The
            -- underline must sit directly under the name (no blank line). Only
            -- prose turns get one: a tool-only message (an agentic step with no
            -- text) folds into the preceding turn, so navigation lands on
            -- substantive turns rather than every tool call.
            transcript.append_turn(out, blocks_out, ev.type, body, body_blocks, has_text)
          end
        end
      end
    end
  end
  return out, blocks_out
end

return M
