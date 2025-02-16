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

set timeoutlen=1000
set ttimeoutlen=10

" Disable mouse by default.
set mouse=

" Enable spell checking
set spell
set spelllang=en_us

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
set lbr
set tw=500

set ai " Auto indent
set wrap " Wrap lines
let &showbreak = "↪ " " Show line wrap indicator

""" Misc

set diffopt=vertical
set shellpipe=>

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
        set number
    elseif(&number)
        set norelativenumber
        set nonumber
    else
        set relativenumber
        set nonumber
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

""" Key mappings

let g:mapleader = " "
let g:maplocalleader = "\\"

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

" Fast quit
nnoremap <silent> <leader>q :q<cr>
nnoremap <silent> <leader>Q :q!<cr>

" Copy to system clipboard
map <silent> <leader>y "+y

"" UI

" toggle highlight search
noremap <silent> <leader>uh :set hlsearch! hlsearch?<cr>
" switch between number, relative_number, no_number
noremap <silent> <leader>un :call SwitchNumber()<cr>
" toggle wrap
noremap <silent> <leader>uw :set wrap! wrap?<cr>
" toggle spell checking
noremap <silent> <leader>us :set spell! spell?<cr>

"" Buffers

" open new buffer
noremap <silent> <leader>be :enew<cr>
" delete buffer
noremap <silent> <leader>x :bd<cr>
" write buffer
noremap <silent> <leader>bw :w<cr>
" switch buffers
nnoremap <silent> <tab> :bn<cr>
nnoremap <silent> ]b :bn<cr>
nnoremap <silent> <s-tab> :bp<cr>
nnoremap <silent> [b :bp<cr>
" switch to last edited buffer
noremap <leader>bl <c-^>
" Only keep the current buffer, close all others.
" %bd = delete all buffers; e# = edit the last buffer; bd# = delete the last buffer with "[No Name]".
command! BufOnly silent! execute "%bd|e#|bd#"
noremap <silent> <leader>bo :BufOnly<cr>

""" Tabs
" Open new tab
noremap <silent> <leader>te :tabnew<cr>
" Next tab
noremap <silent> <leader>tn :tabn<cr>
noremap <silent> ]t :tabn<cr>
" Previous tab
noremap <silent> <leader>tp :tabp<cr>
noremap <silent> [t :tabp<cr>
" Close tab
noremap <silent> <leader>tx :tabclose<cr>

"" Windows

" split window vertically
noremap <leader>wv <c-w>v
" split window horizontally
noremap <leader>wh <c-w>s
" make split windows equal size
noremap <leader>we <c-w>=
" close current window
noremap <leader>wx <c-w>c
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

" Switch quicklist
nnoremap [q :cprev<cr>
nnoremap ]q :cnext<cr>

" Move a line of text
vnoremap <silent> <c-j> :m'>+<cr>`<my`>mzgv`yo`z
vnoremap <silent> <c-k> :m'<-2<cr>`>my`<mzgv`yo`z

" <leader>r to replace selected text
vnoremap <expr> <leader>r ReplaceSelection()

"" Command-line mode.

set cedit=\<C-Y>

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
