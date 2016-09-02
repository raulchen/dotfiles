set rtp+=~/dotfiles/vim
call plug#begin('~/dotfiles/vim/installed_plugins')

" General
Plug 'scrooloose/nerdtree'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'mileszs/ack.vim'
Plug 'haya14busa/incsearch.vim'
Plug 'amix/open_file_under_cursor.vim'
Plug 'easymotion/vim-easymotion'
Plug 'terryma/vim-expand-region'
Plug 'michaeljsmith/vim-indent-object'
for p in ['~/.fzf', '/usr/local/opt/fzf']
    if isdirectory(expand(p))
        Plug 'junegunn/fzf', {'dir': p}
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
Plug 'townk/vim-autoclose'
Plug 'mbbill/undotree'

" UI
Plug 'mkitt/tabline.vim'
Plug 'itchyny/lightline.vim'
Plug 'dracula/vim'

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/gv.vim'

" Language support
Plug 'sheerun/vim-polyglot'
Plug 'scrooloose/syntastic'
Plug 'davidhalter/jedi-vim', {'for': 'python'}
Plug 'nvie/vim-flake8', {'for': 'python'}

call plug#end()
