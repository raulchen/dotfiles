#!/usr/bin/env bash
# Acknowledge a waiting agent when you switch to the window showing its project,
# after it has requested attention.
#
# Bound to tmux's pane-focus-in: clears the "waiting" (red) flag for the agent
# whose cwd matches the focused window's path, so the indicator goes away once
# you've actually looked. The agent may still be blocked on input — this is a
# "seen it" signal, not a state change on the agent's side. It re-flags on the
# next Notification, or after you respond (busy -> done -> idle).
#
set -uo pipefail
shopt -s nullglob

wpath=${1:-}

dir=${XDG_CACHE_HOME:-$HOME/.cache}/agent-status
for f in "$dir"/*; do
  # acknowledge the focused window's waiting agent
  IFS=$'\t' read -r state cwd < "$f" || continue
  [ -n "$wpath" ] && [ "$state" = wait ] && [ "$cwd" = "$wpath" ] && rm -f "$f"
done
