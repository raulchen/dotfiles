""""""""""""""""""""""""""""""
" FZF
""""""""""""""""""""""""""""""
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

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

function! RgWithWordUnderCursor()
    " Get the word under the cursor
    let l:word = expand("<cword>")
    " Escape special characters
    let l:escaped_word = escape(l:word, '\/.*$^~[]')
    " Execute Rg with the word under the cursor
    call feedkeys(':Rg '.l:escaped_word, 'n')
endfunction

function! RgWithSelection()
    " Yank the visual selection into the unnamed register
    normal! gvy
    " Get the yanked text from the unnamed register
    let l:text = getreg('"')
    " Escape special characters
    let l:escaped_text = escape(l:text, '\/.*$^~[]')
    " Execute Rg with the selected text
    call feedkeys(':Rg '.l:escaped_text, 'n')
endfunction

" Find files.
nnoremap <leader>ff :execute FilesOrGFiles()<cr>
" Find files under the directory of the current file.
nnoremap <leader>fd :Files <c-r>=expand("%:p:h")<cr>/<cr>
" Find a buffer.
nnoremap <leader>fb :Buffers<cr>
" Find word under cursor.
nnoremap <leader>fs :call RgWithWordUnderCursor()<cr>
" Find selected text.
vnoremap <leader>fs :<c-u>call RgWithSelection()<cr>
" Find tag for the current buffer.
nnoremap <leader>ft :BTags<cr>
nnoremap <leader>fT :Tags<cr>
" Find marks
nnoremap <leader>fm :Marks<cr>
" Find file history.
nnoremap <leader>fh :History<cr>
" Find search history.
nnoremap <leader>f/ :History/<cr>
" Find command history.
nnoremap <leader>f: :History:<cr>
" Find git commits for the current buffer.
nnoremap <leader>fc  :BCommits<cr>
" Find all git commits.
nnoremap <leader>fC :Commits<cr>
" Find key mappings.
nnoremap <leader>fk :Maps<cr>
" Find a line in the current buffer.
nnoremap <leader>fl :BLines<cr>
" Find a line in all buffers.
nnoremap <leader>fL :Lines<cr>

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
if !has("nvim")
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
end

"""""""""""""""""""
" Lightline
"""""""""""""""""""
if !has("nvim")
  let g:lightline = {
  \     'colorscheme': 'snazzy',
  \     'tabline': {'left': [['buffers']], 'right': []},
  \     'component_expand': {'buffers': 'lightline#bufferline#buffers'},
  \     'component_type': {'buffers': 'tabsel'},
  \ }

  let g:lightline#bufferline#show_number = 1
  let g:lightline#bufferline#number_separator = '.'
  let g:lightline#bufferline#filename_modifier = ':t'
end

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
" vim-rooter
"""""""""""""""""""
let g:rooter_silent_chdir = 0
let g:rooter_patterns = [".git", "WORKSPACE"]

"""""""""""""""""""
" vim-oscyank
"""""""""""""""""""
" Copy to system clipboard.
vnoremap <leader>y :OSCYankVisual<CR>
let g:oscyank_term = 'default'

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

"""""""""""""""""""
" vim-fugitive
"""""""""""""""""""
" Git status
nnoremap <leader>gg :Git<cr>
" Open in browser
nnoremap <leader>go :GBrowse<cr>
" Git blame
nnoremap <leader>gB :G blame<cr>
" Git log of the current buffer
nnoremap <leader>gl :0Gclog<cr>
" Git log
nnoremap <leader>gL :Gclog<cr>
" Git log of the visual selection
vnoremap <leader>gl :Gclog<cr>

"""""""""""""""""""
" vim-plugin-AnsiEsc
"""""""""""""""""""
" Disable default mappings
let g:no_cecutil_maps = 0

