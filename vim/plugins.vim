set rtp+=~/dotfiles/vim
call plug#begin('~/dotfiles/vim/installed_plugins')

" General
Plug 'scrooloose/nerdtree'
Plug 'amix/open_file_under_cursor.vim'
Plug 'easymotion/vim-easymotion'
Plug 'terryma/vim-expand-region'
Plug 'michaeljsmith/vim-indent-object'
Plug 'dyng/ctrlsf.vim'
Plug 'google/vim-searchindex'
Plug 'airblade/vim-rooter'
for p in ['~/.fzf', '/usr/local/opt/fzf', '/home/linuxbrew/.linuxbrew/opt/fzf']
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
" Plug 'maxbrunsfeld/vim-yankstack'
Plug 'jiangmiao/auto-pairs'
Plug 'mbbill/undotree', {'on': 'UndotreeToggle'}
Plug 'tpope/vim-sleuth'
Plug 'Chiel92/vim-autoformat'

" UI
Plug 'mhinz/vim-startify'
Plug 'itchyny/lightline.vim'
Plug 'mgee/lightline-bufferline'
" Plug 'dracula/vim', {'as': 'dracula-vim'}
Plug 'connorholyday/vim-snazzy'
Plug 'jszakmeister/vim-togglecursor'
Plug 'majutsushi/tagbar'

" Source control
Plug 'mhinz/vim-signify'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim', {'on': 'GV'}
Plug 'jlfwong/vim-mercenary'
Plug 'will133/vim-dirdiff'

" Language support
Plug 'sheerun/vim-polyglot'
Plug 'w0rp/ale'
Plug 'davidhalter/jedi-vim', {'for': ['python', 'pyrex'], 'on': 'Pyimport'}
Plug 'lambdalisue/vim-pyenv', {'for': ['python', 'pyrex'], 'on': 'Pyimport'}
Plug 'hdima/python-syntax', {'for': ['python', 'pyrex']}
Plug 'tshirtman/vim-cython'
Plug 'zchee/vim-flatbuffers'
Plug 'zxqfl/tabnine-vim'

call plug#end()
