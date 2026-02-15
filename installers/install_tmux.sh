#!/bin/sh
#
# Download, build, and install the latest tmux release on Linux.
#
# Usage:
#   install_tmux.sh
#   install_tmux.sh /custom/prefix
#
# Default prefix is ~/.local.
# Installs tmux under:
#   <prefix>/opt/tmux-<version>
# Updates stable symlinks:
#   <prefix>/opt/tmux
#   <prefix>/bin/tmux

set -eu

if [ "$(uname -s)" != "Linux" ]; then
  echo "error: this script only supports Linux" >&2
  exit 1
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: missing required command: $1" >&2
    exit 1
  fi
}

need_cmd curl
need_cmd tar
need_cmd mktemp
need_cmd make
need_cmd cc

prefix="${1:-$HOME/.local}"
opt_dir="$prefix/opt"
bin_dir="$prefix/bin"

tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/tmux/tmux/releases/latest" | sed -n 's#.*/tag/\([^/]*\)$#\1#p')"

if [ -z "$tag" ]; then
  echo "error: failed to determine latest tmux release tag" >&2
  exit 1
fi

version="$tag"
asset="tmux-${version}.tar.gz"
download_url="https://github.com/tmux/tmux/releases/download/${tag}/${asset}"
install_dir="$opt_dir/tmux-${version}"
current_link="$opt_dir/tmux"
target_bin="$bin_dir/tmux"

mkdir -p "$opt_dir" "$bin_dir"

current_version=""
if [ -x "$target_bin" ]; then
  current_version="$("$target_bin" -V 2>/dev/null | awk '{ print $2 }')"
fi

if [ "$current_version" = "$version" ] && [ -d "$install_dir" ]; then
  ln -sfn "$install_dir" "$current_link"
  ln -sfn "$current_link/bin/tmux" "$target_bin"
  echo "tmux ${version} is already installed. Nothing to do."
  exit 0
fi

if [ -d "$install_dir" ]; then
  ln -sfn "$install_dir" "$current_link"
  ln -sfn "$current_link/bin/tmux" "$target_bin"
  echo "tmux ${version} is already built. Symlinks updated."
  if [ -n "$current_version" ] && [ "$current_version" != "$version" ]; then
    echo "Upgraded tmux from ${current_version} to ${version}."
  fi
  exit 0
fi

if [ -n "$current_version" ]; then
  echo "Upgrading tmux from ${current_version} to ${version}..."
else
  echo "Installing tmux ${version}..."
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

echo "Downloading ${asset}..."
curl -fL "$download_url" -o "$tmp_dir/$asset"

tar -xzf "$tmp_dir/$asset" -C "$tmp_dir"

src_dir="$tmp_dir/tmux-${version}"
if [ ! -d "$src_dir" ]; then
  echo "error: extracted source directory tmux-${version} not found" >&2
  exit 1
fi

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"

(
  cd "$src_dir"
  ./configure --prefix="$install_dir"
  make -j"$jobs"
  make install
)

ln -sfn "$install_dir" "$current_link"
ln -sfn "$current_link/bin/tmux" "$target_bin"

echo "Installed tmux ${version} to ${install_dir}"
echo "Active tmux symlink: ${current_link}"
echo "Binary symlink: ${target_bin}"
