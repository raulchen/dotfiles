#!/usr/bin/env bash

# Tmux fzf file picker - select files and insert them into the current pane

# Exit if not running in tmux
if [ -z "$TMUX" ]; then
    echo "Error: This script must be run from within tmux" >&2
    exit 1
fi

# Get the optional working directory
PANE_PATH="${1:-$(pwd)}"

# Change to the pane's directory
cd "$PANE_PATH" || exit 1

# Capture the current pane ID before fzf opens
PANE_ID="$TMUX_PANE"

# Run FZF_DEFAULT_COMMAND and pipe to fzf
# Let fzf read FZF_CTRL_T_OPTS via FZF_DEFAULT_OPTS environment variable
selected=$(eval "$FZF_DEFAULT_COMMAND" | \
    FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}" fzf)

# If files were selected, insert them into the current pane
if [ -n "$selected" ]; then
    # Convert newlines to spaces and send to the target pane
    echo "$selected" | tr '\n' ' ' | sed 's/ $//' | xargs -I {} tmux send-keys -t "$PANE_ID" -l "{}"
fi
