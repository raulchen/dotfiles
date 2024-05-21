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
PROMPT='%{$fg[yellow]%}%(?,,%{${fg[red]}%})❯$PROMPT_SEPARATOR%{$reset_color%}'
RPROMPT='$(git_super_status)%{$fg[yellow]%}%~$PROMPT_SEPARATOR%{$fg[green]%}%*%{$reset_color%}'

# Remove the extra space after the right prompt.
ZLE_RPROMPT_INDENT=0
