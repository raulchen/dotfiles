#!/bin/sh
#
# Download and install the latest Neovim release on Linux.
#
# Usage:
#   install_neovim.sh
#   install_neovim.sh /custom/prefix
#
# Default prefix is ~/.local.
# Installs Neovim under:
#   <prefix>/opt/neovim-<version>
# Updates stable symlinks:
#   <prefix>/opt/neovim
#   <prefix>/bin/nvim

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

prefix="${1:-$HOME/.local}"
arch="$(uname -m)"

case "$arch" in
  x86_64)
    asset="nvim-linux-x86_64.tar.gz"
    extracted_dir="nvim-linux-x86_64"
    ;;
  aarch64|arm64)
    asset="nvim-linux-arm64.tar.gz"
    extracted_dir="nvim-linux-arm64"
    ;;
  *)
    echo "error: unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/neovim/neovim/releases/latest" | sed -n 's#.*/tag/\([^/]*\)$#\1#p')"

if [ -z "$tag" ]; then
  echo "error: failed to determine latest Neovim release tag" >&2
  exit 1
fi

version="${tag#v}"
download_url="https://github.com/neovim/neovim/releases/latest/download/${asset}"
opt_dir="$prefix/opt"
bin_dir="$prefix/bin"
install_dir="$opt_dir/neovim-$version"
current_link="$opt_dir/neovim"

current_version=""
if [ -x "$bin_dir/nvim" ]; then
  current_version="$("$bin_dir/nvim" --version 2>/dev/null | sed -n '1s/^NVIM v//p')"
fi

print_stale_versions() {
  stale_versions="$(find "$opt_dir" -maxdepth 1 -mindepth 1 -type d -name 'neovim-*' ! -name "neovim-${version}" -exec basename {} \; | sed 's/^neovim-//' | sort | tr '\n' ' ' | sed 's/[[:space:]]$//')"
  if [ -n "$stale_versions" ]; then
    echo "Stale Neovim versions: $stale_versions"
  fi
}

mkdir -p "$opt_dir" "$bin_dir"

if [ "$current_version" = "$version" ] && [ -d "$install_dir" ]; then
  ln -sfn "$install_dir" "$current_link"
  ln -sfn "$current_link/bin/nvim" "$bin_dir/nvim"
  echo "Neovim ${version} is already installed. Nothing to do."
  print_stale_versions
  exit 0
fi

if [ -d "$install_dir" ]; then
  ln -sfn "$install_dir" "$current_link"
  ln -sfn "$current_link/bin/nvim" "$bin_dir/nvim"
  echo "Neovim ${version} is already downloaded. Symlinks updated."
  if [ -n "$current_version" ] && [ "$current_version" != "$version" ]; then
    echo "Upgraded Neovim from ${current_version} to ${version}."
  fi
  print_stale_versions
  exit 0
fi

if [ -n "$current_version" ] && [ "$current_version" != "$version" ]; then
  echo "Upgrading Neovim from ${current_version} to ${version}..."
else
  echo "Installing Neovim ${version}..."
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

echo "Downloading ${asset} (${tag})..."
curl -fL "$download_url" -o "$tmp_dir/$asset"

tar -xzf "$tmp_dir/$asset" -C "$tmp_dir"

if [ ! -d "$tmp_dir/$extracted_dir" ]; then
  echo "error: extracted directory ${extracted_dir} not found" >&2
  exit 1
fi

mv "$tmp_dir/$extracted_dir" "$install_dir"

ln -sfn "$install_dir" "$current_link"
ln -sfn "$current_link/bin/nvim" "$bin_dir/nvim"

echo "Installed Neovim ${version} to ${install_dir}"
echo "Active Neovim symlink: ${current_link}"
echo "Binary symlink: ${bin_dir}/nvim"
print_stale_versions
