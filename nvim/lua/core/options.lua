local opt = vim.opt

-------------------
-- General settings
-------------------

-- Show line numbers
opt.number = true

-- Show relative line numbers
opt.relativenumber = true

-- Show incomplete commands at bottom
opt.showcmd = true

-- Time to wait for mapped sequence
opt.timeoutlen = 500

-- Disable mouse by default
opt.mouse = ''

-- Enable spell checking
opt.spell = true

-- Set spellcheck language
opt.spelllang = 'en_us'

-- Confirm to save changes before exiting modified buffer
opt.confirm = true

-- Decrease update time to make features like git signs, code diagnostics,
-- and swap file updates more responsive
opt.updatetime = 1000

--------------------------
-- User Interface settings
--------------------------

-- Set 7 lines to the cursor - when moving vertically using j/k
opt.scrolloff = 7

-- Turn on the wild menu
opt.wildmenu = true

-- Completion behavior: longest:full,full
opt.wildmode = 'longest:full,full'

-- Ignore compiled files
opt.wildignore = {
  '*.o', '*~', '*.pyc', '*.pyo', '*.class', '*.swp',
  vim.fn.has('win32') == 1 and '.git\\*,.hg\\*,.svn\\*' or '*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store'
}

-- Always show current position
opt.ruler = true

-- Highlight current line
opt.cursorline = true

-- Hide cmdline unless needed
opt.cmdheight = 0

-- Configure backspace so it acts as it should act
opt.backspace = 'eol,start,indent'

-- Allow cursor to wrap lines
opt.whichwrap:append('<,>,h,l')

-- Ignore case when searching
opt.ignorecase = true

-- When searching try to be smart about cases
opt.smartcase = true

-- Highlight search results
opt.hlsearch = true

-- Makes search act like search in modern browsers
opt.incsearch = true

-- Enable true color support
opt.termguicolors = true

-- Always show one status line across all windows
opt.laststatus = 3

-- Always show tabline
opt.showtabline = 2

-- New horizontal splits below current
opt.splitbelow = true

-- New vertical splits right of current
opt.splitright = true

-- Merge signcolumn and number column
opt.signcolumn = 'number'

-- Preview substitutions in a split window
opt.inccommand = 'split'

-- W hides “written” messages when saving a file (“filename written”).
-- I hides the intro screen that appears on startup.
-- c hides completion messages like “match 1 of 2”.
-- C hides messages while scanning for completion items.
opt.shortmess:append({ W = true, I = true, c = true, C = true })

-- Override special fill chars
opt.fillchars = {
  diff = "╱",
}

-------------------------
-- Files/backups settings
-------------------------

-- Persistent undo history
opt.undofile = true

---------------------
-- Text/tabs settings
---------------------

-- Use spaces instead of tabs
opt.expandtab = true

-- Smart tab handling
opt.smarttab = true

-- 1 tab == 4 spaces
opt.shiftwidth = 4
opt.tabstop = 4

-- round indentation with `>`/`<` to shiftwidth
opt.shiftround = true
-- Number of space inserted for indentation,
-- when zero the 'tabstop' value will be used
opt.shiftwidth = 0

-- Wrap indent to match line start
opt.breakindent = true

-- Automatically adjusts indentation for new lines based on programming syntax
opt.smartindent = true

-- Ensure lines break only at specific characters (like spaces or hyphens)
opt.linebreak = true

-- Wrap long lines
opt.wrap = true

-- Show line wrap indicator
opt.showbreak = '↪ '
