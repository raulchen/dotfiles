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

# Git commit browser
flog() {
  git log --oneline --decorate --color=always ${*:-} |
  fzf --ansi --no-sort --reverse \
      --delimiter=' ' \
      --preview "git show {1} | bat --color=always -l gitlog --line-range :$LINES --style plain" \
      --bind 'enter:become(git show {1})'
}

frg() {
    rg --color=always --line-number --no-heading --smart-case ${*:-} |
      fzf --ansi \
          --color "hl:-1:underline,hl+:-1:underline:reverse" \
          --delimiter : \
          --preview 'bat --color=always {1} --highlight-line {2}' \
          --preview-window 'right,50%,<70(down,50%),+{2}+3/3,~3' \
          --bind 'enter:become(vim {1} +{2})'
}

# Search and kill a process.
fkill() {
    (date; ps -ef) |
      fzf --bind='ctrl-r:reload(date; ps -ef)' \
          --header=$'Press CTRL-R to reload\n\n' --header-lines=2 \
          --preview='echo {}' --preview-window=down,3,wrap \
          --layout=reverse --height=80% | awk '{print $2}' | xargs kill -9
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
