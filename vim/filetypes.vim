"""""""""""""""
" Python
"""""""""""""""
let python_highlight_all = 1
au FileType python,pyrex syn keyword pythonDecorator True None False self cls

au BufNewFile,BufRead *.jinja set syntax=htmljinja
au BufNewFile,BufRead *.mako set ft=mako

au FileType python,pyrex set foldmethod=indent
au FileType python,pyrex set foldlevel=99

au FileType python,pyrex ia ipdb import ipdb; ipdb.set_trace()

"""""""""""""""
" C/C++
"""""""""""""""
autocmd FileType c,cpp setlocal commentstring=//\ %s
