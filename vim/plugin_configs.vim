""""""""""""""""""""""""""""""
" FZF
""""""""""""""""""""""""""""""
let g:fzf_history_dir = '~/dotfiles/vim/temp_dirs/fzf-history'
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

let $FZF_DEFAULT_OPTS = '--layout=reverse --inline-info'

" let g:fzf_layout = { 'down': '80%' }
let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.8, 'border': 'sharp'} }

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

nmap <c-g><c-f> :Files<cr>
nmap <c-g><c-p> :Files <c-r>=expand("%:p:h")<cr>/
"J for jump
nmap <c-g><c-j> :Buffers<cr>
nmap <c-g><c-r> :Rg<space>
nmap <c-g><c-t> :BTags<cr>
nmap <c-g><c-g><c-t> :Tags<cr>
nmap <c-g><c-m> :Marks<cr>
nmap <c-g><c-h> :History<cr>
nmap <c-g>/ :History/<cr>
nmap <c-g>; :History:<cr>
" L for log
nmap <c-g><c-g><c-l> :BCommits<cr>
nmap <c-g><c-l> :Commits<cr>
nmap <c-g>m :Maps<cr>

imap <c-g><c-w> <plug>(fzf-complete-word)
imap <c-g><c-p> <plug>(fzf-complete-path)
imap <expr> <c-g><c-f> fzf#vim#complete#path('rg --files')
imap <c-g><c-l> <plug>(fzf-complete-line)

""""""""""""""""""""""""
" Color scheme
""""""""""""""""""""""""
" color dracula
" hi Normal ctermbg=None
colorscheme snazzy
hi Comment cterm=italic
hi CursorLine cterm=underline

""""""""""""""""""""""""
" Nerd Tree
""""""""""""""""""""""""
let NERDTreeShowHidden=0
map <leader>n :NERDTreeToggle<cr>
map <leader><leader>n :NERDTreeFind<cr>

"""""""""""""""""""
" EasyMotion
"""""""""""""""""""
" <Leader>f{char} to move to {char}
map  <Leader>f <Plug>(easymotion-bd-f)
nmap <Leader>f <Plug>(easymotion-overwin-f)

" Move to line
map <Leader>L <Plug>(easymotion-bd-jk)
nmap <Leader>L <Plug>(easymotion-overwin-line)

" Move to word
map  <Leader>W <Plug>(easymotion-bd-w)
nmap <Leader>W <Plug>(easymotion-overwin-w)

let g:EasyMotion_smartcase = 1

"""""""""""""""""""
" Ale
"""""""""""""""""""
let g:ale_fixers = {
\   'cpp': ['clang-format'],
\   'python': ['yapf'],
\}
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_enter = 0

"""""""""""""""""""
" Lightline
"""""""""""""""""""
function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))

    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors

    return l:counts.total == 0 ? 'OK' : printf(
    \   'W:%d E:%d',
    \   all_non_errors,
    \   all_errors
    \)
endfunction

function TabIndex()
  return printf('%d/%d', tabpagenr(), tabpagenr('$'))
endfunction

let g:lightline = {
\     'colorscheme': 'snazzy',
\     'active': {
\       'left': [['mode', 'paste'], ['gitbranch', 'readonly', 'relativepath', 'modified']],
\       'right': [['linter'], ['lineinfo'], ['filetype']]
\     },
\     'tabline': {'left': [['tab_index'], ['buffers']], 'right': []},
\     'component': {
\         'lineinfo': '%l:%v %p%%'
\     },
\     'component_function': {
\         'gitbranch': 'fugitive#head',
\         'tab_index': 'TabIndex',
\         'linter': 'LinterStatus'
\     },
\     'component_expand': {'buffers': 'lightline#bufferline#buffers'},
\     'component_type': {'buffers': 'tabsel'},
\ }

let g:lightline#bufferline#show_number = 1
let g:lightline#bufferline#number_separator = '.'
let g:lightline#bufferline#filename_modifier = ':t'

"""""""""""""""""""
" Undo tree
"""""""""""""""""""
nnoremap <leader>u :UndotreeToggle<cr>

"""""""""""""""""""
" Jedi-vim
"""""""""""""""""""
let g:jedi#popup_on_dot = 0
let g:jedi#popup_select_first = 1
let g:jedi#smart_auto_mappings = 1
let g:jedi#goto_command = "<c-e><c-g>"
let g:jedi#goto_assignments_command = "<c-e><c-a>"
let g:jedi#goto_definitions_command = "<c-e><c-d>"
let g:jedi#documentation_command = "K"
let g:jedi#usages_command = "<c-e><c-u>"
let g:jedi#completions_command = "<c-e>"
let g:jedi#rename_command = "<c-e><c-r>"
let g:jedi#show_call_signatures = "0"
autocmd FileType python,pyrex setlocal completeopt-=preview
autocmd FileType python,pyrex setlocal complete-=i

"""""""""""""""""""
" vim-pyenv
"""""""""""""""""""
function! s:jedi_auto_force_py_version() abort
  let g:jedi#force_py_version = pyenv#python#get_internal_major_version()
endfunction
augroup vim-pyenv-custom-augroup
  autocmd! *
  autocmd User vim-pyenv-activate-post   call s:jedi_auto_force_py_version()
  autocmd User vim-pyenv-deactivate-post call s:jedi_auto_force_py_version()
augroup END

"""""""""""""""""""
" CtrlSF
"""""""""""""""""""
nmap <leader>a <Plug>CtrlSFPrompt
vmap <leader>a <Plug>CtrlSFVwordPath
let g:ctrlsf_auto_close = 0
let g:ctrlsf_mapping = {
    \ "popen": "<cr>",
    \ }

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
nmap <F8> :TagbarToggle<CR>
let g:tagbar_sort = 0

"""""""""""""""""""
" AutoFormat
"""""""""""""""""""
let g:autoformat_autoindent = 0
let g:autoformat_retab = 0
let g:autoformat_remove_trailing_spaces = 0
nnoremap <leader>f :Autoformat<CR>
vnoremap <leader>f :Autoformat<CR>

"""""""""""""""""""
" auto-pairs
"""""""""""""""""""
let g:AutoPairsMultilineClose = 0

"""""""""""""""""""
" vim-merge
"""""""""""""""""""
let g:vimmerge#buffer_numbers = {
\ 'BASE': 1,
\ 'LOCAL': 2,
\ 'REMOTE': 3,
\ 'MERGED': 4
\}

function VimMergeSwitchLayout(left, right)
  silent windo diffoff
  silent wincmd o
  silent execute 'buffer' . g:vimmerge#buffer_numbers[a:left]
  silent vsp
  silent execute 'buffer' . g:vimmerge#buffer_numbers[a:right]
  silent windo diffthis
  silent windo diffupdate
  silent wincmd w
endfunction

function VimMergeStart()
  call VimMergeSwitchLayout('MERGED', 'LOCAL')
  " Set shortcuts for switching layouts.
  nnoremap <leader>1 :call VimMergeSwitchLayout('BASE', 'LOCAL')<cr>
  nnoremap <leader>2 :call VimMergeSwitchLayout('BASE', 'REMOTE')<cr>
  nnoremap <leader>3 :call VimMergeSwitchLayout('MERGED', 'LOCAL')<cr>
  nnoremap <leader>4 :call VimMergeSwitchLayout('MERGED', 'REMOTE')<cr>
  nnoremap <leader>5 :call VimMergeSwitchLayout('MERGED', 'BASE')<cr>
  " Search conflict markers.
  let pattern = "[<=>]\\{7\\}"
  execute 'normal! /'. pattern ."\<cr>"
  let @/ = pattern
endfunction


"""""""""""""""""""
" vim-rooter
"""""""""""""""""""
let g:rooter_silent_chdir = 1
let g:rooter_patterns = [".git", "WORKSPACE"]
