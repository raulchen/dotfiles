# Hammerspoon

Some of the following key bindings are inspired by Tmux. The default prefix key is `` ctrl+` ``. E.g., `prefix - a` means to press `` ctrl+` `` first, then press `a`.

# Window management

- `prefix - g`: show a 6x6 grid that lets you set the window frame.
- `option [ + shift ] + tab`: switch windows.

Resize and move windows:

- `prefix - hjkl`: move window to the left/bottom/up/right half of screen.
- `prefix - hj/hk/jl/kl`: move window to the four corners of screen.
- `prefix - jk`: move window to the center of screen.
- `prefix - hl`: fullscreen window.
- `prefix - ctrl+h`: move window to the left one-third of screen.
- `prefix - ctrl+j`: move window to the left two-thirds of screen.
- `prefix - ctrl+k`: move window to the right two-thirds of screen.
- `prefix - ctrl+l`: move window to the right one-third of screen.
- `prefix - ;`: move window to the next screen.
- `prefix - =`: expand window frame.
- `prefix - -`: shrink window frame.
- `prefix - shift+hjkl`: move window around (press esc to exit prefix mode when you're done moving).
- `prefix - cmd+hjkl`: expand window edges.
- `prefix - cmd+shift+hjkl`: shrink window edges.

# Double CMD+Q to quit app

Press `cmd+q` twice to quit current app, in order to avoid unintended quits.

# Option key based key bindings

In macOS, the option key is used to input special characters that most people barely use. Let's make it more useful.

- `option + hjkl`: vim-style arrow keys.
- `option + shift + hjkl`: option + arrow keys (move faster).
- `option + shift + ctrl + hjkl`: shift + arrow keys (selection).
- `option + y`: home.
- `option + u`: end.
- `option + i`: page_up.
- `option + o`: page_down.
- `option + d`: delete.
- `option + f`: forward delete.
- `option + shift + d`: option + delete.
- `option + shift + f`: option + forward delete.
- `option + n/m`: cmd [+ shift] + tab (switch tabs).
- `option + q`: esc.
- `option + a`: capslock.
- `option + p` / `option + 1`: play.
- `option + [` / `option + 2`: previous track.
- `option + ]` / `option + 3`: next track.
- `option + /` / `option + f1`: mute.
- `option + ,` / `option + f2`: volume down.
- `option + .` / `option + f3`: volume up.

# Smart modifier keys

Make the modifier keys smarter:
- Tap `ctrl` alone: esc.
- Tap `shift` alone: switch to next input method.

# URL dispatcher

When Hammerspoon is set as the default browser, a prompt will be shown to let you choose which browser to open a URL with.

# Other features

- `prefix - m`: switch primary monitor.
- `prefix - c`: toggle caffeinate (disable sleep).
- `prefix - s`: start screen saver.
- `prefix - r`: reload Hammerspoon config.
- `prefix - d`: toggle Hammerspoon console for debug.
