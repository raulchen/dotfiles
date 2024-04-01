#!/bin/bash
# Attach to a tmux session+window or create it if it doesn't exist.
# Usage: tmux_attach.sh <session_name> <window_name> <working_dir>

SESSION_NAME="$1"
WINDOW_NAME="$2"
WORKING_DIR="$3"

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux new-session -s "$SESSION_NAME" -n "$WINDOW_NAME" -c "$WORKING_DIR"
else
    if ! tmux list-windows -t "$SESSION_NAME" | grep -q "$WINDOW_NAME"; then
        tmux new-window -d -t "$SESSION_NAME" -n "$WINDOW_NAME" -c "$WORKING_DIR"
    fi
    tmux attach-session -t "$SESSION_NAME":"$WINDOW_NAME"
fi

