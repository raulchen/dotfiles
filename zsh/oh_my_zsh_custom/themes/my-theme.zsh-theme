# Print all colors:
# for code in {000..255}; do print -P -- "$code: %F{$code}Color%f"; done

local PROMPT_SEPARATOR="$FG[240]|"

PROMPT='%{$fg[yellow]%}%(?,,%{${fg[red]}%})\$$PROMPT_SEPARATOR%{$reset_color%}'
RPROMPT_PREFIX='$PROMPT_SEPARATOR'
RPROMPT_SUFFIX='%{$fg[yellow]%}%~$PROMPT_SEPARATOR%{$fg[green]%}%*%{$reset_color%}'

_prompt_precmd() {
    local d root
    d=$PWD
    while : ; do
        if test -d "$d/.git" ; then
            root="$d/.git"
            break
        elif test -d "$d/.hg" ; then
            root="$d/.hg"
            break
        fi
        test "$d" = / && break
        d=$(cd -P "$d/.." && echo "$PWD")
    done

    local source_control_info
    if [[ -n "$root" ]]; then
        async_flush_jobs "my_prompt"
	    async_job "my_prompt" _get_source_control_prompt_info "$root"
        source_control_info="%{$fg[blue]%}...$PROMPT_SEPARATOR"
    fi

   RPROMPT="$RPROMPT_PREFIX$source_control_info$RPROMPT_SUFFIX"
}

_get_hg_branch() {
    # Return current bookmark, or remote bookmark, or commit hash
    local branch
    local current="$1/bookmarks.current"
    if [[ -f "$current" ]]; then
        branch=$(cat "$current")
    else
        local commit_hash=$(hg log -r . -l 1 -T "{node}")
        local remote=$(awk "/$commit_hash bookmarks/{print \$3}" $1/remotenames)
        if [[ -n "$remote" ]]; then
            branch=$(echo "$remote" | cut -c 7-)
            branch="r$branch"
        else
            branch=$(echo "$commit_hash" | cut -c 1-7)
        fi
    fi
    echo "$branch"
}

_get_source_control_prompt_info() {
    local branch dirty
    builtin cd -q "$1/.."
    if [[ "$1" == *.git ]]; then
        branch=$(git_current_branch)
        dirty=$(command git status --porcelain 2> /dev/null | head -n1)
    elif [[ "$1" == *.hg ]]; then
        branch=$(_get_hg_branch $1)
        dirty=$(command hg status 2> /dev/null | head -n1)
    fi

    if [[ -n "$dirty" ]]; then
        echo -n "%{$fg[red]%}$branch*$PROMPT_SEPARATOR"
    else
        echo -n "%{$fg[blue]%}$branch$PROMPT_SEPARATOR"
    fi
}

_prompt_callback() {
    if [[ -n "$3" ]]; then
        RPROMPT="$RPROMPT_PREFIX$3$RPROMPT_SUFFIX"
        zle && zle reset-prompt
    fi
}

add-zsh-hook precmd _prompt_precmd

async_start_worker "my_prompt" -u -n
async_register_callback "my_prompt" _prompt_callback
