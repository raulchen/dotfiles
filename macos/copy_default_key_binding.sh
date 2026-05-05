#!/bin/bash
# Symlinks don't work for ~/Library/KeyBindings/DefaultKeyBinding.dict because
# sandboxed apps refuse to follow symlinks that point
# outside ~/Library/. A hard copy is required instead.

base_dir=$(cd "$(dirname "$0")" && pwd)
mkdir -p ~/Library/KeyBindings
cp "$base_dir/DefaultKeyBinding.dict" ~/Library/KeyBindings/DefaultKeyBinding.dict
