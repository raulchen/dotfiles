local api = vim.api

local general_group = api.nvim_create_augroup('GeneralSettings', { clear = true })
local filetype_group = api.nvim_create_augroup('FileTypeSettings', { clear = true })

api.nvim_create_autocmd('BufReadPost', {
  desc = 'Return to last cursor position',
  group = general_group,
  pattern = '*',
  callback = function()
    -- Skip `.git/COMMIT_EDITMSG`
    if vim.fn.expand('%:t') == 'COMMIT_EDITMSG' then return end
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

api.nvim_create_autocmd('BufWritePre', {
  desc = 'Trim trailing whitespaces on save',
  group = general_group,
  pattern = '*',
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[keepjumps keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
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
    "gitsigns-blame",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

api.nvim_create_autocmd('FileType', {
  desc = 'Python/Pyrex: Fold based on indentation',
  group = filetype_group,
  pattern = { 'python', 'pyrex' },
  callback = function()
    vim.opt_local.foldmethod = 'indent'
    vim.opt_local.foldlevel = 99
  end
})

api.nvim_create_autocmd('FileType', {
  desc = 'C/C++: Use //-style comments',
  group = filetype_group,
  pattern = { 'c', 'cpp' },
  callback = function()
    vim.opt_local.commentstring = '// %s'
  end
})
