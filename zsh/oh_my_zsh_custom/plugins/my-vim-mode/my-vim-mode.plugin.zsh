bindkey -v

# Super fast escape time
export KEYTIMEOUT=1

local block="\e[1 q"
local underline="\e[3 q"
local vertical_bar="\e[5 q"

function zle-keymap-select {
  case $KEYMAP in
    viins|main) echo -ne "$vertical_bar";;
    *)     echo -ne "$block";;
  esac

  zle reset-prompt
  zle -R
}

function zle-line-init {
  echo -ne "$vertical_bar"
  echoti smkx
}

function zle-line-finish {
  echo -ne "$block"
  echoti rmkx
}

zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

# Expand ".../"
function expand-dots {
   if [[ $LBUFFER =~ ".*\.\.\.$" ]]; then
	 zle _expand_alias
	 zle expand-word
   fi
   zle self-insert
}
zle -N expand-dots
bindkey -M viins "/" expand-dots

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
