# Print all colors:
# for code in {000..255}; do print -P -- "$code: %F{$code}Color%f"; done

local PROMPT_SEPARATOR=" "

ZSH_THEME_GIT_PROMPT_SEPARATOR=""
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX="$PROMPT_SEPARATOR"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[blue]%}%{↓%G%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[blue]%}%{↑%G%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[blue]%}%{~%G%}"
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[blue]%}%{⚑%G%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[green]%}%{✔%G%}"

# Disable default venv prompt modification
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Show venv name
function venv_prompt() {
    if [[ -n "$VIRTUAL_ENV_PROMPT" ]]; then
        local project_dir="${VIRTUAL_ENV:h}"
        # Drop the venv name if in the project dir.
        if [[ "$PWD" == "$project_dir" || "$PWD" == "$project_dir"/* ]]; then
            echo " "
        else
            echo " $VIRTUAL_ENV_PROMPT$PROMPT_SEPARATOR"
        fi
    fi
}

PROMPT='%{$fg[yellow]%}%(?,,%{${fg[red]}%})❯$PROMPT_SEPARATOR%{$reset_color%}'
RPROMPT='$(git_super_status)%{$fg[yellow]%}$(venv_prompt)%~$PROMPT_SEPARATOR%{$fg[green]%}%*%{$reset_color%}'

# Remove the extra space after the right prompt.
ZLE_RPROMPT_INDENT=0
