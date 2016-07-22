#!/bin/sh

verify_tmux_verision () {
    tmux_home=~/dotfiles/tmux
    tmux_version="$(tmux -V | cut -c 6-)"
    
    if [[ $(echo "$tmux_version >= 2.1" | bc) -eq 1 ]] ; then
        tmux source-file "$tmux_home/tmux_ge_2.1.conf"
        exit
    else
        tmux source-file "$tmux_home/tmux_lt_2.1.conf"
        exit
    fi
}

verify_tmux_verision
