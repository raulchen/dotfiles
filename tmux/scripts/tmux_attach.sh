#!/bin/bash
# Attach to a tmux session+window or create it if it doesn't exist.
# Usage: tmux_attach.sh <session_name> <window_name> <working_dir>

SESSION_NAME="$1"
WINDOW_NAME="$2"
WORKING_DIR="$3"

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    # Create session if not exists
    tmux new-session -s "$SESSION_NAME" -n "$WINDOW_NAME" -c "$WORKING_DIR"
else
    # Find the first window with the given name under the session.
    WINDOW_ID=$(tmux list-windows -t "$SESSION_NAME"  -F "#{window_id} #{window_name}" | grep "$WINDOW_NAME$" | head -n 1 | awk '{print $1}')
    if [ -n "$WINDOW_ID" ]; then
        # If the window exists, attach to it.
        tmux attach-session -t "$SESSION_NAME":"$WINDOW_ID"
    else
        # Otherwise, create a new window under the session and attach to it.
        tmux new-window -d -t "$SESSION_NAME" -n "$WINDOW_NAME" -c "$WORKING_DIR"
        tmux attach-session -t "$SESSION_NAME":"$WINDOW_NAME"
    fi
fi

