#!/bin/bash
# Update the current tmux window name to the project root directory name.
# Usage: tmux_update_window_name.sh [window_id] [pane_current_path]
#
# Naming logic:
#   - Regular repo: "repo"
#   - Worktree: "repo:worktree"
#   - Monorepo with sub-project: "repo:subproject"
#   - Monorepo worktree with sub-project: "repo:subproject:worktree"

[[ -z "$TMUX" ]] && exit 0

# Only update from the first pane in the window (pane-base-index is 1)
[[ "$(tmux display-message -p '#{pane_index}')" != "1" ]] && exit 0

window_id="${1:-$(tmux display-message -p '#{window_id}')}"
pane_path="${2:-$PWD}"

# Get git info in a single call (avoids multiple subprocess spawns)
if git_info="$(git -C "$pane_path" rev-parse --path-format=absolute --git-dir --git-common-dir --show-toplevel 2>/dev/null)"; then
    # Parse the three lines of output
    git_dir="${git_info%%$'\n'*}"
    git_info="${git_info#*$'\n'}"
    git_common_dir="${git_info%%$'\n'*}"
    git_toplevel="${git_info#*$'\n'}"

    # Determine repo name and worktree name
    if [[ "$git_dir" != "$git_common_dir" ]]; then
        # In a worktree: repo is parent of .git, worktree is the toplevel basename
        repo_root="${git_common_dir%/.git}"
        repo_name="${repo_root##*/}"
        worktree_name="${git_toplevel##*/}"
    else
        repo_name="${git_toplevel##*/}"
        worktree_name=""
    fi

    # Find sub-project within git toplevel
    project_root="$(find_project_root.sh "$pane_path")"
    subproject_name=""
    if [[ "$project_root" != "$git_toplevel" && "$project_root" == "$git_toplevel"/* ]]; then
        subproject_name="${project_root##*/}"
    fi

    # Build window name
    window_name="$repo_name"
    [[ -n "$subproject_name" ]] && window_name="$window_name:$subproject_name"
    [[ -n "$worktree_name" ]] && window_name="$window_name:$worktree_name"
else
    # Not a git repo, find project root
    project_root="$(find_project_root.sh "$pane_path")"
    window_name="${project_root##*/}"
fi

tmux rename-window -t "$window_id" "${window_name:0:25}"
