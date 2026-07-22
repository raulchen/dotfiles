#!/usr/bin/env bash
# fzf-based tmux switcher, in two modes (replaces the built-in choose-tree):
#
#   session  - pick from all sessions and switch the client to it (prefix+s).
#   window   - pick from windows in the current session and select it (prefix+w).

set -uo pipefail

mode="${1:-session}"

# The client that triggered the switch (so switch-client targets it explicitly).
client="$(tmux display-message -p '#{client_name}')"

# Emits the coloured agent logo (ANSI) for a given cwd, empty if none waiting.
flag_script="$HOME/.config/tmux/scripts/agent-window-flag.sh"

case "$mode" in
  session)
    prompt='session> '
    # current session, for the active-row marker.
    current="$(tmux display-message -p '#{session_name}')"
    # <sortkey>\t<target=session_name>\t<path>\t<display: name + window count>
    list="$(tmux list-sessions -F \
      '#{?#{@svisit},#{@svisit},0}	#{session_name}	#{pane_current_path}	#{p24:#{session_name}} #{session_windows} windows')"
    ;;
  window)
    prompt='window> '
    session="$(tmux display-message -p '#{session_name}')"
    current="$(tmux display-message -p '#{session_name}:#{window_index}')"
    # <sortkey>\t<target=session:index>\t<path>\t<display: index:name + path>
    list="$(tmux list-windows -t "$session" -F \
      '#{?#{@wvisit},#{@wvisit},0}	#{session_name}:#{window_index}	#{pane_current_path}	#{p20:#{window_index}:#{window_name}} #{=/-50/…:#{s|^$HOME|~:pane_current_path}}')"
    ;;
  *)
    echo "usage: $0 [session|window]" >&2
    exit 2
    ;;
esac

# Sort by last-visit time (sort key = field 1, desc), then drop the key.
# String reverse sort is exact for the equal-width ns timestamps and sinks the
# never-visited "0" rows to the bottom.
# Then, per row: mark the active row and prepend the agent flag for its cwd.
# Emitted as <target>\t<display>, so fzf shows only field 2 but keeps the
# target in field 1 for the preview and switch.
selected="$(
  printf '%s\n' "$list" \
  | sort -t$'\t' -k1,1r \
  | cut -f2- \
  | while IFS=$'\t' read -r target path display; do
      [ "$target" = "$current" ] && mark='●' || mark=' '
      flag="$("$flag_script" "$path" ansi)"
      printf '%s\t%s %s%s\n' "$target" "$mark" "$flag" "$display"
    done |
  # Popup geometry, --reverse, --preview-window and the common key binds come
  # from FZF_DEFAULT_OPTS (which sets --tmux, so this runs from a run-shell
  # binding without a tty); only switcher-specific options are passed here.
  fzf --ansi \
        --delimiter='\t' \
        --with-nth=2 \
        --bind='load:pos(2)' \
        --prompt="$prompt" \
        --preview='tmux capture-pane -ep -t {1}'
)"

# No selection (e.g. Esc) is a normal, silent exit.
target="${selected%%$'\t'*}"
if [ -n "$target" ]; then
  tmux switch-client -c "$client" -t "$target"
fi
