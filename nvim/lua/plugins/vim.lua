local vim_plugins = {}

for _, v in pairs(vim.g.vim_plugins) do
  local plugin = { v, }
  if v == "connorholyday/vim-snazzy" then
    plugin.config = function()
      vim.cmd("colorscheme snazzy")
    end
  end
  table.insert(vim_plugins, plugin)
end

return vim_plugins
