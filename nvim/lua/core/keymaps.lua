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
map({ 'n', 'x' }, 'L', '<cmd>bn<cr>', { desc = 'Next buffer' })
map({ 'n', 'x' }, 'H', '<cmd>bp<cr>', { desc = 'Previous buffer' })
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
map("t", "<C-\\><C-r>", function()
  local registers = '*+"-:.%/#=_abcdefghijklmnopqrstuvwxyz0123456789'
  local lines = {}
  for i = 1, #registers do
    local key = registers:sub(i, i)
    local ok, value = pcall(vim.fn.getreg, key, 1)
    if ok and value ~= "" then
      value = vim.fn.keytrans(value --[[@as string]])
          :gsub("<Space>", " ")
          :gsub("<CR>", "\\n")
          :gsub("<NL>", "\\n")
          :sub(1, 50)
      table.insert(lines, string.format('"%s: %s', key, value))
    end
  end

  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local width = math.min(60, math.max(unpack(vim.tbl_map(function(l) return #l end, lines))))
  local height = #lines
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Registers ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false

  vim.cmd("redraw")
  local reg = vim.fn.getcharstr()
  vim.api.nvim_win_close(win, true)
  vim.api.nvim_buf_delete(buf, { force = true })

  local content = vim.fn.getreg(reg)
  if content ~= "" then
    vim.api.nvim_paste(content, true, -1)
  end
end, { desc = "Paste register" })

-- Terminal window navigation
map('t', '<C-\\><C-h>', '<cmd>wincmd h<cr>', { desc = 'Move to left window' })
map('t', '<C-\\><C-j>', '<cmd>wincmd j<cr>', { desc = 'Move to lower window' })
map('t', '<C-\\><C-k>', '<cmd>wincmd k<cr>', { desc = 'Move to upper window' })
map('t', '<C-\\><C-l>', '<cmd>wincmd l<cr>', { desc = 'Move to right window' })

-- Enhanced gf/gF mappings:
-- Check for line number after the filename (supports: file:10 or file line(s) 10)
local function open_file_under_cursor(use_other_window)
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

  -- Handle window selection
  if use_other_window then
    -- Find a different window with winfixbuf disabled
    local current_win = vim.api.nvim_get_current_win()
    local target_win = nil
    local windows = vim.api.nvim_tabpage_list_wins(0)

    for _, win in ipairs(windows) do
      if win ~= current_win and not vim.wo[win].winfixbuf then
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
  end

  -- Open the file and jump to line if specified
  local open_file = function()
    vim.cmd("e " .. vim.fn.fnameescape(path))
    if line_number then
      vim.api.nvim_win_set_cursor(0, { line_number, 0 })
    end
  end

  if use_other_window then
    vim.schedule(open_file)
  else
    open_file()
  end
end

map("n", "gf", function() open_file_under_cursor(false) end, { desc = "Open file under cursor in current window" })
map("n", "gF", function() open_file_under_cursor(true) end, { desc = "Open file under cursor in other window" })

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
