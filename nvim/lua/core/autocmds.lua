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

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight on yank",
  group = general_group,
  callback = function()
    vim.highlight.on_yank({ timeout = 300 })
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  desc = "Auto create parent dir when saving a file",
  group = general_group,
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    local dir = vim.fn.fnamemodify(file, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      if vim.fn.confirm("Create directory: " .. dir .. "?", "&Yes\n&No") == 1 then
        vim.fn.mkdir(dir, "p")
      end
    end
  end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  desc = "Equalize window sizes when vim is resized",
  group = general_group,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Filetype specific settings

vim.api.nvim_create_autocmd("FileType", {
  desc = "Close some filetypes with <q>",
  group = filetype_group,
  pattern = {
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "startuptime",
    "checkhealth",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

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
