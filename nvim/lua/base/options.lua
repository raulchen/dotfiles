local opt = vim.opt

-- General settings

-- Show line numbers
opt.number = true

-- Show relative line numbers
opt.relativenumber = true

-- Show incomplete commands at bottom
opt.showcmd = true

-- Sets how many lines of history VIM has to remember
opt.history = 1000

-- Time to wait for mapped sequence
opt.timeoutlen = 500

-- Time to wait for key code sequence
opt.ttimeoutlen = 10

-- Disable mouse by default
opt.mouse = ''

-- Enable spell checking
opt.spell = true

-- Set spellcheck language
opt.spelllang = 'en_us'

-- User Interface settings

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

-- Height of the command bar
opt.cmdheight = 1

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

-- For regular expressions turn magic on
opt.magic = true

-- Show matching brackets when text indicator is over them
opt.showmatch = true

-- How many tenths of a second to blink when matching brackets
opt.matchtime = 2

-- No annoying sound on errors
opt.errorbells = false

-- No visual bell
opt.visualbell = false

-- Use dark background
opt.background = 'dark'

-- Set encoding
opt.encoding = 'utf8'

-- Use Unix line endings
opt.fileformats = 'unix,dos,mac'

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

-- Files/backups settings

-- Persistent undo history
opt.undofile = true

-- Text/tabs settings

-- Use spaces instead of tabs
opt.expandtab = true

-- Smart tab handling
opt.smarttab = true

-- 1 tab == 4 spaces
opt.shiftwidth = 4
opt.tabstop = 4

-- Linebreak on 500 characters
opt.linebreak = true

-- Maximum text width
opt.textwidth = 500

-- Maintain indent
opt.autoindent = true

-- Wrap long lines
opt.wrap = true

-- Show line wrap indicator
opt.showbreak = '↪ '
