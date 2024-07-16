local vim_plugins = {}

for _, v in pairs(vim.g.vim_plugins) do
  local plugin = {
    v,
    event = "VeryLazy",
  }
  table.insert(vim_plugins, plugin)
end

return vim_plugins
