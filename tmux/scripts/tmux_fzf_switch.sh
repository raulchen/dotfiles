#!/usr/bin/env bash
# fzf-based tmux switcher, in two modes (replaces the built-in choose-tree):
#
#   session  - pick from all sessions and switch the client to it (prefix+s).
#   window   - pick from windows in the current session and select it (prefix+w).
#
# In-switcher key binds:
#   Tab     - toggle between session and window mode (re-execs this script).
#   ctrl-x  - kill the highlighted session/window, then reload the list.
#   ctrl-r  - rename the highlighted session/window, then reload the list.

set -uo pipefail

# Emits the coloured agent logo (ANSI) for a given cwd, empty if none waiting.
flag_script="$HOME/.config/tmux/scripts/agent-window-flag.sh"

# Print the fzf input rows for a mode as <target>\t<display>, where display is
# the active-row marker + agent flag + the human-readable columns. Shared by the
# initial run and by ctrl-x/ctrl-r's reload (invoked as `$0 --emit <mode>`).
emit_rows() {
  local mode="$1" current list session
  case "$mode" in
    session)
      current="$(tmux display-message -p '#{session_name}')"
      # <sortkey>\t<target=session_name>\t<path>\t<display: name + window count>
      list="$(tmux list-sessions -F \
        '#{?#{@svisit},#{@svisit},0}	#{session_name}	#{pane_current_path}	#{p24:#{session_name}} #{session_windows} windows')"
      ;;
    window)
      session="$(tmux display-message -p '#{session_name}')"
      current="$(tmux display-message -p '#{session_name}:#{window_index}')"
      # <sortkey>\t<target=session:index>\t<path>\t<display: index:name + path>
      list="$(tmux list-windows -t "$session" -F \
        '#{?#{@wvisit},#{@wvisit},0}	#{session_name}:#{window_index}	#{pane_current_path}	#{p20:#{window_index}:#{window_name}} #{=/-50/…:#{s|^$HOME|~:pane_current_path}}')"
      ;;
  esac

  # Sort by last-visit time (sort key = field 1, desc), then drop the key.
  # String reverse sort is exact for the equal-width ns timestamps and sinks the
  # never-visited "0" rows to the bottom.
  # Then, per row: mark the active row and prepend the agent flag for its cwd.
  # Emitted as <target>\t<display>, so fzf shows only field 2 but keeps the
  # target in field 1 for the preview and switch.
  printf '%s\n' "$list" \
    | sort -t$'\t' -k1,1r \
    | cut -f2- \
    | while IFS=$'\t' read -r target path display; do
        [ "$target" = "$current" ] && mark='●' || mark=' '
        flag="$("$flag_script" "$path" ansi)"
        printf '%s\t%s %s%s\n' "$target" "$mark" "$flag" "$display"
      done
}

# Reload/emit hook: print rows for the given mode and exit. Used by ctrl-x and
# ctrl-r's reload() action, which needs a command it can re-run standalone.
if [ "${1:-}" = "--emit" ]; then
  emit_rows "${2:-session}"
  exit 0
fi

mode="${1:-session}"

# The client that triggered the switch (so switch-client targets it explicitly).
client="$(tmux display-message -p '#{client_name}')"

case "$mode" in
  session)
    prompt='session> '
    other='window'
    # Refuse to kill the session the client is attached to (killing it would
    # yank the client to another session out from under the popup); ring the
    # bell instead. transform() lets the refusal and the kill emit different
    # follow-up actions.
    kill_bind='ctrl-x:transform(if [ {1} = "$(tmux display-message -p "#{session_name}")" ]; then echo bell; else tmux kill-session -t {1}; echo "reload('"$0"' --emit session)"; fi)'
    # Session name is the target itself, so prefill rename with it.
    rename_bind='ctrl-r:execute(tmux command-prompt -I {1} -p "rename session:" "rename-session -t {1} '"'"'%%'"'"'")+reload('"$0"' --emit session)'
    ;;
  window)
    prompt='window> '
    other='session'
    kill_bind='ctrl-x:execute-silent(tmux kill-window -t {1})+reload('"$0"' --emit window)'
    # Target is session:index; prefill rename with the current window name.
    rename_bind='ctrl-r:execute(tmux command-prompt -I "$(tmux display-message -pt {1} "#{window_name}")" -p "rename window:" "rename-window -t {1} '"'"'%%'"'"'")+reload('"$0"' --emit window)'
    ;;
  *)
    echo "usage: $0 [session|window]" >&2
    exit 2
    ;;
esac

# Popup geometry, --reverse, --preview-window and the common key binds come
# from FZF_DEFAULT_OPTS (which sets --tmux, so this runs from a run-shell
# binding without a tty); only switcher-specific options are passed here.
#   Tab    -> re-exec in the other mode.
#   ctrl-x -> kill highlighted target, then reload (session mode guards self).
#   ctrl-r -> rename highlighted target, then reload.
selected="$(
  emit_rows "$mode" \
  | fzf --ansi \
        --delimiter='\t' \
        --with-nth=2 \
        --bind='load:pos(2)' \
        --bind="tab:become($0 $other)" \
        --bind="$kill_bind" \
        --bind="$rename_bind" \
        --header='tab: switch mode · ctrl-x: kill · ctrl-r: rename' \
        --prompt="$prompt" \
        --preview='tmux capture-pane -ep -t {1}'
)"

# No selection (e.g. Esc) is a normal, silent exit.
target="${selected%%$'\t'*}"
if [ -n "$target" ]; then
  tmux switch-client -c "$client" -t "$target"
fi
