local utils = require("core.utils")

local treesitter_filetypes = {
  "bash",
  "c",
  "cpp",
  "json",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "python",
  "vim",
  "vimdoc",
  "yaml",
}

-- Return node text, handling nil nodes and buffer selection.
local function ts_node_text(node, buf)
  if not node then
    return nil
  end
  return vim.treesitter.get_node_text(node, buf or 0)
end

-- Best-effort name lookup for a node across language grammars.
local function ts_node_name(node, buf)
  if not node then
    return nil
  end
  -- Prefer explicit "name" field when grammars expose it.
  local name_node = node:field("name")[1]
  if name_node then
    return ts_node_text(name_node, buf)
  end
  -- Fall back to identifier-like children for looser grammars.
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

-- Fetch the smallest Treesitter node at the cursor, if available.
local function ts_node_at_cursor()
  if vim.treesitter.get_node then
    local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = true })
    if ok and node then
      return node
    end
  end
  -- Compatibility fallback for older Treesitter utils.
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
    -- Skip call nodes; accept definition/declaration-ish nodes.
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
    -- Walk up to the next enclosing node.
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

-- Walk up the AST and yank the nearest function/class definition name.
local function yank_ts_ancestor_name(kind)
  if kind == "function" then
    local _, name = ts_function_node_and_name()
    if name then
      utils.yank_to_register(name)
      return
    end
    vim.notify("No function name found at cursor", vim.log.levels.WARN)
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

local function yank_ts_class_method_name()
  local func_node, func_name = ts_function_node_and_name()
  if not func_name then
    vim.notify("No function name found at cursor", vim.log.levels.WARN)
    return
  end
  -- Find the nearest enclosing class for the function.
  local class_name = ts_class_name_from_node(func_node:parent())
  if not class_name then
    vim.notify("No class name found for function", vim.log.levels.WARN)
    return
  end
  utils.yank_to_register(string.format("%s::%s", class_name, func_name))
end

local function setup_treesitter_filetype_features(buf)
  vim.treesitter.start(buf)
  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  vim.opt_local.foldmethod = "expr"
  if vim.treesitter.foldexpr then
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  else
    vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
  end
  vim.opt_local.foldenable = false
end

local function setup_treesitter(_, _)
  local ts = require("nvim-treesitter")
  ts.setup({})
  if #treesitter_filetypes > 0 then
    ts.install(treesitter_filetypes)
  end

  -- Tree-sitter based folding/highlighting.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = treesitter_filetypes,
    callback = function(args)
      setup_treesitter_filetype_features(args.buf)
    end,
  })
end

local function setup_treesitter_context(_, _)
  require("treesitter-context").setup {
    multiline_threshold = 1,
  }
  vim.cmd([[
    hi TreesitterContextBottom gui=underline guisp=Grey
    hi TreesitterContextLineNumberBottom gui=underline guisp=Grey
  ]])
  vim.keymap.set("n", "[x", function()
    require("treesitter-context").go_to_context()
  end, { desc = "Go to context beginning" })
end

local treesitter_textobjects_opts = {
  select = {
    enable = false,
  },
  move = {
    enable = true,
    set_jumps = true,
    goto_next_start = {
      ["]k"] = { query = "@block.outer", desc = "Next block start" },
      ["]f"] = { query = "@function.outer", desc = "Next function start" },
      ["]a"] = { query = "@parameter.inner", desc = "Next parameter start" },
      ["]C"] = { query = "@class.outer", desc = "Next class start" },
    },
    goto_next_end = {
      ["]K"] = { query = "@block.outer", desc = "Next block end" },
      ["]F"] = { query = "@function.outer", desc = "Next function end" },
      ["]A"] = { query = "@parameter.inner", desc = "Next parameter end" },
    },
    goto_previous_start = {
      ["[k"] = { query = "@block.outer", desc = "Previous block start" },
      ["[f"] = { query = "@function.outer", desc = "Previous function start" },
      ["[a"] = { query = "@parameter.inner", desc = "Previous parameter start" },
      ["[C"] = { query = "@class.outer", desc = "Previous class start" },
    },
    goto_previous_end = {
      ["[K"] = { query = "@block.outer", desc = "Previous block end" },
      ["[F"] = { query = "@function.outer", desc = "Previous function end" },
      ["[A"] = { query = "@parameter.inner", desc = "Previous parameter end" },
    },
  },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    keys = {
      { "<leader>ym", function() yank_ts_ancestor_name("function") end, desc = "Yank method/function name", ft = treesitter_filetypes },
      { "<leader>yc", function() yank_ts_ancestor_name("class") end, desc = "Yank class name", ft = treesitter_filetypes },
      { "<leader>yM", yank_ts_class_method_name, desc = "Yank class::method name", ft = treesitter_filetypes },
    },
    config = setup_treesitter,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        opts = treesitter_textobjects_opts,
      },
      {
        "nvim-treesitter/nvim-treesitter-context",
        config = setup_treesitter_context,
      }
    },
  },
}
