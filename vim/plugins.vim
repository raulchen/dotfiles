let g:vim_plugins = []

" General
call extend(g:vim_plugins, [
\  "scrooloose/nerdtree",
\  "amix/open_file_under_cursor.vim",
\  "michaeljsmith/vim-indent-object",
\  "google/vim-searchindex",
\  "airblade/vim-rooter",
\  "junegunn/fzf",
\  "junegunn/fzf.vim",
\  "christoomey/vim-tmux-navigator",
\])

if has("nvim") || has("terminal")
    call add(g:vim_plugins, "voldikss/vim-floaterm")
endif

" Editing
call extend(g:vim_plugins, [
\  "tpope/vim-surround",
\  "tpope/vim-commentary",
\  "mg979/vim-visual-multi",
\  "tpope/vim-repeat",
\  "mbbill/undotree",
\  "tpope/vim-sleuth",
\  "ojroques/vim-oscyank",
\  "justinmk/vim-sneak",
\])

" UI
call extend(g:vim_plugins, [
\  "mhinz/vim-startify",
\  "connorholyday/vim-snazzy",
\  "itchyny/lightline.vim",
\  "mgee/lightline-bufferline",
\  "jszakmeister/vim-togglecursor",
\  "majutsushi/tagbar",
\])

" Source control
call extend(g:vim_plugins, [
\  "tpope/vim-fugitive",
\  "junegunn/gv.vim",
\  "will133/vim-dirdiff",
\])

if !has("nvim")
    let g:plug_threads = 8
    let g:plug_retries = 4
    set rtp+=~/dotfiles/vim
    call plug#begin('~/dotfiles/vim/installed_plugins')
    for plugin in g:vim_plugins
	execute "Plug '" . plugin . "'"
    endfor
    call plug#end()

    colorscheme snazzy
endif

" if has("nvim")
"     Plug 'neovim/nvim-lspconfig'
"     Plug 'hrsh7th/nvim-cmp'
"     Plug 'hrsh7th/cmp-nvim-lsp'
"     Plug 'saadparwaiz1/cmp_luasnip'
"     Plug 'L3MON4D3/LuaSnip'
"     Plug 'mfussenegger/nvim-dap'
"     Plug 'rcarriga/nvim-dap-ui'
"     Plug 'williamboman/mason.nvim'
"     Plug 'williamboman/mason-lspconfig.nvim'
"     Plug 'github/copilot.vim'
"     Plug 'nvim-lua/plenary.nvim'
"     Plug 'jose-elias-alvarez/null-ls.nvim'
"     Plug 'lukas-reineke/indent-blankline.nvim'
"     Plug 'folke/which-key.nvim'
"     Plug 'lewis6991/gitsigns.nvim'
" endif
