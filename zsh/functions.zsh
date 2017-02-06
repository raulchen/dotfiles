# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() {
    IFS=''
    local declare files=($(fzf-tmux --query="$1" --select-1 --exit-0))
    [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
    unset IFS
}

# fd - cd to selected directory
fd() {
    local dir
    dir=$(find ${1:-*} -path '*/\.*' -prune \
        -o -type d -print 2> /dev/null | fzf-tmux +m) &&
        cd "$dir"
}

# fda - including hidden directories
fda() {
    local dir
    dir=$(find ${1:-.} -type d 2> /dev/null | fzf-tmux +m) && cd "$dir"
}


# fu - cd upward
fu() {
    print_parent_dirs() {
        path=$(pwd)
        path=${path%/*}
        while [[ "$path" != "" ]]; do
            echo $path
            path=${path%/*}
        done
        echo "/"
    }
    local DIR=$(print_parent_dirs | fzf-tmux)
    cd "$DIR"
}

# flog - git commit browser
flog() {
  glol |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --header "Press CTRL-S to toggle sort" \
      --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 |
                 xargs -I % sh -c 'git show --color=always % | head -$LINES'" \
      --bind "enter:execute:echo {} | grep -o '[a-f0-9]\{7\}' | head -1 |
              xargs -I % sh -c 'vim fugitive://\$(git rev-parse --show-toplevel)/.git//% < /dev/tty'"
}

# v - open files in ~/.viminfo
unalias v 2>/dev/null
v() {
    local files
    files=$(grep '^>' ~/.viminfo | cut -c3- |
    while read line; do
        [ -f "${line/\~/$HOME}" ] && echo "$line"
    done | fzf-tmux -d -m -q "$*" -1) && vim ${files//\~/$HOME}
}
alias fv=v

fz() {
    local dir
    dir="$(fasd -Rdl "$1" | fzf-tmux -1 -0 --no-sort +m)" && cd "${dir}" || return 1
}

fag() {
    local _size=`echo "($LINES*0.35-2)/1" | bc`
    local _cmd="pcat %s -c %d -l $_size -n --color=always"
    ag --color $@ | fzf --ansi --reverse --no-sort \
        --preview-window down:35% \
        --preview "echo {} |
                   awk -F':' '{printf \"$_cmd\",\$1,\$2}' |
                   awk '{system(\$0)}'" \
        --bind "ctrl-m:execute: echo {} |
                awk -F':' '{print \"+\"\$2\" \"\$1}' |
                xargs -I % sh -c '</dev/tty vim %'"
}

vless() {
    if test $# -eq 0; then
        vim -u ~/dotfiles/vim/less.vim -
    else
        vim -u ~/dotfiles/vim/less.vim $@
    fi
}

function _notify {
  echo -ne 'trigger''-notify('$@')' && sleep 0.01 && echo -e '\r\033[K\033[1A'
}

function notify {
    sleep 0.1;
    if [ $? = 0 ]; then
        _notify "Task finished"
    else
        _notify "Task failed"
    fi
}
