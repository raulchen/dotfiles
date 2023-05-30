let g:plug_threads = 8
let g:plug_retries = 4
set rtp+=~/dotfiles/vim
call plug#begin('~/dotfiles/vim/installed_plugins')

" General
Plug 'scrooloose/nerdtree'
Plug 'amix/open_file_under_cursor.vim'
Plug 'michaeljsmith/vim-indent-object'
Plug 'google/vim-searchindex'
Plug 'airblade/vim-rooter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
if has("nvim") || has("terminal")
    Plug 'voldikss/vim-floaterm'
endif
Plug 'christoomey/vim-tmux-navigator'

" Edit
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-repeat'
Plug 'mbbill/undotree', {'on': 'UndotreeToggle'}
Plug 'tpope/vim-sleuth'
Plug 'junegunn/vim-peekaboo'
Plug 'ojroques/vim-oscyank'
Plug 'justinmk/vim-sneak'

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
Plug 'will133/vim-dirdiff'

" Language support
Plug 'sheerun/vim-polyglot'
Plug 'vim-scripts/a.vim'

if has("nvim")
    Plug 'neovim/nvim-lspconfig'
    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'saadparwaiz1/cmp_luasnip'
    Plug 'L3MON4D3/LuaSnip'
    Plug 'mfussenegger/nvim-dap'
    Plug 'rcarriga/nvim-dap-ui'
    Plug 'williamboman/mason.nvim'
    Plug 'williamboman/mason-lspconfig.nvim'
    Plug 'github/copilot.vim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'jose-elias-alvarez/null-ls.nvim'
endif

call plug#end()
