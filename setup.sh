#!/bin/bash
base_dir=$(cd "$(dirname "$0")" && pwd)
backup_dir="$base_dir/.backups.local"
backup_prefix="$backup_dir/$(date '+%Y%m%d%H%M%S')"
is_darwin=false
[[ $OSTYPE == darwin* ]] && is_darwin=true

link_file() {
    local src=$1 dst=$2
    local use_sudo=${3:-false}
    local -a command_prefix=()
    [[ $use_sudo == true ]] && command_prefix=(sudo)
    local backup_dst=false delete_dst=false link_dst=true
    if [[ -e $dst ]]; then
        current_link=$(readlink "$dst")
        if [[ "$current_link" != "$src" ]]; then
            while true; do
                printf "File already exists: %s. What do you want?\n" "$dst"
                printf "[r]eplace; [b]ack up; [s]kip: "
                read -r op
                case $op in
                    r )
                        delete_dst=true
                        link_dst=true
                        break;;
                    b )
                        backup_dst=true
                        delete_dst=true
                        link_dst=true
                        break;;
                    s )
                        link_dst=false
                        break;;
                    * )
                       echo "Unrecognized option: $op";;
               esac
            done
        else
            echo "$dst is already linked to $src"
            link_dst=false
        fi
    fi
    if [[ "$backup_dst" == "true" ]]; then
        mkdir -p "$backup_dir"
        local backup_file
        backup_file="$backup_prefix$(basename "$dst")"
        "${command_prefix[@]}" mv "$dst" "$backup_file"
        echo "$dst was backed up to $backup_file"
    fi
    if [[ "$delete_dst" == "true" ]]; then
        "${command_prefix[@]}" rm -rf "$dst"
    fi
    if [[ "$link_dst" == "true" ]]; then
        "${command_prefix[@]}" ln -s "$src" "$dst"
        echo "$dst linked to $src"
        return 0
    fi
    return 1
}

if [[ "$base_dir" != "$HOME/dotfiles" ]]; then
    link_file "$base_dir" ~/dotfiles
fi

link_file "$base_dir/zsh/zshrc" ~/.zshrc
link_file "$base_dir/zsh/zshenv" ~/.zshenv

link_file "$base_dir/vim/vimrc" ~/.vimrc

if [[ $is_darwin == true ]]; then
    link_file "$base_dir/hammerspoon" ~/.hammerspoon
    "$base_dir/macos/copy_default_key_binding.sh"
fi

mkdir -p ~/.claude
for f in "$base_dir"/claude/*; do
    link_file "$f" ~/.claude/"$(basename "$f")"
done

mkdir -p ~/.codex
for f in "$base_dir"/codex/*; do
    [[ $(basename "$f") == config.toml ]] && continue
    link_file "$f" ~/.codex/"$(basename "$f")"
done
sudo mkdir -p /etc/codex
link_file "$base_dir/codex/config.toml" /etc/codex/config.toml true

mkdir -p ~/.config
xdg_configs=(nvim tmux git lsd wezterm ghostty yazi)
for name in "${xdg_configs[@]}"; do
    link_file "$base_dir/$name" ~/.config/"$name"
done
