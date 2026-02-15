#!/bin/sh
#
# Download and install the latest zoxide release on Linux.
#
# Usage:
#   install_zoxide.sh
#   install_zoxide.sh /custom/install/dir
#
# Defaults to ~/.local/bin.

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
need_cmd install
need_cmd find

install_dir="${1:-$HOME/.local/bin}"
target_bin="$install_dir/zoxide"
arch="$(uname -m)"

case "$arch" in
  x86_64)
    target_triple="x86_64-unknown-linux-musl"
    ;;
  aarch64|arm64)
    target_triple="aarch64-unknown-linux-musl"
    ;;
  *)
    echo "error: unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/ajeetdsouza/zoxide/releases/latest" | sed -n 's#.*/tag/\([^/]*\)$#\1#p')"

if [ -z "$tag" ]; then
  echo "error: failed to determine latest zoxide release tag" >&2
  exit 1
fi

version="${tag#v}"
asset="zoxide-${version}-${target_triple}.tar.gz"
download_url="https://github.com/ajeetdsouza/zoxide/releases/download/${tag}/${asset}"

current_version=""
if [ -x "$target_bin" ]; then
  current_version="$("$target_bin" --version 2>/dev/null | awk 'NR==1 { print $2 }' | sed 's/^v//')"
fi

if [ "$current_version" = "$version" ]; then
  echo "zoxide ${version} is already installed. Nothing to do."
  exit 0
fi

if [ -n "$current_version" ]; then
  echo "Upgrading zoxide from ${current_version} to ${version}..."
else
  echo "Installing zoxide ${version}..."
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

echo "Downloading ${asset}..."
curl -fL "$download_url" -o "$tmp_dir/$asset"

tar -xzf "$tmp_dir/$asset" -C "$tmp_dir"

zoxide_bin="$(find "$tmp_dir" -type f -name zoxide | head -n 1)"
if [ -z "$zoxide_bin" ] || [ ! -f "$zoxide_bin" ]; then
  echo "error: zoxide binary not found in archive" >&2
  exit 1
fi

mkdir -p "$install_dir"
install -m 0755 "$zoxide_bin" "$target_bin"

echo "Installed zoxide ${version} to ${target_bin}"
