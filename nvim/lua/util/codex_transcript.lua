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

-- Inspect newest root rollouts first and choose the first session whose cwd
-- matches. This works without lifecycle hooks or a tmux-specific registry.
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
    local fd = uv.fs_open(path, "r", 438)
    if fd then
      local first = first_line(fd, transcript)
      uv.fs_close(fd)
      local ok, ev = pcall(vim.json.decode, first or "")
      local p = ok and ev.type == "session_meta" and ev.payload or nil
      local parent = p and p.parent_thread_id
      if p and (parent == nil or parent == vim.NIL) and type(p.source) ~= "table"
          and vim.fs.normalize(p.cwd or "") == vim.fs.normalize(cwd) then
        return path
      end
    end
  end
end

-- Read from the latest top-level `compacted` record. That record carries the
-- replacement history and must remain in the tail, unlike Claude's boundary
-- marker, which is discarded by its parser.
local function transcript_tail(path, transcript)
  local function boundary_cut(buf, at_file_start)
    local from, cut = 1, nil
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
      if line_start or at_file_start then cut = line_start or 1 end
    end
    return cut
  end
  return transcript.tail(path, boundary_cut)
end

function M.render(path, transcript)
  local text = transcript_tail(path, transcript)
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
        out, blocks, calls = {}, {}, {}
        for _, item in ipairs(ev.payload.replacement_history or {}) do message(item) end
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
