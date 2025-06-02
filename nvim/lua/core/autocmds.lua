local api = vim.api

local general_group = api.nvim_create_augroup('GeneralSettings', { clear = true })

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

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Prompt to resolve symlinks when opening files",
  group = general_group,
  callback = function(event)
    local buf_path = vim.api.nvim_buf_get_name(event.buf)
    -- Skip if the buffer is not a file.
    if vim.fn.filereadable(buf_path) == 0 then
      return
    end
    local real_path = vim.fn.resolve(buf_path)
    if real_path ~= buf_path then
      if vim.fn.confirm("File is a symlink. Resolve to original file?\n" .. real_path, "&Yes\n&No") == 1 then
        vim.schedule(function()
          vim.cmd("ResolveSymlink")
        end
        )
      end
    end
  end,
})

-- Filetype specific settings

local filetype_group = api.nvim_create_augroup('FileTypeSettings', { clear = true })

-- Update formatoptions for all filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = filetype_group,
  pattern = "*",
  callback = function()
    -- Use vim.schedule to ensure that the autocmd runs after the default
    -- formatoptions are set
    vim.schedule(function()
      vim.opt_local.formatoptions = vim.opt_local.formatoptions
          - "t" -- Do not auto-wrap text using textwidth
          - "c" -- Do not auto-wrap comments using textwidth
          - "o" -- Do not insert comment leader after hitting o/O
          + "r" -- Automatically insert the comment leader after hitting Enter
    end)
  end,
})

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
  desc = 'Python autocmd',
  group = filetype_group,
  pattern = { 'python', 'pyrex' },
  callback = function()
    -- Fold based on indentation
    vim.opt_local.foldmethod = 'indent'
    vim.opt_local.foldlevel = 99
    -- Set macro 'p' to print a debug message
    local esc = vim.api.nvim_replace_termcodes('<esc>', true, true, true)
    vim.fn.setreg('p', 'yoprint("=== "' .. esc .. 'PA, )' .. esc .. 'P')
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
