#!/bin/sh
#
# Download and install the latest fzf release on Linux.
#
# Usage:
#   install_fzf.sh
#   install_fzf.sh /custom/install/dir
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

install_dir="${1:-$HOME/.local/bin}"
arch="$(uname -m)"

case "$arch" in
  x86_64)
    fzf_arch="amd64"
    ;;
  aarch64|arm64)
    fzf_arch="arm64"
    ;;
  armv7l)
    fzf_arch="armv7"
    ;;
  armv6l)
    fzf_arch="armv6"
    ;;
  i386|i686)
    fzf_arch="386"
    ;;
  *)
    echo "error: unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/junegunn/fzf/releases/latest" | sed -n 's#.*/tag/\([^/]*\)$#\1#p')"

if [ -z "$tag" ]; then
  echo "error: failed to determine latest fzf release tag" >&2
  exit 1
fi

version="${tag#v}"
asset="fzf-${version}-linux_${fzf_arch}.tar.gz"
download_url="https://github.com/junegunn/fzf/releases/download/${tag}/${asset}"
target_bin="$install_dir/fzf"

current_version=""
if [ -x "$target_bin" ]; then
  current_version="$("$target_bin" --version 2>/dev/null | awk 'NR==1 { print $1 }')"
fi

if [ "$current_version" = "$version" ]; then
  echo "fzf ${version} is already installed. Nothing to do."
  exit 0
fi

if [ -n "$current_version" ]; then
  echo "Upgrading fzf from ${current_version} to ${version}..."
else
  echo "Installing fzf ${version}..."
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

echo "Downloading ${asset}..."
curl -fL "$download_url" -o "$tmp_dir/$asset"

tar -xzf "$tmp_dir/$asset" -C "$tmp_dir"

if [ ! -f "$tmp_dir/fzf" ]; then
  echo "error: fzf binary not found in archive" >&2
  exit 1
fi

mkdir -p "$install_dir"
install -m 0755 "$tmp_dir/fzf" "$target_bin"

echo "Installed fzf ${version} to ${target_bin}"
