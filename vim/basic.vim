"""""""""""""""""""""""
" General
"""""""""""""""""""""""
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

let mapleader = ","
let g:mapleader = ","

set timeoutlen=1000

" Fast saving
nnoremap <leader>w :w!<cr>

" :W sudo saves the file
command W w !sudo tee % > /dev/null

" Fast quit
nnoremap <leader>q :q<cr>
nnoremap <leader><leader>q :q!<cr>

" Fold
nnoremap <space> za
vnoremap <space> zf

" Enable mouse
set mouse=a

""""""""""""""""""""""""""""
" User Interface
""""""""""""""""""""""""""""
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
set lazyredraw

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

"""""""""""""""""""""""""""""""""
" Files, backups and undo
"""""""""""""""""""""""""""""""""
set nowritebackup
set nobackup
" auto create temp_dirs
for d in ['undo', 'swap']
    let p = '~/dotfiles/vim/temp_dirs/'.d
    if !isdirectory(p)
        execute 'silent !mkdir -p '.p.' > /dev/null 2>&1'
    endif
endfor
set undodir=~/dotfiles/vim/temp_dirs/undo//
set undofile
set directory=~/dotfiles/vim/temp_dirs/swap//

""""""""""""""""""""""""""""""""""
" Text, tab and indent related
""""""""""""""""""""""""""""""""""
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
set si " Smart indent
set wrap " Wrap lines

""""""""""""""""""""""""""""""
" Visual mode
""""""""""""""""""""""""""""""
" Make * and # work in visual mode as well
vnoremap <expr> <silent> * SearchSelection(1)
vnoremap <expr> <silent> # SearchSelection(0)

""""""""""""""""""""""""""""""""""""""""""""
" Moving around, tabs, windows and buffers
""""""""""""""""""""""""""""""""""""""""""""
" disable highlight
noremap <silent> <leader><cr> :noh<cr>

" switch tabs
noremap <tab> gt
noremap <s-tab> gT

" switch windows
nnoremap <silent> <c-h> <c-w>h
nnoremap <silent> <c-l> <c-w>l
nnoremap <silent> <c-j> <c-w>j
nnoremap <silent> <c-k> <c-w>k

" create new tab
nnoremap <leader>tn :tabnew<cr>

" go to last accessed tab
let g:lasttab = 1
nnoremap <leader>tl :exe "tabn ".g:lasttab<cr>
au TabLeave * let g:lasttab = tabpagenr()

" Opens a new tab with the current buffer's path
noremap <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
noremap <leader>cd :cd %:p:h<cr>:pwd<cr>

" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab
  set stal=2
catch
endtry

" Return to last edit position when opening files
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

""""""""""""""""""""""""""""""
" Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2

""""""""""""""""""""""""""""""
" Editing
""""""""""""""""""""""""""""""

" use register z for x and s
nnoremap x "zx
nnoremap X "zX
nnoremap s "zs

" Move a line of text
nmap <leader>j mz:m+<cr>`z
nmap <leader>k mz:m-2<cr>`z
vmap <leader>j :m'>+<cr>`<my`>mzgv`yo`z
vmap <leader>k :m'<-2<cr>`>my`<mzgv`yo`z
vmap <c-j> <leader>j
vmap <c-k> <leader>k

" Delete trailing white space on save
func! DeleteTrailingWhitespaces()
    exe "normal mz"
    %s/\s\+$//ge
    exe "normal `z"
endfunc
autocmd BufWrite * :call DeleteTrailingWhitespaces()

vnoremap <leader>y :call CopyToTmux()<cr>

" <leader>r to replace selected text
vnoremap <expr> <leader>r ReplaceSelection()

" Don't lose selection when indenting
xnoremap <  <gv
xnoremap >  >gv

""""""""""""""""""""""""""""""""""""""
" Cope displaying
"""""""""""""""""""""""""""""""""""""""
noremap <leader>cc :botright cope<cr>
noremap <leader>co ggVGy:tabnew<cr>:set syntax=qf<cr>pgg
noremap <leader>cn :cn<cr>
noremap <leader>cp :cp<cr>

""""""""""""""""""""""""""
" Spell checking
""""""""""""""""""""""""""
"  toggle spell checking
noremap <leader>ss :setlocal spell!<cr>

noremap <leader>sn ]s
noremap <leader>sp [s
noremap <leader>sa zg
noremap <leader>s? z=

"""""""""""""""""""""""""""
" Misc
"""""""""""""""""""""""""""
set diffopt=vertical
set shellpipe=>

""""""""""""""""""""""""""""""
" Command mode related
""""""""""""""""""""""""""""""
" Bash like keys for the command line
cnoremap <c-a> <home>
cnoremap <c-e> <end>
cnoremap <c-k> <c-u>

cnoremap <c-p> <up>
cnoremap <c-n> <down>

""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""
function! GetSelection(one_line, escape) range
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    let res = join(lines, a:one_line ? '\n' : "\n")
    if a:escape != ''
        let res = escape(res, a:escape)
    endif
    return res
endfunction

function! CopyToTmux() range
    let s = GetSelection(0, '"')
    call system('echo -n "' . s . '" | tmux loadb -')
    echo "Copied to tmux buffer"
endfunction

function! ReplaceSelection() range
    let cmd = '":\<c-u>%sno/".GetSelection(1, "")."/"'
    return ":\<c-u>call feedkeys(". cmd. ", 'n')\<cr>"
endfunction

function! SearchSelection(forward) range
    let cmd = a:forward ? '"/' : '"?'
    let cmd .= '\<c-u>".GetSelection(1, "")."\<cr>"'
    return ":\<c-u>call feedkeys(". cmd . ", 'n')\<cr>"
endfunction

"""""""""""""""""""
" Fn keys
"""""""""""""""""""
" F2 to switch between number, relative_number, no_number
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
noremap <F2> :call SwitchNumber()<cr>
" F3 to toggle wrap
noremap <F3> :set wrap! wrap?<cr>
" F4 to toggle paste
noremap <F4> :setlocal paste!<cr>
inoremap <F4> <esc>:setlocal paste!<cr>i

" F5 to toggle system clipboard
function! ToggleSystemClipboard()
    if(&clipboard=='unnamed')
        echo 'Using vim built-in clipboard'
        set clipboard=
    else
        echo 'Using system clipboard'
        set clipboard=unnamed
    endif
endfunc
noremap <F5> :call ToggleSystemClipboard()<cr>
