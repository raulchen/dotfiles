""" General
set nocompatible

set number
set relativenumber

" Show incomplete cmds down the bottom
set showcmd

" Sets how many lines of history VIM has to remember
set history=1000

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
"set autoread

set timeoutlen=500
set ttimeoutlen=10

" Disable mouse by default.
set mouse=

" Enable spell checking
set spell
set spelllang=en_us

""" User Interface

" Set 7 lines to the cursor - when moving vertically using j/k
set scrolloff=7

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
set hidden

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
set matchtime=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=

" Enable syntax highlighting
syntax enable

set background=dark

set encoding=utf8

" Use Unix as the standard file type
set fileformats=unix,dos,mac

" Support italic
set t_ZH=[3m
set t_ZR=[23m

" Always show status line and tabline
set laststatus=2
set showtabline=2

if !has("nvim") && exists('+termguicolors')
  set termguicolors
endif

set splitbelow
set splitright

if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
endif

""" Files, backups and undo

set undofile
if !has("nvim")
    let g:vim_data_dir = '~/.local/share/vim/'
    " Create temp dirs if not exist
    for d in ['undo', 'swap']
        let p = g:vim_data_dir.d
        if !isdirectory(p)
            execute 'silent !mkdir -p '.p.' > /dev/null 2>&1'
        endif
    endfor
    exec "set undodir=".g:vim_data_dir."/undo//"
    exec "set directory=".g:vim_data_dir."/swap//"
endif

""" Text, tab and indent related

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" Linebreak on 500 characters
set linebreak
set textwidth=500

set autoindent
set wrap " Wrap lines
let &showbreak = "↪ " " Show line wrap indicator

""" Custom commands

" :W sudo saves the file
command W w !sudo tee % > /dev/null

""" Auto Commands

" Parse syntax from this many lines backwards.
" If syntax is still incorrect, manually reparse syntax with
" ':syntax sync fromstart'.
autocmd BufEnter * syntax sync minlines=5000

" Return to last edit position when opening files
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Delete trailing white space on save
func! DeleteTrailingWhitespaces()
    exe "normal mz"
    %s/\s\+$//ge
    exe "normal `z"
endfunc
autocmd BufWrite * :call DeleteTrailingWhitespaces()

" Python
" Fold files based on indentation
autocmd FileType python,pyrex set foldmethod=indent
autocmd FileType python,pyrex set foldlevel=99

" C/C++
" Use "//"-style comments
autocmd FileType c,cpp setlocal commentstring=//\ %s

""" Key mappings

let g:mapleader = " "
let g:maplocalleader = "\\"

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

function! YankToClipboard(value)
    call setreg('+', a:value)
endfunction

function! SwitchNumber()
    if(&relativenumber)
        set norelativenumber
        set number
    elseif(&number)
        set norelativenumber
        set nonumber
    else
        set relativenumber
        set nonumber
    endif
endfunc

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

" Copy/paste using system clipboard.
nnoremap <silent> gy "+y
xnoremap <silent> gy "+y
nnoremap <silent> gp "+p
xnoremap <silent> gp "+p
nnoremap <silent> gP "+P
xnoremap <silent> gP "+P

nnoremap <silent> <leader>yy :call YankToClipboard(expand('%'))<cr>
nnoremap <silent> <leader>ya :call YankToClipboard(expand('%:p'))<cr>
nnoremap <silent> <leader>yf :call YankToClipboard(expand('%:t'))<cr>
nnoremap <silent> <leader>yd :call YankToClipboard(expand('%:p:h'))<cr>
nnoremap <silent> <leader>yl :call YankToClipboard(expand('%:p').':'.line('.'))<cr>

" Make n/N direction consistent regardless of / or ? search.
nnoremap <expr> n (v:searchforward ? 'n' : 'N').'zv'
xnoremap <expr> n (v:searchforward ? 'n' : 'N')
onoremap <expr> n (v:searchforward ? 'n' : 'N')
nnoremap <expr> N (v:searchforward ? 'N' : 'n').'zv'
xnoremap <expr> N (v:searchforward ? 'N' : 'n')
onoremap <expr> N (v:searchforward ? 'N' : 'n')

"" UI

" toggle highlight search
nnoremap <silent> <leader>uh :set hlsearch! hlsearch?<cr>
" switch between number, relative_number, no_number
nnoremap <silent> <leader>un :call SwitchNumber()<cr>
" toggle wrap
nnoremap <silent> <leader>uw :set wrap! wrap?<cr>
" toggle spell checking
nnoremap <silent> <leader>us :set spell! spell?<cr>

"" Buffers

" open new buffer
nnoremap <silent> <leader>be :enew<cr>
" delete buffer
nnoremap <silent> <leader>x :bd<cr>
nnoremap <silent> <leader>bx :bd<cr>
" write buffer
nnoremap <silent> <leader>bw :w<cr>
" switch buffers
nnoremap <silent> <tab> :bn<cr>
xnoremap <silent> <tab> :bn<cr>
nnoremap <silent> ]b :bn<cr>
nnoremap <silent> <s-tab> :bp<cr>
xnoremap <silent> <s-tab> :bp<cr>
nnoremap <silent> [b :bp<cr>
nnoremap <silent> L :bn<cr>
xnoremap <silent> L :bn<cr>
nnoremap <silent> H :bp<cr>
xnoremap <silent> H :bp<cr>
" switch to last edited buffer
nnoremap <leader>bl <c-^>
" Only keep the current buffer, close all others.
" %bd = delete all buffers; e# = edit the last buffer; bd# = delete the last buffer with "[No Name]".
command! BufOnly silent! execute "%bd|e#|bd#"
nnoremap <silent> <leader>bo :BufOnly<cr>

""" Tabs
" Tab mappings.
nnoremap <silent> <leader><tab>e :tabnew<cr>
nnoremap <silent> <leader><tab>n :tabn<cr>
xnoremap <silent> <leader><tab>n :tabn<cr>
nnoremap <silent> ]<tab> :tabn<cr>
xnoremap <silent> ]<tab> :tabn<cr>
nnoremap <silent> <leader><tab>p :tabp<cr>
xnoremap <silent> <leader><tab>p :tabp<cr>
nnoremap <silent> [<tab> :tabp<cr>
xnoremap <silent> [<tab> :tabp<cr>
nnoremap <silent> <leader><tab>x :tabclose<cr>
nnoremap <silent> <leader><tab>s :tab split<cr>

"" Windows

" split window vertically
nnoremap <leader>wv <c-w>v
" split window horizontally
nnoremap <leader>wh <c-w>s
" make split windows equal size
nnoremap <leader>we <c-w>=
" close current window
nnoremap <leader>wx <c-w>c
nnoremap <leader>ww <c-w>p
" increase window height
nnoremap <leader>w= <c-w>+
" decrease window height
nnoremap <leader>w- <c-w>-
" increase window width
nnoremap <leader>w. <c-w>>
" decrease window width
nnoremap <leader>w, <c-w><
" switch windows
nnoremap <silent> <c-h> <c-w>h
nnoremap <silent> <c-l> <c-w>l
nnoremap <silent> <c-j> <c-w>j
nnoremap <silent> <c-k> <c-w>k
tnoremap <silent> <c-\><c-h> <c-\><c-n><c-w>h
tnoremap <silent> <c-\><c-j> <c-\><c-n><c-w>j
tnoremap <silent> <c-\><c-k> <c-\><c-n><c-w>k
tnoremap <silent> <c-\><c-l> <c-\><c-n><c-w>l

" Terminal escape
tnoremap <c-\><c-\> <c-\><c-n>

" Esc to clear search highlights.
nnoremap <silent> <esc> :nohlsearch<cr><esc>

" Clear search, diff update and redraw
nnoremap <silent> <leader>ur :nohlsearch<bar>diffupdate<bar>normal! <c-l><cr>

" Switch quicklist
nnoremap [q :cprev<cr>
nnoremap ]q :cnext<cr>

" Move a line of text
vnoremap <silent> <c-j> :m'>+<cr>`<my`>mzgv`yo`z
vnoremap <silent> <c-k> :m'<-2<cr>`>my`<mzgv`yo`z

"" Command-line mode.

" Edit command line
set cedit=\<C-X>\<C-E>

" Emacs-style key mappings for the command line (`:help emacs-keys`).
" start of line
cnoremap <C-A> <Home>
" back one character
cnoremap <C-B> <Left>
" also bind <C-V> to <Left> because <C-B> is tmux prefix
cnoremap <C-V> <Left>
" delete character under cursor
cnoremap <C-D> <Del>
" end of line
cnoremap <C-E> <End>
" forward one character
cnoremap <C-F> <Right>
" recall newer command-line
cnoremap <C-N> <Down>
" recall previous (older) command-line
cnoremap <C-P> <Up>
" back one word
cnoremap <Esc><C-B> <S-Left>
" forward one word
cnoremap <Esc><C-F> <S-Right>

" Insert the path of the current file's directory.
cnoremap <c-x><c-d> <C-R>=expand('%:p:h')."/"<CR>
" Insert the path of the current file.
cnoremap <c-x><c-f> <C-R>=expand('%:p')<CR>
