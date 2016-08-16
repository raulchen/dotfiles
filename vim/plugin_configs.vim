""""""""""""""""""""""""""""""
" FZF
""""""""""""""""""""""""""""""
let fzf = 0
for p in ["~/.fzf", "/usr/local/opt/fzf"]
    if isdirectory(expand(p))
        execute "set rtp+=".p
        let fzf = 1
    endif
endfor
if !fzf
    echo "FZF not found"
else
    let g:fzf_history_dir = '~/dotfiles/vim/temp_dirs/fzf-history'
    nmap <c-g>f :Files<cr>
    nmap <c-g>p :Files <c-r>=expand("%:p:h")<cr>/
    nmap <c-g>b :Buffers<cr>
    nmap <c-g>a :Ag<space>
    nmap <c-g>l :BLines<cr>
    nmap <c-g>L :Lines<cr>
    nmap <c-g>t :BTags<cr>
    nmap <c-g>T :Tags<cr>
    nmap <c-g>m :Marks<cr>
    nmap <c-g>h :History<cr>
    nmap <c-g>/ :History/<cr>
    nmap <c-g>; :History:<cr>
    nmap <c-g>g :BCommits<cr>
    nmap <c-g>G :Commits<cr>
    nmap <c-g>c :Commands<cr>
    nmap <c-g>m :Maps<cr>
    xmap <c-g>m <plug>(fzf-maps-x)
    omap <c-g>m <plug>(fzf-maps-o)
    imap <c-g>m <plug>(fzf-maps-i)
    imap <c-g>w <plug>(fzf-complete-word)
    imap <c-g>p <plug>(fzf-complete-path)
    imap <c-g>f <plug>(fzf-complete-file-ag)
    imap <c-g>l <plug>(fzf-complete-line)
endif

""""""""""""""""""""""""
" Dracula theme
""""""""""""""""""""""""
color dracula
hi Search ctermfg=17 ctermbg=228 cterm=NONE guifg=#282a36 guibg=#f1fa8c gui=NONE

""""""""""""""""""""""""
" Nerd Tree
""""""""""""""""""""""""
let NERDTreeShowHidden=0
map <leader>n :NERDTreeTabsToggle<cr>

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
" Lightline
"""""""""""""""""""
let g:lightline = {
\     'active': {
\       'left': [ [ 'mode', 'paste' ],
\                 [ 'fugitive', 'readonly', 'relativepath', 'modified' ] ]
\     },
\     'component': {
\         'fugitive': '%{exists("*fugitive#head")?fugitive#head():""}'
\     },
\     'component_visible_condition': {
\         'fugitive': '(exists("*fugitive#head") && ""!=fugitive#head())'
\     },
\ }

"""""""""""""""""""
" Syntastic
"""""""""""""""""""
" Python
let g:syntastic_python_checkers=['pyflakes']

"""""""""""""""""""
" Undo tree
"""""""""""""""""""
nnoremap <leader>u :UndotreeToggle<cr>

"""""""""""""""""""
" Ack.vim
"""""""""""""""""""
if executable('ag')
    let g:ackprg = 'ag --vimgrep'
endif

"""""""""""""""""""
" Jedi-vim
"""""""""""""""""""
let g:jedi#use_tabs_not_buffers = 1
let g:jedi#popup_on_dot = 0
let g:jedi#popup_select_first = 1
let g:jedi#smart_auto_mappings = 1
let g:jedi#goto_command = "<c-e>g"
let g:jedi#goto_assignments_command = "<c-e>a"
let g:jedi#goto_definitions_command = "<c-e>d"
let g:jedi#documentation_command = "K"
let g:jedi#usages_command = "<c-e>u"
let g:jedi#completions_command = "<C-Space>"
let g:jedi#rename_command = "<c-e>r"
autocmd FileType python setlocal completeopt-=preview
autocmd FileType python setlocal complete-=i
