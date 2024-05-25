let g:vim_plugins = []

" General
call extend(g:vim_plugins, [
\  "amix/open_file_under_cursor.vim",
\  "michaeljsmith/vim-indent-object",
\  "christoomey/vim-tmux-navigator",
\])

" Editing
call extend(g:vim_plugins, [
\  "tpope/vim-surround",
\  "mg979/vim-visual-multi",
\  "tpope/vim-repeat",
\  "mbbill/undotree",
\  "tpope/vim-sleuth",
\  "ojroques/vim-oscyank",
\  "justinmk/vim-sneak",
\])

" UI
call extend(g:vim_plugins, [
\  "jszakmeister/vim-togglecursor",
\  "powerman/vim-plugin-AnsiEsc",
\])

" Source control
call extend(g:vim_plugins, [
\  "tpope/vim-fugitive",
\  "tpope/vim-rhubarb",
\])

" Following plugins are not enabled for neovim.
if !has("nvim")
    call extend(g:vim_plugins, [
    \  "junegunn/fzf",
    \  "junegunn/fzf.vim",
    \  "connorholyday/vim-snazzy",
    \  "scrooloose/nerdtree",
    \  "itchyny/lightline.vim",
    \  "mgee/lightline-bufferline",
    \  "mhinz/vim-startify",
    \  "google/vim-searchindex",
    \  "tpope/vim-commentary",
    \])
end

if !has("nvim")
    let g:plug_threads = 8
    let g:plug_retries = 4
    set rtp+=~/dotfiles/vim
    call plug#begin(g:vim_data_dir.'/installed_plugins')
    for plugin in g:vim_plugins
	execute "Plug '" . plugin . "'"
    endfor
    call plug#end()

    colorscheme snazzy
endif
