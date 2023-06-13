""""""""""""""""""""""""""""""
" FZF
""""""""""""""""""""""""""""""
let g:fzf_history_dir = g:vim_temp_dir_root."fzf-history"
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

let $FZF_DEFAULT_OPTS = '--layout=reverse --bind "ctrl-/:toggle-preview,ctrl-d:page-down,ctrl-u:page-up,ctrl-p:up,ctrl-n:down"'

if has("patch-8.2.191") || has("nvim")
  let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.9} }
else
  let g:fzf_layout = { 'window': 'enew' }
endif
let g:fzf_preview_window = ['right,50%,<70(down,50%)', 'ctrl-/']

" Customize fzf colors to match your color scheme
" - fzf#wrap translates this to a set of `--color` options
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --hidden --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number -- '.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)

function FilesOrGFiles()
  if system('git rev-parse --is-inside-work-tree 2>/dev/null') =~ 'true'
    execute 'GFiles'
  else
    execute 'Files'
  endif
endfunction

" Find files.
nnoremap <leader>ff :execute FilesOrGFiles()<cr>
" Find files under the directory of the current file.
nnoremap <leader>fd :Files <c-r>=expand("%:p:h")<cr>/<cr>
" Find a buffer.
nnoremap <leader>fb :Buffers<cr>
" Find with Rg
nnoremap <leader>fr :Rg<space>
" Find tag for the current buffer.
nnoremap <leader>ft :BTags<cr>
nnoremap <leader>fT :Tags<cr>
" Find marks
nnoremap <leader>fm :Marks<cr>
" Find file history.
nnoremap <leader>fh :History<cr>
" FInd search history.
nnoremap <leader>f/ :History/<cr>
" Find command history.
nnoremap <leader>f: :History:<cr>
" Find git commits for the current buffer.
nnoremap <leader>fc  :BCommits<cr>
" Find all git commits.
nnoremap <leader>fC :Commits<cr>
" Find key mappings.
nnoremap <leader>fk :Maps<cr>

" Insert mode completion
inoremap <c-g><c-w> <plug>(fzf-complete-word)
inoremap <c-g><c-p> <plug>(fzf-complete-path)
inoremap <expr> <c-g><c-f> fzf#vim#complete#path('rg --files')
inoremap <c-g><c-l> <plug>(fzf-complete-line)

""""""""""""""""""""""""
" Color scheme
""""""""""""""""""""""""
" colorscheme snazzy
hi CursorLine cterm=underline

""""""""""""""""""""""""
" Nerd Tree
""""""""""""""""""""""""
let NERDTreeShowHidden=0

function! NerdTreeToggleFind()
    if exists("g:NERDTree") && g:NERDTree.IsOpen()
        NERDTreeClose
    elseif filereadable(expand('%'))
        NERDTreeFind
    else
        NERDTree
    endif
endfunction

nnoremap <leader>n :call NerdTreeToggleFind()<CR>

"""""""""""""""""""
" Lightline
"""""""""""""""""""
let g:lightline = {
\     'colorscheme': 'snazzy',
\     'tabline': {'left': [['buffers']], 'right': []},
\     'component_expand': {'buffers': 'lightline#bufferline#buffers'},
\     'component_type': {'buffers': 'tabsel'},
\ }

let g:lightline#bufferline#show_number = 1
let g:lightline#bufferline#number_separator = '.'
let g:lightline#bufferline#filename_modifier = ':t'

"""""""""""""""""""
" Undo tree
"""""""""""""""""""
nnoremap <leader>uu :UndotreeToggle<cr>

"""""""""""""""""""
" togglecursor
"""""""""""""""""""
let g:togglecursor_default="blinking_block"
let g:togglecursor_insert="blinking_line"
let g:togglecursor_leave="blinking_block"
let g:togglecursor_replace="blinking_block"

"""""""""""""""""""
" Tagbar
"""""""""""""""""""
nnoremap <leader>ut :TagbarToggle<CR>
let g:tagbar_sort = 0

"""""""""""""""""""
" vim-rooter
"""""""""""""""""""
let g:rooter_silent_chdir = 0
let g:rooter_patterns = [".git", "WORKSPACE", "Makefile"]

"""""""""""""""""""
" vim-oscyank
"""""""""""""""""""
" Copy to system clipboard.
vnoremap <leader>y :OSCYankVisual<CR>
let g:oscyank_term = 'default'

"""""""""""""""""""
" vim-floaterm
"""""""""""""""""""
let g:floaterm_keymap_toggle = '<C-T>'
let g:floaterm_opener = 'edit'
let g:floaterm_width = 0.9
let g:floaterm_height = 0.9
command! Ranger FloatermNew ranger

"""""""""""""""""""
" vim-tmux-navigator
"""""""""""""""""""
" Disable tmux navigator when zooming the Vim pane
" let g:tmux_navigator_disable_when_zoomed = 1

let g:tmux_navigator_no_mappings = 1
noremap <silent> <C-M-H> :<C-U>TmuxNavigateLeft<cr>
noremap <silent> <C-M-J> :<C-U>TmuxNavigateDown<cr>
noremap <silent> <C-M-K> :<C-U>TmuxNavigateUp<cr>
noremap <silent> <C-M-L> :<C-U>TmuxNavigateRight<cr>
