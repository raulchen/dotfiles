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

# Append branch name if in a git worktree
git_dir="$(cd "$project_root" && realpath "$(git rev-parse --git-dir 2>/dev/null)" 2>/dev/null)"
if [ -n "$git_dir" ]; then
    git_common_dir="$(cd "$project_root" && realpath "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null)"
    if [ "$git_dir" != "$git_common_dir" ]; then
        # In a worktree: use repo name + worktree folder name
        repo_name="$(basename "$(dirname "$git_common_dir")")"
        worktree_name="$(basename "$project_root")"
        window_name="$repo_name:$worktree_name"
    fi
fi

# Limit window name to 25 characters
window_name="${window_name:0:25}"

tmux rename-window -t "$window_id" "$window_name"
