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
  glol --color=always |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --header "Press CTRL-S to toggle sort" \
      --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 |
                 xargs -I % sh -c 'git show --color=always % | head -$LINES'" \
      --bind "enter:execute:echo {} | grep -o '[a-f0-9]\{7\}' | head -1 |
              xargs -I % sh -c 'vim fugitive://\$(git rev-parse --show-toplevel)/.git//% < /dev/tty'"
}

fz() {
    local dir
    dir="$(fasd -Rdl "$1" | fzf-tmux -1 -0 --no-sort +m)" && cd "${dir}" || return 1
}

frg() {
    rg --color=always --line-number --no-heading --smart-case "${*:-}" |
      fzf --ansi \
          --color "hl:-1:underline,hl+:-1:underline:reverse" \
          --delimiter : \
          --preview 'bat --color=always {1} --highlight-line {2}' \
          --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
          --bind 'enter:become(vim {1} +{2})'
}

__fzf_select_from_tmux() {
    local cmd="command tmux capture-pane -CJp | command perl -pe 's/\s+/\n/g' | sort | uniq"
    setopt localoptions pipefail 2> /dev/null
    eval "$cmd | $(__fzfcmd) -m" | while read item; do
        echo -n "${(q)item} "
    done
    local ret=$?
    echo
    return $ret
}

fzf-select-from-tmux-widget() {
    LBUFFER="${LBUFFER}$(__fzf_select_from_tmux)"
    local ret=$?
    zle redisplay
    typeset -f zle-line-init >/dev/null && zle zle-line-init
    return $ret
}

zle     -N   fzf-select-from-tmux-widget
bindkey '^Y' fzf-select-from-tmux-widget

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
