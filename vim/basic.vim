""" General
set nocompatible

set number

" Show incomplete cmds down the bottom
set showcmd

" Sets how many lines of history VIM has to remember
set history=1000

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
"set autoread

set timeoutlen=1000
set ttimeoutlen=10

" Enable mouse
set mouse=a

""" User Interface

" Set 7 lines to the cursor - when moving vertically using j/k
set so=7

" Turn on the wild menu
set wildmenu
set wildmode=longest:full,full

" Ignore compiled files
set wildignore=*.o,*~,*.pyc,*.pyo,*.class,*.swp
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

" Always show current position
set ruler

" Highlight current line
set cursorline

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
" TODO: this seems to cause rendering issues.
" set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Enable syntax highlighting
syntax enable

set background=dark

set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

" Support italic
set t_ZH=[3m
set t_ZR=[23m

" Always show status line and tabline
set laststatus=2
set showtabline=2

if exists('+termguicolors')
  " Fix termguicolors in tmux.
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

set splitbelow
set splitright

if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
endif

""" Files, backups and undo

set nowritebackup
set nobackup
if has("nvim")
    let g:vim_temp_dir_root = '~/dotfiles/nvim/temp_dirs/'
else
    let g:vim_temp_dir_root = '~/dotfiles/vim/temp_dirs/'
    " Create temp dirs if not exist
    for d in ['undo', 'swap']
        let p = g:vim_temp_dir_root.d
        if !isdirectory(p)
            execute 'silent !mkdir -p '.p.' > /dev/null 2>&1'
        endif
    endfor
endif
exec "set undodir=".g:vim_temp_dir_root."/undo//"
set undofile
exec "set directory=".g:vim_temp_dir_root."/swap//"

""" Text, tab and indent related

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" Linebreak on 500 characters
set lbr
set tw=500

set ai " Auto indent
set wrap " Wrap lines

""" Misc

set diffopt=vertical
set shellpipe=>
set iskeyword+=\-

""" Custom commands

" :W sudo saves the file
command W w !sudo tee % > /dev/null

""" Custom functions

func! DeleteTrailingWhitespaces()
    exe "normal mz"
    %s/\s\+$//ge
    exe "normal `z"
endfunc

function! GetSelection(one_line) range
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    let res = join(lines, a:one_line ? '\n' : "\n")
    return res
endfunction

function! ReplaceSelection() range
    let cmd = '":\<c-u>%sno/".GetSelection(1)."/"'
    return ":\<c-u>call feedkeys(". cmd. ", 'n')\<cr>"
endfunction

function! SearchSelection(forward) range
    let cmd = a:forward ? '"/' : '"?'
    let cmd .= '\<c-u>".GetSelection(1)."\<cr>"'
    return ":\<c-u>call feedkeys(". cmd . ", 'n')\<cr>"
endfunction

function! SwitchNumber()
    if(&relativenumber)
        set norelativenumber
        set nonumber
    elseif(&number)
        set relativenumber
        set nonumber
    else
        set norelativenumber
        set number
    endif
endfunc

""" Auto Commands

" Parse syntax from this many lines backwards.
" If syntax is still incorrect, manually reparse syntax with
" ':syntax sync fromstart'.
autocmd BufEnter * syntax sync minlines=5000

" Return to last edit position when opening files
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Delete trailing white space on save
autocmd BufWrite * :call DeleteTrailingWhitespaces()

" Python
" Fold files based on indentation
autocmd FileType python,pyrex set foldmethod=indent
autocmd FileType python,pyrex set foldlevel=99

" C/C++
" Use "//"-style comments
autocmd FileType c,cpp setlocal commentstring=//\ %s
" Don't treat "-" as a keyword
autocmd FileType c,cpp setlocal iskeyword-=\-

""" Key mappings

let mapleader = " "
let g:mapleader = " "

"" Override builtins

" Make * and # work in visual mode as well
vnoremap <expr> <silent> * SearchSelection(1)
vnoremap <expr> <silent> # SearchSelection(0)

" use register z for x and s
nnoremap x "zx
nnoremap X "zX

" Don't lose selection when indenting
xnoremap <  <gv
xnoremap >  >gv

"" Save and quit

" Fast saving
nnoremap <leader>w :w!<cr>

" Fast quit
nnoremap <leader>q :q<cr>
nnoremap <leader>Q :q!<cr>

"" UI

" disable highlight
noremap <leader>uh :noh<cr>
" switch between number, relative_number, no_number
noremap <leader>un :call SwitchNumber()<cr>
" toggle wrap
noremap <leader>uw :set wrap! wrap?<cr>
" toggle spell checking
noremap <leader>us :set spell! spell?<cr>

"" Navigation

" delete buffer
noremap <leader>d :bd<cr>
" switch to last edited buffer
noremap <leader>bl <c-^>

" switch buffers and tabs
nnoremap <tab> :bn<cr>
nnoremap <s-tab> :bp<cr>

" switch windows
nnoremap <silent> <c-h> <c-w>h
nnoremap <silent> <c-l> <c-w>l
nnoremap <silent> <c-j> <c-w>j
nnoremap <silent> <c-k> <c-w>k

" Opens a new buffer with the current buffer's path
noremap <leader>e :edit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
noremap <leader>cd :cd %:p:h<cr>:pwd<cr>

"" Editing

" Move a line of text
vnoremap <c-j> :m'>+<cr>`<my`>mzgv`yo`z
vnoremap <c-k> :m'<-2<cr>`>my`<mzgv`yo`z

" <leader>r to replace selected text
vnoremap <expr> <leader>r ReplaceSelection()

"" Command mode.

" Bash like keys for the command line
cnoremap <c-a> <home>
cnoremap <c-e> <end>
cnoremap <c-k> <c-u>
cnoremap <c-p> <up>
cnoremap <c-n> <down>
