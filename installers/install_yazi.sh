#!/bin/sh
#
# Download and install the latest yazi release on Linux.
#
# Usage:
#   install_yazi.sh
#   install_yazi.sh /custom/install/dir
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
need_cmd unzip
need_cmd mktemp
need_cmd install

install_dir="${1:-$HOME/.local/bin}"
yazi_target="$install_dir/yazi"
ya_target="$install_dir/ya"
arch="$(uname -m)"

case "$arch" in
  x86_64)
    musl_triple="x86_64-unknown-linux-musl"
    gnu_triple="x86_64-unknown-linux-gnu"
    ;;
  aarch64|arm64)
    musl_triple="aarch64-unknown-linux-musl"
    gnu_triple="aarch64-unknown-linux-gnu"
    ;;
  *)
    echo "error: unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/sxyazi/yazi/releases/latest" | sed -n 's#.*/tag/\([^/]*\)$#\1#p')"

if [ -z "$tag" ]; then
  echo "error: failed to determine latest yazi release tag" >&2
  exit 1
fi

version="${tag#v}"
musl_asset="yazi-${musl_triple}.zip"
musl_download_url="https://github.com/sxyazi/yazi/releases/download/${tag}/${musl_asset}"
gnu_asset="yazi-${gnu_triple}.zip"
gnu_download_url="https://github.com/sxyazi/yazi/releases/download/${tag}/${gnu_asset}"

current_version=""
if [ -x "$yazi_target" ]; then
  current_version="$("$yazi_target" --version 2>/dev/null | awk 'NR==1 { print $2 }' | sed 's/^v//')"
fi

if [ "$current_version" = "$version" ]; then
  echo "yazi ${version} is already installed. Nothing to do."
  exit 0
fi

if [ -n "$current_version" ]; then
  echo "Upgrading yazi from ${current_version} to ${version}..."
else
  echo "Installing yazi ${version}..."
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

asset="$musl_asset"
download_url="$musl_download_url"
target_triple="$musl_triple"

echo "Downloading ${asset}..."
if ! curl -fL "$download_url" -o "$tmp_dir/$asset"; then
  asset="$gnu_asset"
  download_url="$gnu_download_url"
  target_triple="$gnu_triple"
  echo "MUSL build unavailable for ${tag}, falling back to ${asset}..."
  curl -fL "$download_url" -o "$tmp_dir/$asset"
fi

unzip -q "$tmp_dir/$asset" -d "$tmp_dir"

yazi_bin="$tmp_dir/yazi-${target_triple}/yazi"
ya_bin="$tmp_dir/yazi-${target_triple}/ya"

if [ ! -f "$yazi_bin" ] || [ ! -f "$ya_bin" ]; then
  echo "error: yazi binaries not found in archive" >&2
  exit 1
fi

mkdir -p "$install_dir"
install -m 0755 "$yazi_bin" "$yazi_target"
install -m 0755 "$ya_bin" "$ya_target"

echo "Installed yazi ${version} to ${install_dir} (yazi, ya)"
