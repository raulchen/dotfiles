local M = {}

---@class CommandPaletteItem
---@field name string Display name for the command
---@field action function|string Function to execute or vim command string
---@field desc? string Optional description
---@field category? string Optional category for grouping

---@type CommandPaletteItem[]
local commands = {}

---Register a command to the command palette.
---@param item CommandPaletteItem|CommandPaletteItem[]
function M.register(item)
  if vim.islist(item) then
    for _, cmd in ipairs(item) do
      M.register(cmd)
    end
    return
  end
  table.insert(commands, item)
end

---Get all buffer-local keymaps for the current mode.
---@return CommandPaletteItem[]
local function get_buffer_keymaps()
  local items = {}
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)

  local keymaps = vim.api.nvim_buf_get_keymap(0, mode)
  for _, km in ipairs(keymaps) do
    local name = km.desc or ""
    local category = km.lhs and km.lhs or nil
    table.insert(items, {
      name = name,
      category = category,
      lhs = km.lhs,
    })
  end

  return items
end

---Open the command palette picker.
function M.open()
  local items = vim.list_extend({}, commands)
  vim.list_extend(items, get_buffer_keymaps())

  if #items == 0 then
    vim.notify("Command palette is empty.", vim.log.levels.WARN)
    return
  end

  table.sort(items, function(a, b)
    local a_cat = a.category or ""
    local b_cat = b.category or ""
    if a_cat == b_cat then
      return a.name < b.name
    end
    return a_cat < b_cat
  end)

  vim.ui.select(items, {
    prompt = "Command Palette",
    format_item = function(cmd)
      local text = cmd.name
      if cmd.category then
        text = string.format("[%s] %s", cmd.category, cmd.name)
      end
      if cmd.desc then
        text = text .. "  " .. cmd.desc
      end
      return text
    end,
  }, function(cmd)
    if cmd then
      if cmd.lhs then
        local keys = vim.api.nvim_replace_termcodes(cmd.lhs, true, false, true)
        vim.api.nvim_feedkeys(keys, "m", false)
      elseif type(cmd.action) == "function" then
        cmd.action()
      elseif type(cmd.action) == "string" then
        vim.cmd(cmd.action)
      end
    end
  end)
end

---Get all registered commands.
---@return CommandPaletteItem[]
function M.get_commands()
  return commands
end

---Clear all registered commands.
function M.clear()
  commands = {}
end

return M
