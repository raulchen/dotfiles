#!/bin/sh
#
# Download and install the latest LTS Node.js release on Linux.
#
# Usage:
#   install_node.sh
#   install_node.sh /custom/prefix
#
# Default prefix is ~/.local.
# Installs Node.js under:
#   <prefix>/opt/node-<version>
# Updates stable symlinks:
#   <prefix>/opt/node
#   <prefix>/bin/node
#   <prefix>/bin/npm
#   <prefix>/bin/npx

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
need_cmd awk

prefix="${1:-$HOME/.local}"
arch="$(uname -m)"

case "$arch" in
  x86_64)
    node_arch="x64"
    ;;
  aarch64|arm64)
    node_arch="arm64"
    ;;
  *)
    echo "error: unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

# index.tab lists releases newest first; column 10 is the LTS codename ("-" if not LTS).
tag="$(curl -fsSL "https://nodejs.org/dist/index.tab" | awk 'NR > 1 && $10 != "-" && !found { print $1; found = 1 }')"

if [ -z "$tag" ]; then
  echo "error: failed to determine latest Node.js LTS release" >&2
  exit 1
fi

version="${tag#v}"
asset="node-${tag}-linux-${node_arch}.tar.gz"
extracted_dir="node-${tag}-linux-${node_arch}"
download_url="https://nodejs.org/dist/${tag}/${asset}"
opt_dir="$prefix/opt"
bin_dir="$prefix/bin"
install_dir="$opt_dir/node-$version"
current_link="$opt_dir/node"

update_symlinks() {
  ln -sfn "$install_dir" "$current_link"
  for bin in node npm npx; do
    ln -sfn "$current_link/bin/$bin" "$bin_dir/$bin"
  done
}

# Point npm's global prefix at <prefix> so `npm install -g` binaries land in
# <prefix>/bin (on PATH) instead of the versioned install directory, where
# they would be lost on upgrade.
configure_npm_prefix() {
  "$bin_dir/npm" config set prefix "$prefix"
}

current_version=""
if [ -x "$bin_dir/node" ]; then
  current_version="$("$bin_dir/node" --version 2>/dev/null | sed 's/^v//')"
fi

print_stale_versions() {
  stale_versions="$(find "$opt_dir" -maxdepth 1 -mindepth 1 -type d -name 'node-*' ! -name "node-${version}" -exec basename {} \; | sed 's/^node-//' | sort | tr '\n' ' ' | sed 's/[[:space:]]$//')"
  if [ -n "$stale_versions" ]; then
    echo "Stale Node.js versions: $stale_versions"
  fi
}

mkdir -p "$opt_dir" "$bin_dir"

if [ "$current_version" = "$version" ] && [ -d "$install_dir" ]; then
  update_symlinks
  configure_npm_prefix
  echo "Node.js ${version} is already installed. Nothing to do."
  print_stale_versions
  exit 0
fi

if [ -d "$install_dir" ]; then
  update_symlinks
  configure_npm_prefix
  echo "Node.js ${version} is already downloaded. Symlinks updated."
  if [ -n "$current_version" ] && [ "$current_version" != "$version" ]; then
    echo "Upgraded Node.js from ${current_version} to ${version}."
  fi
  print_stale_versions
  exit 0
fi

if [ -n "$current_version" ] && [ "$current_version" != "$version" ]; then
  echo "Upgrading Node.js from ${current_version} to ${version}..."
else
  echo "Installing Node.js ${version}..."
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

update_symlinks
configure_npm_prefix

echo "Installed Node.js ${version} to ${install_dir}"
echo "Active Node.js symlink: ${current_link}"
echo "Binary symlinks: ${bin_dir}/node, ${bin_dir}/npm, ${bin_dir}/npx"
echo "npm global prefix: ${prefix}"
print_stale_versions
