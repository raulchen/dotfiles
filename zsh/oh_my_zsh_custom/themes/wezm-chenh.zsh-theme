PROMPT='$(git_prompt_info)%(?,,%{${fg_bold[white]}%}%?%{$fg[black]%}|%{$reset_color%})%{$fg[yellow]%}$ %{$reset_color%}'
RPROMPT='%{$fg[green]%}%~%{$fg[black]%}|%{$fg_bold[yellow]%}%*%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}✘%{$fg[black]%}|"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[black]%}|"
