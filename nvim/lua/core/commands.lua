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
