local map = vim.keymap.set

-- Leader configuration
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Buffer management
map('n', '<leader>be', '<cmd>enew<cr>', { desc = 'Create new buffer' })
map('n', '<leader>x', '<cmd>bd<cr>', { desc = 'Delete current buffer' })
map('n', '<leader>bx', '<cmd>bd<cr>', { desc = 'Delete current buffer' })
map('n', '<leader>bw', '<cmd>w<cr>', { desc = 'Save current buffer' })
map({ 'n', 'x' }, '<tab>', '<cmd>bn<cr>', { desc = 'Next buffer' })
map({ 'n', 'x' }, '<s-tab>', '<cmd>bp<cr>', { desc = 'Previous buffer' })
map('n', '<leader>bl', '<c-^>', { desc = 'Switch to last buffer' })

-- Tab management
map('n', '<leader>te', '<cmd>tabnew<cr>', { desc = 'Create new tab' })
map({ 'n', 'x' }, '<leader>tn', '<cmd>tabn<cr>', { desc = 'Next tab' })
map({ 'n', 'x' }, ']t', '<cmd>tabn<cr>', { desc = 'Next tab' })
map({ 'n', 'x' }, '<leader>tp', '<cmd>tabp<cr>', { desc = 'Previous tab' })
map({ 'n', 'x' }, '[t', '<cmd>tabp<cr>', { desc = 'Previous tab' })
map('n', '<leader>tx', '<cmd>tabclose<cr>', { desc = 'Close current tab' })
map('n', '<leader>ts', '<cmd>tab split<cr>', { desc = 'Split current window into new tab' })

-- Window management
map('n', '<leader>wv', '<c-w>v', { desc = 'Vertical split window' })
map('n', '<leader>wh', '<c-w>s', { desc = 'Horizontal split window' })
map('n', '<leader>we', '<c-w>=', { desc = 'Equalize window sizes' })
map('n', '<leader>wx', '<c-w>c', { desc = 'Close current window' })
map('n', '<leader>ww', '<c-w>p', { desc = 'Previous window' })
map('n', '<c-h>', '<c-w>h', { desc = 'Move to left window' })
map('n', '<c-l>', '<c-w>l', { desc = 'Move to right window' })
map('n', '<c-j>', '<c-w>j', { desc = 'Move to lower window' })
map('n', '<c-k>', '<c-w>k', { desc = 'Move to upper window' })

-- UI toggles
map('n', '<leader>uh', '<cmd>set hlsearch!<cr>', { desc = 'Toggle search highlight' })
map('n', '<leader>un', function()
  -- Toggle between number/relativenumber/none
  if vim.wo.relativenumber then
    vim.wo.relativenumber = false
    vim.wo.number = true
  elseif vim.wo.number then
    vim.wo.number = false
  else
    vim.wo.relativenumber = true
  end
end, { desc = 'Toggle line number mode' })

map('n', '<leader>uw', '<cmd>set wrap!<cr>', { desc = 'Toggle line wrapping' })
map('n', '<leader>us', '<cmd>set spell!<cr>', { desc = 'Toggle spell checking' })

-- Text manipulation
map('x', '<', '<gv', { remap = true, desc = 'Indent left (keep selection)' })
map('x', '>', '>gv', { remap = true, desc = 'Indent right (keep selection)' })
map('v', '<c-j>', ":m '>+1<cr>gv=gv", { desc = 'Move line(s) down' })
map('v', '<c-k>', ":m '<-2<cr>gv=gv", { desc = 'Move line(s) up' })

-- System clipboard
map({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to system clipboard' })

-- Make n/N direction consistent regardless of / or ? search
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Command line mappings
-- Ctrl-Y to edit command line
vim.cmd([[set cedit=\<C-Y>]])
-- Emacs-style navigation
map('c', '<C-A>', '<Home>', { desc = 'Start of line' })
map('c', '<C-B>', '<Left>', { desc = 'Move left' })
-- Also map <C-V> to move left, as <C-B> is taken by Tmux.
map('c', '<C-V>', '<Left>', { desc = 'Move left' })
map('c', '<C-D>', '<Del>', { desc = 'Delete character' })
map('c', '<C-E>', '<End>', { desc = 'End of line' })
map('c', '<C-F>', '<Right>', { desc = 'Move right' })
map('c', '<C-N>', '<Down>', { desc = 'Next command' })
map('c', '<C-P>', '<Up>', { desc = 'Previous command' })
map('c', '<Esc><C-B>', '<S-Left>', { desc = 'Back one word' })
map('c', '<Esc><C-F>', '<S-Right>', { desc = 'Forward one word' })
map('c', '<c-x><c-d>', '<C-R>=expand("%:p:h")."/"<cr>', { desc = 'Insert directory path' })
map('c', '<c-x><c-f>', '<C-R>=expand("%:p")<cr>', { desc = 'Insert file path' })

-- Terminal Mappings
map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })

-- Enhanced gf mapping:
-- check for line number after the filename.
-- open file in a different window with winfixbuf disabled
map("n", "gf", function()
  local cwd = vim.fn.getcwd()
  local filename = vim.fn.expand("<cfile>")
  local path = vim.fn.findfile(filename, cwd)
  if path == "" then
    path = vim.fn.finddir(filename, cwd)
  end
  if path == "" then
    vim.notify("No file or directory under cursor", vim.log.levels.WARN)
    return
  end

  -- Check if filename is followed by a line number
  -- Supports: file:10 or file line(s) 10
  local line = vim.fn.getline(".")
  local _, filename_end = line:find(filename, 1, true)
  local line_number = nil
  if filename_end then
    local after_filename = line:sub(filename_end + 1)
    -- Match :10 pattern
    local colon_match = after_filename:match("^%s*:%s*(%d+)")
    if colon_match then
      line_number = tonumber(colon_match)
    else
      -- Match " line 10" or " lines 10" pattern
      local line_match = after_filename:match("^%s*lines?%s+(%d+)")
      if line_match then
        line_number = tonumber(line_match)
      end
    end
  end

  -- Find a different window with winfixbuf disabled
  local current_win = vim.api.nvim_get_current_win()
  local target_win = nil
  local windows = vim.api.nvim_tabpage_list_wins(0)

  -- Check for existing window with winfixbuf disabled (excluding current window)
  for _, win in ipairs(windows) do
    if win ~= current_win and not vim.api.nvim_win_get_option(win, "winfixbuf") then
      target_win = win
      break
    end
  end

  -- Create vertical split if none exists
  if not target_win then
    vim.cmd("vsplit")
    target_win = vim.api.nvim_get_current_win()
  else
    vim.api.nvim_set_current_win(target_win)
  end

  -- Open the file in the target window
  vim.schedule(function()
    vim.cmd("e " .. vim.fn.fnameescape(path))
    if line_number then
      vim.api.nvim_win_set_cursor(0, { line_number, 0 })
    end
  end)
end, { desc = "Open file under cursor" })

-- Esc to clear search highlights
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and clear hlsearch" })

-- Clear search, diff update and redraw
map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / clear hlsearch / diff update" }
)

-- Custom commands
vim.api.nvim_create_user_command('W', 'w !sudo tee % > /dev/null', {
  desc = 'Write file with sudo privileges'
})

-- Command to resolve symlinks
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
