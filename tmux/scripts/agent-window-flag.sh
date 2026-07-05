#!/usr/bin/env bash
# Per-window coding-agent indicator for the tmux window list.
#
# Prints the agent logo, coloured, when an agent whose project cwd matches THIS
# window is waiting (red) or working (yellow); nothing otherwise. Used as a
# prefix in window-status-format via:
#     #(agent-window-flag.sh '#{pane_current_path}')#I.#W#F
# so the logo leads the window name — even though the agent runs in a hidden
# tmux session (nvim sidekick.nvim). Matched by exact cwd.
#
# A matched file for a dead session is pruned here (belt-and-braces with the
# focus-in cleanup in agent-status-seen.sh).
set -uo pipefail
shopt -s nullglob

LOGO="󰚩 "

wpath=${1:-}
[ -n "$wpath" ] || exit 0

dir=${XDG_CACHE_HOME:-$HOME/.cache}/agent-status
found=""
for f in "$dir"/*; do
  IFS=$'\t' read -r state cwd < "$f" || continue
  [ "$cwd" = "$wpath" ] || continue
  # prune if the owning tmux session is gone
  if ! tmux has-session -t "=$(basename "$f")" 2>/dev/null; then
    rm -f "$f"
    continue
  fi
  case "$state" in
    wait) found=wait; break ;;   # waiting wins over working
    busy) found=busy ;;
  esac
done

case "$found" in
  wait) printf '#[fg=red]%s#[default]' "$LOGO" ;;
  busy) printf '#[fg=yellow]%s#[default]' "$LOGO" ;;
esac
