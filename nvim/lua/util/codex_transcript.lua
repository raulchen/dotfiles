-- Resolve and render Codex JSONL transcripts. Parsing intentionally lives in
-- this agent-specific module because OpenAI documents the transcript contents
-- as an unstable format.

local M = {}

local uv = vim.uv or vim.loop

local function first_line(fd, transcript)
  local parts, offset = {}, 0
  while offset < 4 * 1024 * 1024 do
    local chunk = transcript.read_at(fd, 64 * 1024, offset)
    if chunk == "" then break end
    local newline = chunk:find("\n", 1, true)
    parts[#parts + 1] = newline and chunk:sub(1, newline - 1) or chunk
    if newline then break end
    offset = offset + #chunk
  end
  return table.concat(parts)
end

local function session_meta(path, transcript)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then return end
  local first = first_line(fd, transcript)
  uv.fs_close(fd)
  local ok, ev = pcall(vim.json.decode, first or "")
  return ok and ev.type == "session_meta" and ev.payload or nil
end

local function is_root_for_cwd(path, cwd, transcript)
  local p = session_meta(path, transcript)
  local parent = p and p.parent_thread_id
  return p and (parent == nil or parent == vim.NIL) and type(p.source) ~= "table"
      and vim.fs.normalize(p.cwd or "") == vim.fs.normalize(cwd)
end

-- Return every live root thread under this cwd. The app server cannot identify
-- the owning client pane, so the shared viewer selects automatically only when
-- this list contains one candidate.
---@param done fun(candidates: AgentTranscriptCandidate[])
function M.list_candidates(_, cwd, done)
  local command = vim.fn.expand("~/dotfiles/libexec/codex-live-threads")
  if vim.fn.executable(command) ~= 1 then
    vim.schedule(function() done({}) end)
    return
  end
  local query_cwd = uv.fs_realpath(cwd) or vim.fs.normalize(cwd)
  vim.system({ command, query_cwd }, { text = true }, function(result)
    vim.schedule(function()
      local ok, decoded = pcall(vim.json.decode, result.code == 0 and result.stdout or "")
      if not ok or type(decoded) ~= "table" then
        done({})
        return
      end
      local candidates = {}
      for _, thread in ipairs(decoded) do
        if type(thread) == "table" and type(thread.id) == "string"
            and type(thread.path) == "string" and thread.path:match("%.jsonl$")
            and type(thread.status) == "table" then
          candidates[#candidates + 1] = {
            id = thread.id,
            path = thread.path,
            title = thread.name or thread.preview or thread.id,
            status = thread.status.type or "loaded",
            updated_at = thread.updatedAt,
          }
        end
      end
      done(candidates)
    end)
  end)
end

-- If no live thread is available, inspect persisted rollouts. Codex lifecycle
-- hooks include the thread id and transcript path, but daemon-dispatched hooks
-- inherit the daemon's tmux environment rather than the client pane's, so they
-- cannot safely maintain a pane marker.
--
-- Inspect newest root rollouts and choose the first cwd match instead. This is
-- deliberately reported as a guess: concurrent Codex threads in the same cwd
-- cannot be distinguished, and /resume is exact only once its rollout becomes
-- the most recently modified matching file.
function M.resolve(_, cwd, transcript)
  local root = vim.fn.expand("~/.codex/sessions")
  local paths = vim.fn.glob(root .. "/**/*.jsonl", false, true)
  table.sort(paths, function(a, b)
    local sa, sb = uv.fs_stat(a), uv.fs_stat(b)
    local asec, bsec = sa and sa.mtime.sec or 0, sb and sb.mtime.sec or 0
    if asec ~= bsec then return asec > bsec end
    local ansec, bnsec = sa and sa.mtime.nsec or 0, sb and sb.mtime.nsec or 0
    if ansec ~= bnsec then return ansec > bnsec end
    return a > b
  end)
  for _, path in ipairs(paths) do
    if is_root_for_cwd(path, cwd, transcript) then return path, true end
  end
end

-- Read the current window plus `compact_windows` preceding windows (one by
-- default). A `compacted` record begins a window, so retain the corresponding
-- record; with too few compactions, retain the whole file.
local function transcript_tail(path, transcript, compact_windows)
  local wanted = (compact_windows or 1) + 1
  local seen, count = {}, 0
  local function boundary_cut(buf, at_file_start, window_offset)
    local from, cuts = 1, {}
    while true do
      local marker = buf:find('"type":"compacted"', from, true)
      if not marker then break end
      from = marker + 1
      local line_start, p = nil, 1
      while true do
        local newline = buf:find("\n", p, true)
        if not newline or newline >= marker then break end
        line_start, p = newline + 1, newline + 1
      end
      cuts[#cuts + 1] = line_start or 1
    end
    table.sort(cuts, function(a, b) return a > b end)
    for _, cut in ipairs(cuts) do
      local absolute = window_offset + cut - 1
      if not seen[absolute] then
        seen[absolute], count = true, count + 1
        if count == wanted then return cut end
      end
    end
    return at_file_start and 1 or nil
  end
  return transcript.tail(path, boundary_cut)
end

function M.render(path, transcript, compact_windows)
  local text = transcript_tail(path, transcript, compact_windows)
  if not text then return nil end
  local out, blocks, calls = {}, {}, {}
  local push = transcript.push
  local content_text, value_text = transcript.content_text, transcript.value_text

  local function collapsed(label, body, preview)
    transcript.append_block(out, blocks, label, body, { preview = preview })
  end

  local function message(item)
    if type(item) ~= "table" or item.type ~= "message" then return end
    local role, body = item.role, content_text(item.content)
    if body == "" then return end
    local injected = role == "developer" or role == "system"
        or (role == "user" and body:find("<environment_context>", 1, true)
          and body:find("<INSTRUCTIONS>", 1, true))
    if injected then
      collapsed("context", body, body)
    elseif role == "user" or role == "assistant" then
      local lines = {}
      push(lines, body)
      transcript.append_turn(out, blocks, role, lines, nil, true)
    end
  end

  local function tool_call(item)
    local name = item.name or (item.type == "web_search_call" and "WebSearch") or "tool"
    local raw = item.arguments or item.input or item.action or ""
    local input = raw
    if type(raw) == "string" and raw ~= "" then
      local ok, decoded = pcall(vim.json.decode, raw)
      if ok and type(decoded) == "table" then input = decoded end
    end
    local body = value_text(input)
    local hint = type(input) == "table" and value_text(input.command or input.file_path
      or input.path or input.pattern or input.query or input.description or input.prompt or "") or body
    local lang = ""
    if name == "exec" then
      lang = "javascript"
    elseif name == "apply_patch" then
      lang = "diff"
    elseif type(input) == "table" and input.command then
      lang = "bash"
    end
    transcript.append_block(out, blocks, name, body, {
      preview = hint,
      lang = lang,
      blank = false,
    })
    if item.call_id then calls[item.call_id] = name end
  end

  local function tool_output(item)
    local body = value_text(item.output)
    if body == "" then return end
    local name = item.call_id and calls[item.call_id]
    local is_agent = name and (name == "Agent" or name:find("spawn_agent", 1, true))
    transcript.append_block(out, blocks,
      is_agent and "subagent response" or "result", body, {
        preview = is_agent and nil or body,
        blank = false,
      })
  end

  for line in vim.gsplit(text, "\n", { plain = true }) do
    local ok, ev = pcall(vim.json.decode, line)
    if ok and type(ev) == "table" then
      if ev.type == "compacted" and type(ev.payload) == "table" then
        collapsed("context summary (compacted)",
          "Codex stores the carried compaction summary encrypted in its transcript.")
      elseif ev.type == "response_item" and type(ev.payload) == "table" then
        local item = ev.payload
        if item.type == "message" then
          message(item)
        elseif item.type == "function_call" or item.type == "custom_tool_call"
            or item.type == "web_search_call" then
          tool_call(item)
        elseif item.type == "function_call_output" or item.type == "custom_tool_call_output" then
          tool_output(item)
        end
      end
    end
  end
  return out, blocks
end

return M
