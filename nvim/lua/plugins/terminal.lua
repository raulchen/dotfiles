-- Helper function to focus or start a terminal
local function focus_or_start_terminal(term)
  if term:is_active() then
    term:focus()
  else
    -- Terminal was cleaned up, restart it
    term:start()
    term:focus()
  end
end

local function toggle_terminal(count)
  local ergoterm = require("ergoterm")

  local is_regular_term = function(term)
    return term and #(term.tags or {}) == 0
  end

  -- Check if current buffer is already a terminal
  local current_term = ergoterm.identify()
  if is_regular_term(current_term) then
    -- Hide the current terminal
    ---@diagnostic disable-next-line: need-check-nil
    current_term:close()
    return
  end

  -- If both count and vim.v.count are absent, toggle the last used terminal
  if not count and (not vim.v.count or vim.v.count == 0) then
    local last_term = ergoterm.get_state("last_focused")
    if is_regular_term(last_term) then
      focus_or_start_terminal(last_term)
      return
    end
    -- If no last terminal exists, fall through to default behavior (terminal 1)
  end

  -- Otherwise, open the terminal named $count
  count = count or (vim.v.count > 0 and vim.v.count) or 1
  local term_name = tostring(count)
  local term = ergoterm.get_by_name(term_name)

  if term then
    -- Terminal exists, focus it
    focus_or_start_terminal(term)
  else
    -- Create new terminal with the given name
    term = ergoterm:new({
      name = term_name,
      layout = "below",
    })
    term:start()
  end
end

local ergoterm_keys = {
  { "<c-/>", toggle_terminal, desc = "Toggle terminal", mode = { "n", "t" } },
  { "<c-_>", toggle_terminal, desc = "Toggle terminal", mode = { "n", "t" } },
  { "<leader>ft", "<cmd>TermSelect<cr>", desc = "Pick a terminal" },
}

-- Map <A-1> to <A-9> to toggle terminals 1 to 9
for i = 1, 9 do
  table.insert(ergoterm_keys, {
    "<A-" .. i .. ">",
    function() toggle_terminal(i) end,
    desc = "Toggle terminal " .. i,
    mode = { "n" },
    remap = false,
  })
  table.insert(ergoterm_keys, {
    "<A-" .. i .. ">",
    function() toggle_terminal(i) end,
    desc = "Toggle terminal " .. i,
    mode = { "t" },
    remap = false,
  })
end

local ergoterm_opts = {
  terminal_defaults = {
    float_winblend = 0,
    size = {
      right = "50%",
      below = "45%",
    },
    -- Remember insert/normal mode between focus sessions
    persist_mode = true,
    -- Set winbar to show terminal name and current directory (skip floating terminals)
    on_open = function(term)
      -- Don't set winbar for floating terminals
      if term._state.layout == "float" then
        return
      end
      vim.schedule(function()
        local win = vim.fn.bufwinid(term._state.bufnr)
        if win ~= -1 then
          local name = term.name or "terminal"
          local dir = term._state.dir or vim.fn.getcwd()
          local home = vim.fn.expand("~")
          if vim.startswith(dir, home) then
            dir = "~" .. dir:sub(#home + 1)
          end
          vim.api.nvim_set_option_value(
            "winbar",
            string.format("  %s   %s", name, dir),
            { scope = "local", win = win }
          )
        end
      end)
    end,
  },
}

-- BEGIN AI AGENTS CONFIGURATION --

-- Agent instances (module-level for persistence)
local agents = {}

local function ensure_ai_agents()
  if agents.chats then
    return agents
  end

  local ergoterm = require("ergoterm")

  -- Create factory with shared defaults for AI agents
  local ai_chats = ergoterm.with_defaults({
    layout = "right",
    tags = { "ai_chat" },
    auto_list = false,
    bang_target = false,
    sticky = true,
    watch_files = true,
  })

  -- Create agent instances
  agents.cursor_agent = ai_chats:new({
    cmd = "cursor-agent",
    name = "cursor-agent",
    meta = {
      add_file = function(file) return "@" .. file end,
      add_lines = function(file, start_line, end_line)
        if start_line == end_line then
          return "@" .. file .. ":" .. start_line
        else
          return "@" .. file .. ":" .. start_line .. ":" .. end_line
        end
      end,
    },
  })

  agents.claude_code = ai_chats:new({
    cmd = "claude",
    name = "claude code",
    meta = {
      add_file = function(file) return "@" .. file end,
      add_lines = function(file, start_line, end_line)
        if start_line == end_line then
          return "@" .. file .. ":" .. start_line
        else
          return "@" .. file .. ":" .. start_line .. ":" .. end_line
        end
      end,
    },
  })

  agents.codex = ai_chats:new({
    cmd = "codex",
    name = "codex",
    meta = {
      add_file = function(file) return "@" .. file end,
      add_lines = function(file, start_line, end_line)
        if start_line == end_line then
          return "@" .. file .. ":" .. start_line
        else
          return "@" .. file .. ":" .. start_line .. ":" .. end_line
        end
      end,
    },
  })

  agents.chats = { agents.cursor_agent, agents.claude_code, agents.codex }
  agents.filtered_chats = ergoterm.filter_by_tag("ai_chat")

  return agents
end

-- Check if a terminal is an AI agent
local function is_ai_agent(term)
  if not term then
    return false
  end
  return vim.tbl_contains(term.tags or {}, "ai_chat")
end

-- Helper function to select AI agent and send content
-- If last_focused is an AI agent, use it as default with select_started
-- Otherwise, prompt to choose which agent to launch
local function select_ai_agent_and_send(prompt, send_callback)
  ensure_ai_agents()
  local ergoterm = require("ergoterm")
  local last_focused = ergoterm.get_state("last_focused")
  local default_agent = (last_focused and is_ai_agent(last_focused)) and last_focused or nil
  if not default_agent then
    -- Prompt to choose which agent to launch
    ergoterm.select({
      terminals = agents.chats,
      prompt = prompt,
      callbacks = function(term)
        term:start()
        term:focus()
        send_callback(term)
      end,
    })
  else
    ergoterm.select_started({
      terminals = agents.filtered_chats,
      prompt = prompt,
      callbacks = send_callback,
      default = default_agent,
    })
  end
end

-- Toggle agent terminal window, prompt to choose which agent for the first time
local function toggle_ai_agent()
  ensure_ai_agents()
  local ergoterm = require("ergoterm")

  -- Check if any agent is currently active
  local active_chat = nil
  for _, chat in ipairs(agents.chats) do
    if chat:is_active() then
      active_chat = chat
      break
    end
  end

  if active_chat then
    -- If an agent is active, toggle it
    active_chat:toggle()
  else
    -- If no agent is active, check if last focused terminal is an AI agent
    local last_focused = ergoterm.get_state("last_focused")
    if last_focused and is_ai_agent(last_focused) then
      -- Use last focused AI agent if available
      last_focused:start()
      last_focused:focus()
    else
      -- Show picker to choose agent
      ergoterm.select({
        terminals = agents.chats,
        prompt = "Select AI Agent to Launch",
        callbacks = function(term)
          term:start()
          term:focus()
        end,
      })
    end
  end
end

-- Add the current buffer
local function add_current_buffer()
  local file = vim.fn.expand("%:p")
  select_ai_agent_and_send("Add file to chat", function(term)
    term:send({ term.meta.add_file(file) }, { new_line = false })
  end)
end

-- Add the line or selected lines (only line numbers) - normal mode
local function add_line_numbers()
  local file = vim.fn.expand("%:p")
  local line = vim.api.nvim_win_get_cursor(0)[1]
  select_ai_agent_and_send("Add line numbers to chat", function(term)
    term:send({ term.meta.add_lines(file, line, line) }, { new_line = false })
  end)
end

-- Add the line or selected lines (only line numbers) - visual mode
local function add_selected_line_numbers()
  local file = vim.fn.expand("%:p")
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  select_ai_agent_and_send("Add line numbers to chat", function(term)
    term:send({ term.meta.add_lines(file, start_line, end_line) }, { new_line = false })
  end)
end

-- Send the contents - normal mode
local function send_line_contents()
  select_ai_agent_and_send("Send line to chat", function(term)
    term:send("single_line")
  end)
end

-- Send the contents - visual mode
local function send_selection_contents()
  select_ai_agent_and_send("Send selection to chat", function(term)
    term:send("visual_selection", { trim = false })
  end)
end

-- List and switch agents
local function list_switch_agents()
  ensure_ai_agents()
  local ergoterm = require("ergoterm")
  ergoterm.select({
    terminals = agents.chats,
    prompt = "Select AI Agent",
    callbacks = function(term)
      if term:is_active() then
        term:focus()
      else
        term:start()
        term:focus()
      end
    end,
  })
end

-- AI Agent keymaps
table.insert(ergoterm_keys, { "<leader>aa", toggle_ai_agent, desc = "Toggle AI Agent" })
table.insert(ergoterm_keys, { "<leader>ab", add_current_buffer, desc = "Add Current Buffer to AI Agent" })
table.insert(ergoterm_keys, { "<leader>as", add_line_numbers, desc = "Add Line Numbers to AI Agent" })
table.insert(ergoterm_keys,
  { "<leader>as", add_selected_line_numbers, desc = "Add Selected Line Numbers to AI Agent", mode = "v" })
table.insert(ergoterm_keys, { "<leader>aS", send_line_contents, desc = "Send Line Contents to AI Agent" })
table.insert(ergoterm_keys,
  { "<leader>aS", send_selection_contents, desc = "Send Selection Contents to AI Agent", mode = "v" })
table.insert(ergoterm_keys, { "<leader>al", list_switch_agents, desc = "List and Switch AI Agents" })

-- END AI AGENTS CONFIGURATION --

return {
  "waiting-for-dev/ergoterm.nvim",
  keys = ergoterm_keys,
  cmd = {
    "TermNew",
    "TermSelect",
    "TermSend",
    "TermUpdate",
    "TermInspect",
    "TermToggleUniversalSelection",
  },
  opts = ergoterm_opts,
}
