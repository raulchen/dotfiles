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
    local DIR=$(print_parent_dirs | fzf)
    cd "$DIR"
}

# Git commit browser
flog() {
  git log --oneline --decorate --color=always ${*:-} |
  fzf -- --ansi --no-sort --reverse \
      --delimiter=' ' \
      --preview "git show {1} | bat --color=always -l gitlog --line-range :$LINES --style plain" \
      --preview-window $FZF_PREVIEW_WINDOW \
      --bind 'enter:become(git show {1} --color=always | less -R)'
}

frg() {
    rg --color=always --line-number --no-heading --smart-case --no-context-separator --field-context-separator : ${*:-} |
      fzf --ansi \
          --color "hl:-1:underline,hl+:-1:underline:reverse" \
          --delimiter : \
          --preview 'bat -n --color=always {1} --highlight-line {2}' \
          --preview-window "$FZF_PREVIEW_WINDOW,+{2}-5" \
          --bind 'enter:become(vim {1} +{2})'
}

# Search and kill a process.
fkill() {
    (date; ps -ef) |
      fzf -- --bind='ctrl-r:reload(date; ps -ef)' \
          --header=$'Press CTRL-R to reload\n\n' --header-lines=2 \
          --preview='echo {}' --preview-window=down,3,wrap \
          | awk '{print $2}' | xargs kill -9
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

if type yazi >/dev/null 2>&1 ; then
    #  Wrapper for yazi to cd into the directory output by yazi
    function yz() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        command yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d '' cwd < "$tmp"
        [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
        rm -f -- "$tmp"
    }
fi
