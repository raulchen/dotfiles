#!/bin/bash
# Update the current tmux window name to the project root directory name.
# Usage: tmux_update_window_name.sh [window_id] [pane_current_path]
if [ -z "$TMUX" ]; then
    exit 0
fi

window_id="$1"
pane_path="$2"

# Fall back to querying window_id if not provided (safe when called from shell's precmd)
if [ -z "$window_id" ]; then
    window_id="$(tmux display-message -p '#{window_id}')"
fi

if [ -z "$pane_path" ]; then
    pane_path="$(pwd)"
fi

project_root="$(find_project_root.sh "$pane_path")"
window_name="$(basename "$project_root")"
tmux rename-window -t "$window_id" "$window_name"
