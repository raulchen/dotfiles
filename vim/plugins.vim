""""""""""""""""""""""""""""""
" Load pathogen paths
""""""""""""""""""""""""""""""
call pathogen#infect('~/dotfiles/vim/plugins/{}')
call pathogen#helptags()
let fzf = 0
for p in ["~/.fzf", "/usr/local/opt/fzf"]
    if isdirectory(expand(p))
        execute "set rtp+=".p
        let fzf = 1
    endif
endfor

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
nmap <c-P> <Plug>yankstack_substitute_newer_paste

"""""""""""""""""""
" CtrlP
"""""""""""""""""""
let g:ctrlp_working_path_mode = 0
let g:ctrlp_map = ''
map <leader>p :CtrlP<cr>
map <leader>P :CtrlP<space>
map <leader>m :CtrlPMRUFiles<cr>
map <leader>b :CtrlPBuffer<cr>

"""""""""""""""""""
" Lightline
"""""""""""""""""""

"""""""""""""""""""
" Syntastic
"""""""""""""""""""
" Python
let g:syntastic_python_checkers=['pyflakes']
