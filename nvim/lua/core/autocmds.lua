local api = vim.api

local general_group = api.nvim_create_augroup('GeneralSettings', { clear = true })
local filetype_group = api.nvim_create_augroup('FileTypeSettings', { clear = true })

-- Return to last edit position
api.nvim_create_autocmd('BufReadPost', {
  group = general_group,
  pattern = '*',
  callback = function()
    if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
      vim.cmd('normal! g`"')
    end
  end,
  desc = 'Restore last cursor position'
})

-- Delete trailing whitespace on save
api.nvim_create_autocmd('BufWritePre', {
  group = general_group,
  pattern = '*',
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[keepjumps keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
  desc = 'Trim trailing whitespace'
})

-- Filetype specific settings
-- Python/Pyrex: Fold based on indentation
api.nvim_create_autocmd('FileType', {
  group = filetype_group,
  pattern = { 'python', 'pyrex' },
  callback = function()
    vim.opt_local.foldmethod = 'indent'
    vim.opt_local.foldlevel = 99
  end
})

-- C/C++: Use //-style comments
api.nvim_create_autocmd('FileType', {
  group = filetype_group,
  pattern = { 'c', 'cpp' },
  callback = function()
    vim.opt_local.commentstring = '// %s'
  end
})
