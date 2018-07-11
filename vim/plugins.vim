set rtp+=~/dotfiles/vim
call plug#begin('~/dotfiles/vim/installed_plugins')

" General
Plug 'scrooloose/nerdtree'
Plug 'haya14busa/incsearch.vim'
Plug 'amix/open_file_under_cursor.vim'
Plug 'easymotion/vim-easymotion'
Plug 'terryma/vim-expand-region'
Plug 'michaeljsmith/vim-indent-object'
Plug 'dyng/ctrlsf.vim'
Plug 'google/vim-searchindex'
for p in ['~/.fzf', '/usr/local/opt/fzf']
    if isdirectory(expand(p))
        Plug p
        Plug 'junegunn/fzf.vim'
        break
    endif
endfor

" Edit
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-repeat'
Plug 'maxbrunsfeld/vim-yankstack'
Plug 'jiangmiao/auto-pairs'
Plug 'mbbill/undotree', {'on': 'UndotreeToggle'}
Plug 'tpope/vim-sleuth'

" UI
Plug 'itchyny/lightline.vim'
Plug 'mgee/lightline-bufferline'
Plug 'dracula/vim', {'as': 'dracula-vim'}
Plug 'jszakmeister/vim-togglecursor'
Plug 'majutsushi/tagbar'

" Source control
Plug 'mhinz/vim-signify'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim', {'on': 'GV'}
Plug 'jlfwong/vim-mercenary'

" Language support
Plug 'sheerun/vim-polyglot'
Plug 'scrooloose/syntastic'
Plug 'davidhalter/jedi-vim', {'for': ['python', 'pyrex'], 'on': 'Pyimport'}
Plug 'nvie/vim-flake8', {'for': ['python', 'pyrex']}
Plug 'hdima/python-syntax', {'for': ['python', 'pyrex']}
Plug 'tshirtman/vim-cython'
Plug 'zchee/vim-flatbuffers'

call plug#end()
