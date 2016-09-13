# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() {
  IFS='
'
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
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {} FZF-EOF"
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
    local pos="$(ag --color $@ | fzf --ansi --reverse --no-sort)"
    if [[ $pos ]]; then
        local file="$(echo -n $pos | awk -F ':' '{print $1}')"
        local lineno="$(echo -n $pos | awk -F ':' '{print $2}')"
        vim +$lineno $file
    fi
}

vless() {
    if test $# -eq 0; then
        vim -u ~/dotfiles/vim/less.vim -
    else
        vim -u ~/dotfiles/vim/less.vim $@
    fi
}
