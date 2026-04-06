-- Write file with sudo privileges
vim.api.nvim_create_user_command('W', 'w !sudo tee % > /dev/null', {
  desc = 'Write file with sudo privileges'
})

-- Resolve symlinked file and reopen the original
vim.api.nvim_create_user_command('ResolveSymlink', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  local real_file = vim.fn.resolve(file)

  if real_file ~= file then
    -- Use absolute paths and completely wipe the buffer
    real_file = vim.fn.fnamemodify(real_file, ':p')
    vim.cmd('bwipeout! ' .. bufnr)
    -- Force reload from disk
    vim.cmd('edit! ' .. vim.fn.fnameescape(real_file))
  end
end, { desc = 'Close symlinked buffer and open the original file' })

-- LSP commands removed in Neovim 0.12
vim.api.nvim_create_user_command('LspLog', function()
  vim.cmd.edit(vim.lsp.log.get_filename())
end, { desc = 'Open LSP log file' })

vim.api.nvim_create_user_command('LspInfo', function()
  vim.cmd('checkhealth vim.lsp')
end, { desc = 'Show LSP info via checkhealth' })

vim.api.nvim_create_user_command('LspRestart', function(opts)
  local name = opts.fargs[1]
  local filter = name and { bufnr = 0, name = name } or {}
  local clients = vim.lsp.get_clients(filter)
  for _, client in ipairs(clients) do
    local bufs = client.attached_buffers and vim.tbl_keys(client.attached_buffers) or {}
    client:stop()
    vim.wait(30000, function()
      return vim.lsp.get_client_by_id(client.id) == nil
    end)
    for _, buf in ipairs(bufs) do
      vim.lsp.start(client.config, { bufnr = buf })
    end
  end
end, { desc = 'Restart LSP clients', nargs = '?', complete = function()
  return vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 }))
end })
