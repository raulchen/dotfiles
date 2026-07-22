#!/usr/bin/env bash
# fzf-based tmux switcher, in two modes (replaces the built-in choose-tree):
#
#   session  - pick from all sessions and switch the client to it (prefix+s).
#   window   - pick from windows in the current session and select it (prefix+w).
#
# fzf opens itself in a tmux popup via --tmux, so this can be launched from a
# run-shell binding without a tty of its own.

set -uo pipefail

mode="${1:-session}"

# The client that triggered the switch (so switch-client targets it explicitly).
client="$(tmux display-message -p '#{client_name}')"

case "$mode" in
  session)
    prompt='session> '
    # current session, for the active-row marker.
    current="$(tmux display-message -p '#{session_name}')"
    # <sortkey=last-visit>\t<target=session_name>\t<display: name + window count>
    list="$(tmux list-sessions -F \
      '#{?#{@svisit},#{@svisit},0}	#{session_name}	#{p24:#{session_name}} #{session_windows} windows')"
    ;;
  window)
    prompt='window> '
    session="$(tmux display-message -p '#{session_name}')"
    current="$(tmux display-message -p '#{session_name}:#{window_index}')"
    # <sortkey=last-visit>\t<target=session:index>\t<display: index:name + path>
    list="$(tmux list-windows -t "$session" -F \
      '#{?#{@wvisit},#{@wvisit},0}	#{session_name}:#{window_index}	#{p20:#{window_index}:#{window_name}} #{=/-50/…:#{s|^$HOME|~:pane_current_path}}')"
    ;;
  *)
    echo "usage: $0 [session|window]" >&2
    exit 2
    ;;
esac

# Sort by last-visit time (sort key = field 1, desc), then drop the key.
# String reverse sort is exact for the equal-width ns timestamps and sinks the
# never-visited "0" rows to the bottom.
# Prepend a marker to the active row; hide the target column from the list.
selected="$(
  printf '%s\n' "$list" \
  | sort -t$'\t' -k1,1r \
  | cut -f2- \
  | awk -F'\t' -v cur="$current" 'BEGIN { OFS = "\t" } {
        mark = ($1 == cur) ? "●" : " "
        print $1, mark " " $2
    }' \
  | fzf --ansi \
        --tmux=center,85%,80% \
        --delimiter='\t' \
        --with-nth=2 \
        --bind='load:pos(2)' \
        --prompt="$prompt" \
        --preview='tmux capture-pane -ep -t {1}' \
        --preview-window='right,50%'
)"

# No selection (e.g. Esc) is a normal, silent exit.
target="${selected%%$'\t'*}"
if [ -n "$target" ]; then
  tmux switch-client -c "$client" -t "$target"
fi
