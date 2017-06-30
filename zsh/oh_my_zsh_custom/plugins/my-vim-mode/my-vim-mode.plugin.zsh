bindkey -v

# Super fast escape time
export KEYTIMEOUT=1

# ===================
# Mode indicator
# ===================

function zle-keymap-select() {
  zle reset-prompt
  zle -R
}

zle -N zle-keymap-select

if [[ "$MODE_INDICATOR" == "" ]]; then
  MODE_INDICATOR="%{$fg[red]%}N%{$fg[black]%}|%{$reset_color%}"
fi

function my_vim_mode_prompt_info() {
  echo "${${KEYMAP/vicmd/$MODE_INDICATOR}/(main|viins)/}"
}

# ===================
# Extra keybindings
# ===================

# Ctrl-V: edit in vim
bindkey '^V' edit-command-line
bindkey -M vicmd '^V' edit-command-line

bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history

bindkey '^B' backward-char
bindkey '^F' forward-char

bindkey '^H' backward-delete-char
bindkey '^W' backward-kill-word

bindkey '^R' history-incremental-search-backward

bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

bindkey "^D" copy-prev-shell-word

# -----------------------------------------------------
# below are copied from oh-my-zsh/lib/key-bindings.zsh
# -----------------------------------------------------

if [[ "${terminfo[kcuu1]}" != "" ]]; then
  bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
fi
# start typing + [Down-Arrow] - fuzzy find history backward
if [[ "${terminfo[kcud1]}" != "" ]]; then
  bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
fi

if [[ "${terminfo[kcbt]}" != "" ]]; then
  bindkey "${terminfo[kcbt]}" reverse-menu-complete   # [Shift-Tab] - move through the completion menu backwards
fi

bindkey '^?' backward-delete-char                     # [Backspace] - delete backward
if [[ "${terminfo[kdch1]}" != "" ]]; then
  bindkey "${terminfo[kdch1]}" delete-char            # [Delete] - delete forward
else
  bindkey "^[[3~" delete-char
  bindkey "^[3;5~" delete-char
  bindkey "\e[3~" delete-char
fi

bindkey ' ' magic-space                         # [Space] - do history expansion
