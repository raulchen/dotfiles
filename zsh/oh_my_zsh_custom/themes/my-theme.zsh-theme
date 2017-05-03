PROMPT='$(source_control_prompt_info)%{$fg[yellow]%}%(?,,%{${fg[red]}%})$ %{$reset_color%}'
RPROMPT='%{$fg[green]%}%~%{$fg[black]%}|%{$fg[yellow]%}%*%{$reset_color%}'

source_control_prompt_info() {
    local d git hg fmt
    d=$PWD
    while : ; do
        if test -d "$d/.git" ; then
            git=$d
            break
        elif test -d "$d/.hg" ; then
            hg=$d
            break
        fi
        test "$d" = / && break
        d=$(cd -P "$d/.." && echo "$PWD")
    done
    local branch dirty
    if [[ -n "$git" ]]; then
        branch=$(git_current_branch)
        dirty=$(command git status --porcelain 2> /dev/null | head -n1)
    elif [[ -n "$hg" ]]; then
        branch="master"
        local current="$hg/.hg/bookmarks.current"
        if [[ -f "$current" ]]; then
            branch=$(cat "$current")
        fi
        dirty=$(command hg status 2> /dev/null | head -n1)
    fi
    if [[ -n "$branch" ]]; then
        if [[ -n "$dirty" ]]; then
            echo -n "%{$fg[red]%}$branch*%{$fg[black]%}|"
        else
            echo -n "%{$fg[blue]%}$branch%{$fg[black]%}|"
        fi
    fi
}
