#!/bin/bash
# Update the current tmux window name to the project root directory name.
if [ -z "$TMUX" ]; then
    exit 0
fi

tmux_update_window_name() {
    project_root="$(find_project_root.sh "$1")"
    window_name="$(basename "$project_root")"
    tmux rename-window -t "$(tmux display-message -p '#{window_id}')" "$window_name"
}

pwd="$1"
if [ -z "$pwd" ]; then
    pwd="$(pwd)"
fi

tmux_update_window_name $pwd
