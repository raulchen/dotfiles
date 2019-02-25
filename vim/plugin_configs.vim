""""""""""""""""""""""""""""""
" FZF
""""""""""""""""""""""""""""""
let g:fzf_history_dir = '~/dotfiles/vim/temp_dirs/fzf-history'
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1
" Augmenting Ag command using fzf#vim#with_preview function
" Ag searches literals by default
command! -bang -nargs=* Ag
  \ call fzf#vim#ag(<q-args>, '--literal',
  \                 <bang>0 ? fzf#vim#with_preview('up:60%')
  \                         : fzf#vim#with_preview('right:60%:hidden'),
  \                 <bang>0)
" Agp searches regex patterns
command! -bang -nargs=* Agp
  \ call fzf#vim#ag(<q-args>,
  \                 <bang>0 ? fzf#vim#with_preview('up:60%')
  \                         : fzf#vim#with_preview('right:60%:hidden'),
  \                 <bang>0)

nmap <c-g><c-f> :Files<cr>
nmap <c-g><c-p> :Files <c-r>=expand("%:p:h")<cr>/
"J for jump
nmap <c-g><c-j> :Buffers<cr>
nmap <c-g><c-a> :Ag<space>
vmap <expr> <c-g><c-a> VisualAg()
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
imap <c-g><c-f> <plug>(fzf-complete-file-ag)
imap <c-g><c-l> <plug>(fzf-complete-line)

function! VisualAg() range
    let cmd = '":\<c-u>Ag ".GetSelection(1, "")'
    return ":\<c-u>call feedkeys(" . cmd . ", 'n')\<cr>"
endfunction

""""""""""""""""""""""""
" Color scheme
""""""""""""""""""""""""
" color dracula
" hi Normal ctermbg=None
" hi CursorLine ctermfg=NONE ctermbg=NONE cterm=underline
" hi Comment cterm=italic ctermfg=61
colorscheme snazzy

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
" YankStack
"""""""""""""""""""
nmap <c-p> <Plug>yankstack_substitute_older_paste
nmap <leader>p <Plug>yankstack_substitute_newer_paste
let g:yankstack_yank_keys = ['y', 'd']

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

let g:lightline = {
\     'colorscheme': 'snazzy',
\     'active': {
\       'left': [['mode', 'paste'], ['gitbranch', 'readonly', 'relativepath', 'modified']],
\       'right': [['linter'], ['lineinfo'], ['filetype']]
\     },
\     'component': {
\         'lineinfo': '%l:%v %p%%'
\     },
\     'component_function': {
\         'gitbranch': 'fugitive#head',
\         'linter': 'LinterStatus'
\     },
\ }

let g:lightline.tabline          = {'left': [['buffers']], 'right': []}
let g:lightline.component_expand = {'buffers': 'lightline#bufferline#buffers'}
let g:lightline.component_type   = {'buffers': 'tabsel'}

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
" Polyglot
"""""""""""""""""""
let g:polyglot_disabled = ['python']

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
