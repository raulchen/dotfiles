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
# Keybinds send signals immediately and refresh the process list.
# ctrl-t: SIGTERM  ctrl-k: SIGKILL  ctrl-s: SIGSTOP
# enter:  full process details (ps + lsof) in a pager
# ctrl-r: refresh process list
fkill() {
    (date; ps -ef) | fzf \
          --bind='ctrl-r:reload(date; ps -ef)' \
          --bind='ctrl-t:execute-silent(echo {} | awk "{print \$2}" | xargs kill -15)+reload(date; ps -ef)' \
          --bind='ctrl-k:execute-silent(echo {} | awk "{print \$2}" | xargs kill -9)+reload(date; ps -ef)' \
          --bind='ctrl-s:execute-silent(echo {} | awk "{print \$2}" | xargs kill -STOP)+reload(date; ps -ef)' \
          --bind='enter:execute(pid=$(echo {} | awk "{print \$2}"); { echo "=== Process $pid ==="; ps -p $pid -o pid,ppid,user,%cpu,%mem,stat,start,command 2>/dev/null; echo; echo "=== Open files ==="; lsof -p $pid 2>/dev/null; } | less)' \
          --header=$'CTRL-T: SIGTERM | CTRL-K: SIGKILL | CTRL-S: SIGSTOP | ENTER: details | CTRL-R: reload\n\n' \
          --header-lines=2 \
          --preview='pid=$(echo {} | awk "{print \$2}"); ps -p $pid -o pid=,ppid=,user=,%cpu=,%mem=,command= 2>/dev/null; echo; echo "--- Open files ---"; lsof -p $pid 2>/dev/null | head -10' \
          --preview-window=down,15,wrap \
          --prompt='Kill> '
}

vless() {
    if test $# -eq 0; then
        vim -u ~/dotfiles/vim/less.vim -
    else
        vim -u ~/dotfiles/vim/less.vim $@
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
