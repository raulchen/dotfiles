#!/usr/bin/env bash
# Stamp the focused window and its session with a "last visited" timestamp
# (epoch nanoseconds), so tmux_fzf_switch.sh can order by last-visit time.
#
# Called from the pane-focus-in hook. Window and session use distinct option
# names because window formats inherit session-scoped user options.
#
# Usage: tmux_stamp_visit.sh <window_id> <session_name>

win="$1"
session="$2"
ts="$(date +%s%N)"

tmux set -w -t "$win" @wvisit "$ts"
tmux set -t "$session" @svisit "$ts"
