# Git status for the prompt, replacing the oh-my-zsh git-prompt plugin.
#
# The plugin cost two `git status` runs per prompt: it registered
# precmd_update_git_vars on precmd, and its git_super_status called that same
# function again when RPROMPT expanded `$(git_super_status)`. Each run also
# shelled out to `python3 gitstatus.py`, paying ~45ms of interpreter startup
# and `import re, subprocess` before any git work happened.
#
# Here the work happens once per prompt, in-process, and the rendered string is
# stashed in $_GIT_PROMPT so RPROMPT is a plain parameter expansion with no
# command substitution. Styling comes entirely from the ZSH_THEME_GIT_PROMPT_*
# variables the theme sets.

autoload -Uz add-zsh-hook

# Counters parsed by _gitstatus_collect, rendered by _git_prompt_update.
typeset -gA _gitstatus

# Cached `git rev-parse --git-common-dir`; only re-resolved when $PWD changes.
typeset -g _gitstatus_common_dir= _gitstatus_common_dir_pwd=

# Detached HEAD label: the tag at HEAD ('+' when several point there), else the
# short hash. Sets $REPLY.
_gitstatus_head_label() {
    local -a tags
    tags=( ${(f)"$(command git for-each-ref --points-at=HEAD --count=2 \
        --sort=-version:refname --format='%(refname:short)' refs/tags 2>/dev/null)"} )
    if (( $#tags )); then
        REPLY=$tags[1]
        (( $#tags > 1 )) && REPLY+='+'
    else
        REPLY=$(command git rev-parse --short HEAD 2>/dev/null)
    fi
}

# Stash count in $REPLY. Stashes live in the common dir, shared by every
# worktree, so the lookup only changes when we cd.
_gitstatus_stash_count() {
    if [[ $_gitstatus_common_dir_pwd != $PWD ]]; then
        _gitstatus_common_dir="$(command git rev-parse --git-common-dir 2>/dev/null)"
        _gitstatus_common_dir_pwd=$PWD
    fi

    REPLY=0
    # -s, not -r: an emptied reflog must count 0.
    local reflog="$_gitstatus_common_dir/logs/refs/stash"
    [[ -s $reflog ]] || return
    local log="$(<$reflog)"
    # Unquoted (f) splitting, so the trailing empty field is dropped.
    local -a entries=( ${(f)log} )
    REPLY=$#entries
}

# Fill $_gitstatus. Returns non-zero outside a repository.
_gitstatus_collect() {
    emulate -L zsh
    setopt extendedglob

    _gitstatus=()

    local out
    out=$(LANG=C command git status --porcelain --branch 2>/dev/null) || return 1

    # XY is always two columns followed by a space, so no entry can look like
    # the '## ' branch header.
    local -a lines=( ${(f)out} )
    local header=${${(M)lines:#'## '*}[1]}
    local -a entries=( ${lines:#'## '*} )

    local branch= REPLY
    local -i ahead=0 behind=0
    local info=${${header#'## '}## #}
    if [[ $info == *('Initial commit on '|'No commits yet on ')* ]]; then
        branch=${info##* }
    elif [[ $info == *'no branch'* ]]; then
        _gitstatus_head_label
        branch=$REPLY
    elif [[ $info != *...* ]]; then
        branch=$info
    else
        branch=${info%%...*}
        local rest=${info#*...}
        if [[ $rest == *'['*']'* ]]; then
            local div=${${rest#*\[}%\]*}
            [[ $div == (#b)*'ahead '([0-9]##)* ]] && ahead=$match[1]
            [[ $div == (#b)*'behind '([0-9]##)* ]] && behind=$match[1]
        fi
    fi

    # Column semantics from gitstatus.py: changed/deleted key off the worktree
    # column, conflicts and staged are mutually exclusive on the index column.
    # Array filters rather than a per-line loop -- 3000 status lines cost ~20ms
    # to walk in shell and ~0 here.
    local -i untracked=${#${(M)entries:#'??'*}}
    local -i changed=${#${(M)entries:#[^?]M*}}
    local -i deleted=${#${(M)entries:#[^?]D*}}
    local -i conflicts=${#${(M)entries:#U*}}
    local -i staged=${#${(M)entries:#[^ ?U]*}}

    _gitstatus_stash_count

    _gitstatus=(
        branch    "$branch"
        ahead     $ahead
        behind    $behind
        staged    $staged
        conflicts $conflicts
        changed   $changed
        deleted   $deleted
        untracked $untracked
        stashed   $REPLY
        clean     $(( changed + deleted + staged + conflicts + untracked == 0 ))
    )
}

# Render into $_GIT_PROMPT. Field order and reset placement match the plugin's
# git_super_status exactly.
_git_prompt_update() {
    emulate -L zsh
    typeset -g _GIT_PROMPT=''

    _gitstatus_collect || return

    local upstream=
    if [[ -n ${ZSH_THEME_GIT_SHOW_UPSTREAM+x} ]]; then
        upstream=$(command git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) \
            && upstream="${ZSH_THEME_GIT_PROMPT_UPSTREAM_SEPARATOR}${upstream}"
    fi

    local -i behind=$_gitstatus[behind] ahead=$_gitstatus[ahead] \
             staged=$_gitstatus[staged] conflicts=$_gitstatus[conflicts] \
             changed=$_gitstatus[changed] deleted=$_gitstatus[deleted] \
             untracked=$_gitstatus[untracked] stashed=$_gitstatus[stashed] \
             clean=$_gitstatus[clean]

    local s="$ZSH_THEME_GIT_PROMPT_PREFIX$ZSH_THEME_GIT_PROMPT_BRANCH$_gitstatus[branch]$upstream%{$reset_color%}"
    (( behind ))    && s+="$ZSH_THEME_GIT_PROMPT_BEHIND$behind%{$reset_color%}"
    (( ahead ))     && s+="$ZSH_THEME_GIT_PROMPT_AHEAD$ahead%{$reset_color%}"
    s+="$ZSH_THEME_GIT_PROMPT_SEPARATOR"
    (( staged ))    && s+="$ZSH_THEME_GIT_PROMPT_STAGED$staged%{$reset_color%}"
    (( conflicts )) && s+="$ZSH_THEME_GIT_PROMPT_CONFLICTS$conflicts%{$reset_color%}"
    (( changed ))   && s+="$ZSH_THEME_GIT_PROMPT_CHANGED$changed%{$reset_color%}"
    (( deleted ))   && s+="$ZSH_THEME_GIT_PROMPT_DELETED$deleted%{$reset_color%}"
    (( untracked )) && s+="$ZSH_THEME_GIT_PROMPT_UNTRACKED$untracked%{$reset_color%}"
    (( stashed ))   && s+="$ZSH_THEME_GIT_PROMPT_STASHED$stashed%{$reset_color%}"
    (( clean ))     && s+="$ZSH_THEME_GIT_PROMPT_CLEAN"
    s+="%{$reset_color%}$ZSH_THEME_GIT_PROMPT_SUFFIX"

    _GIT_PROMPT=$s
}

add-zsh-hook precmd _git_prompt_update
