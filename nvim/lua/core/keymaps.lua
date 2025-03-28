local map = vim.keymap.set

-- Leader configuration
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Buffer management
map('n', '<leader>be', '<cmd>enew<cr>', { desc = 'Create new buffer' })
map('n', '<leader>x', '<cmd>bd<cr>', { desc = 'Delete current buffer' })
map('n', '<leader>bw', '<cmd>w<cr>', { desc = 'Save current buffer' })
map({ 'n', 'x' }, '<tab>', '<cmd>bn<cr>', { desc = 'Next buffer' })
map({ 'n', 'x' }, ']b', '<cmd>bn<cr>', { desc = 'Next buffer' })
map({ 'n', 'x' }, '<s-tab>', '<cmd>bp<cr>', { desc = 'Previous buffer' })
map({ 'n', 'x' }, '[b', '<cmd>bp<cr>', { desc = 'Previous buffer' })
map('n', '<leader>bl', '<c-^>', { desc = 'Switch to last buffer' })

-- Tab management
map('n', '<leader>te', '<cmd>tabnew<cr>', { desc = 'Create new tab' })
map({ 'n', 'x' }, '<leader>tn', '<cmd>tabn<cr>', { desc = 'Next tab' })
map({ 'n', 'x' }, ']t', '<cmd>tabn<cr>', { desc = 'Next tab' })
map({ 'n', 'x' }, '<leader>tp', '<cmd>tabp<cr>', { desc = 'Previous tab' })
map({ 'n', 'x' }, '[t', '<cmd>tabp<cr>', { desc = 'Previous tab' })
map('n', '<leader>tx', '<cmd>tabclose<cr>', { desc = 'Close current tab' })

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

-- Switch quickfix
map("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

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

-- Command line mappings
-- Ctrl-Y to edit command line
vim.cmd([[set cedit=\<C-Y>]])
-- Emacs-style navigation
map('c', '<C-A>', '<Home>', { desc = 'Start of line' })
map('c', '<C-B>', '<Left>', { desc = 'Move left' })
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
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to left window" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to lower window" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to upper window" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to right window" })

-- Super-tab
map({ 'i', 's' }, '<Tab>', function()
  if require("copilot.suggestion").is_visible() then
    require("copilot.suggestion").accept()
  elseif require("luasnip").expand_or_jumpable() then
    require("luasnip").expand_or_jump()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
  end
end, { desc = "Super Tab" })

map({ 'i', 's' }, '<S-Tab>', function()
  if require("luasnip").jumpable(-1) then
    require("luasnip").jump(-1)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
  end
end, { desc = "Super S-Tab" })

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
