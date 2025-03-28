""""""""""""""""""""""""""""""
" FZF
""""""""""""""""""""""""""""""
if !has("nvim")
  " [Buffers] Jump to the existing window if possible
  let g:fzf_buffers_jump = 1

  if has("patch-8.2.191") || has("nvim")
    let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.9} }
  else
    let g:fzf_layout = { 'window': 'enew' }
  endif
  let g:fzf_preview_window = ['right,50%,<70(down,50%)', 'ctrl-/']

  function! s:build_quickfix_list(lines)
    call setqflist(map(copy(a:lines), '{ "filename": v:val, "lnum": 1 }'))
    copen
    cc
  endfunction

  let g:fzf_action = {
    \ 'ctrl-q': function('s:build_quickfix_list'),
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit' }

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
end

""""""""""""""""""""""""
" Color scheme
""""""""""""""""""""""""
" colorscheme snazzy
if !has("nvim")
  hi CursorLine cterm=underline
end

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

  nnoremap <silent> <leader>n :call NerdTreeToggleFind()<CR>
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
if !has("nvim")
  nnoremap <silent> <leader>uu :UndotreeToggle<cr>
end

"""""""""""""""""""
" togglecursor
"""""""""""""""""""
let g:togglecursor_default="blinking_block"
let g:togglecursor_insert="blinking_line"
let g:togglecursor_leave="blinking_block"
let g:togglecursor_replace="blinking_block"

"""""""""""""""""""
" vim-oscyank
"""""""""""""""""""
let g:oscyank_silent = 1
" Automatically copy text that was yanked to register +.
autocmd TextYankPost *
    \ if v:event.operator is 'y' && v:event.regname is '+' |
    \ execute 'OSCYankRegister +' |
    \ endif

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
tnoremap <silent> <C-M-H> <c-\><c-n>:<C-U>TmuxNavigateLeft<cr>
tnoremap <silent> <C-M-J> <c-\><c-n>:<C-U>TmuxNavigateDown<cr>
tnoremap <silent> <C-M-K> <c-\><c-n>:<C-U>TmuxNavigateUp<cr>
tnoremap <silent> <C-M-L> <c-\><c-n>:<C-U>TmuxNavigateRight<cr>

"""""""""""""""""""
" vim-fugitive
"""""""""""""""""""
" Git status
nnoremap <silent> <leader>gg :Git<cr>
" Git blame
nnoremap <silent> <leader>gB :G blame<cr>

"""""""""""""""""""
" vim-plugin-AnsiEsc
"""""""""""""""""""
if !has("nvim")
  " Disable default mappings
  let g:no_cecutil_maps = 0
endif

"""""""""""""""""""
" vim-startify
"""""""""""""""""""
if !has("nvim")
  let g:startify_change_to_vcs_root = 0
  let g:startify_change_to_dir = 0
  if has("nvim")
    let g:startify_session_dir = stdpath('data').'/sessions'
  else
    let g:startify_session_dir = g:vim_data_dir.'/sessions'
  endif
  let g:startify_session_sort = 1

  let g:startify_lists = [
        \ { 'type': 'dir',       'header': ['   MRU '. getcwd()] },
        \ { 'type': 'files',     'header': ['   MRU']            },
        \ { 'type': 'sessions',  'header': ['   Sessions']       },
        \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
        \ { 'type': 'commands',  'header': ['   Commands']       },
        \ ]
endif
