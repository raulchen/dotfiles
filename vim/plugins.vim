let g:vim_plugins = []

" General
call extend(g:vim_plugins, [
\  "amix/open_file_under_cursor.vim",
\  "michaeljsmith/vim-indent-object",
\  "google/vim-searchindex",
\  "airblade/vim-rooter",
\  "junegunn/fzf",
\  "junegunn/fzf.vim",
\  "christoomey/vim-tmux-navigator",
\])

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
\  "jszakmeister/vim-togglecursor",
\])

" Source control
call extend(g:vim_plugins, [
\  "tpope/vim-fugitive",
\  "junegunn/gv.vim",
\  "will133/vim-dirdiff",
\])

" Following plugins are not enabled for neovim.
if !has("nvim")
    call extend(g:vim_plugins, [
    \  "scrooloose/nerdtree",
    \  "itchyny/lightline.vim",
    \  "mgee/lightline-bufferline",
    \])
end

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
