local utils = require("core.utils")

local M = {}

local function ts_lang_label()
  local filetype = vim.bo.filetype
  local lang = vim.treesitter.language.get_lang(filetype)
  return lang or filetype or "unknown"
end

local function ts_node_text(node, buf)
  if not node then
    return nil
  end
  return vim.treesitter.get_node_text(node, buf or 0)
end

local function ts_node_name(node, buf)
  if not node then
    return nil
  end
  local name_node = node:field("name")[1]
  if name_node then
    return ts_node_text(name_node, buf)
  end
  for child in node:iter_children() do
    if child:named() then
      local child_type = child:type()
      if child_type == "identifier"
          or child_type == "type_identifier"
          or child_type == "variable_name"
          or child_type:find("name", 1, true) then
        return ts_node_text(child, buf)
      end
    end
  end
  return nil
end

local function ts_node_at_cursor()
  if vim.treesitter.get_node then
    local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = true })
    if ok and node then
      return node
    end
  end
  local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if ok then
    return ts_utils.get_node_at_cursor()
  end
  return nil
end

local function ts_function_node_and_name()
  local node = ts_node_at_cursor()
  while node do
    local node_type = node:type()
    local is_function_def = false
    if node_type:find("call", 1, true) == nil
        and (node_type:find("function", 1, true) or node_type:find("method", 1, true)) then
      if node_type:find("definition", 1, true)
          or node_type:find("declaration", 1, true)
          or node:field("body")[1] ~= nil then
        is_function_def = true
      end
    end
    if is_function_def then
      local name = ts_node_name(node, 0)
      if name and name ~= "" then
        return node, name
      end
    end
    node = node:parent()
  end
  return nil, nil
end

local function ts_class_name_from_node(node)
  while node do
    if node:type():find("class", 1, true) then
      local name = ts_node_name(node, 0)
      if name and name ~= "" then
        return name
      end
    end
    node = node:parent()
  end
  return nil
end

function M.yank_ancestor_name(kind)
  if kind == "function" then
    local _, name = ts_function_node_and_name()
    if name then
      utils.yank_to_register(name)
      return
    end
    vim.notify(string.format("Treesitter unvailable for [%s]", ts_lang_label()), vim.log.levels.WARN)
    return
  end
  if kind == "class" then
    local name = ts_class_name_from_node(ts_node_at_cursor())
    if name then
      utils.yank_to_register(name)
      return
    end
    vim.notify("No class name found at cursor", vim.log.levels.WARN)
    return
  end
  vim.notify("Unsupported Treesitter yank kind", vim.log.levels.WARN)
end

function M.yank_class_method_name()
  local func_node, func_name = ts_function_node_and_name()
  if not func_name then
    vim.notify(string.format("Treesitter unvailable for [%s]", ts_lang_label()), vim.log.levels.WARN)
    return
  end
  local class_name = ts_class_name_from_node(func_node:parent())
  if not class_name then
    vim.notify("No class name found for function", vim.log.levels.WARN)
    return
  end
  utils.yank_to_register(string.format("%s::%s", class_name, func_name))
end

return M
