alias -g H="2>&1 | head"
alias -g L="2>&1 | less"
alias -g VL="2>&1 | vless"
alias -g G="2>&1 | grep -i"
alias -g F="2>&1 | fzf --reverse"
alias -g C="2>&1 | tmux load-buffer -"
alias -g N="> /dev/null 2>&1 "

alias tailf="tail -f"
unalias d >/dev/null 2>&1
alias d="dirs -v | head -10"
alias v="vim"
alias vi="vim"
alias tat="tmux new -A -s default"

alias proxy_on="export {http,https,ftp}_proxy=http://127.0.0.1:7890; export socks_proxy=socks5://127.0.0.1:7891; no_proxy='localhost,127.0.0.1,*.local'"
alias proxy_off="unset {http,https,ftp,all,socks,no}_proxy"

if [[ `uname` == 'Darwin' ]]; then
    # Flush Directory Service cache
    alias flushdns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"

    # Hide/show all desktop icons (useful when presenting)
    alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
    alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

    # Merge PDF files
    # Usage: `mergepdf -o output.pdf input{1,2,3}.pdf`
    alias mergepdf='/System/Library/Automator/Combine\ PDF\ Pages.action/Contents/Resources/join.py'
fi

# lsd
if type lsd >/dev/null 2>&1 ; then
    _lsd_params="--date +'%Y-%m-%d %H:%M:%S' --group-dirs=first"
    alias ls="lsd $_lsd_params"
    alias ll="lsd -l $_lsd_params"
    alias la="lsd -la $_lsd_params"
    alias lt="lsd --tree $_lsd_params"
    alias tree="lsd --tree $_lsd_params"
fi

# git
alias g="git"
# automatically set git alias from git config
for al in `git --list-cmds=alias`; do
    alias g$al="git $al"
done
