#!/bin/sh
# AURELION installer — downloads the prebuilt binary for your platform and
# installs it to ~/.local/bin (no sudo).
#
#   curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/install.sh | sh
#
# Env:
#   AURELION_VERSION=vX.Y.Z   pin a version (default: latest)
#   AURELION_INSTALL_DIR=DIR  install location (default: ~/.local/bin)
set -eu

REPO="zerodeity/aurelion-dist"
INSTALL_DIR="${AURELION_INSTALL_DIR:-$HOME/.local/bin}"
MARKER="# added by aurelion installer"

os_raw="${AURELION_OS:-$(uname -s)}"
arch_raw="${AURELION_ARCH:-$(uname -m)}"
case "$os_raw" in
  Darwin | darwin | macos) os=macos ;;
  Linux | linux) os=linux ;;
  *) echo "aurelion: unsupported OS '$os_raw'" >&2; exit 1 ;;
esac
case "$arch_raw" in
  arm64 | aarch64) arch=arm64 ;;
  x86_64 | amd64 | x64) arch=x64 ;;
  *) echo "aurelion: unsupported architecture '$arch_raw'" >&2; exit 1 ;;
esac
asset="aurelion-${os}-${arch}.tar.gz"

# Detection seam for tests: print the asset name and stop before any network.
if [ "${AURELION_DRYRUN:-}" = "1" ]; then
  echo "$asset"
  exit 0
fi

if [ -n "${AURELION_VERSION:-}" ]; then
  base="https://github.com/$REPO/releases/download/$AURELION_VERSION"
else
  base="https://github.com/$REPO/releases/latest/download"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "aurelion: downloading $asset ..."
curl -fsSL "$base/$asset" -o "$tmp/$asset"
curl -fsSL "$base/sha256sums.txt" -o "$tmp/sha256sums.txt"

want="$(awk -v a="$asset" '$2 == a { print $1 }' "$tmp/sha256sums.txt")"
if [ -z "$want" ]; then
  echo "aurelion: no checksum for $asset" >&2
  exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
  got="$(sha256sum "$tmp/$asset" | awk '{ print $1 }')"
else
  got="$(shasum -a 256 "$tmp/$asset" | awk '{ print $1 }')"
fi
if [ "$got" != "$want" ]; then
  echo "aurelion: checksum mismatch for $asset" >&2
  exit 1
fi

tar -xzf "$tmp/$asset" -C "$tmp"
mkdir -p "$INSTALL_DIR"
mv "$tmp/aurelion" "$INSTALL_DIR/aurelion"
chmod +x "$INSTALL_DIR/aurelion"

if [ "$os" = macos ]; then
  xattr -d com.apple.quarantine "$INSTALL_DIR/aurelion" 2>/dev/null || true
fi

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    for prof in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
      if [ -f "$prof" ]; then
        # $PATH is written literally into the profile, not expanded here.
        # shellcheck disable=SC2016
        printf '\n%s\nexport PATH="%s:$PATH"\n' "$MARKER" "$INSTALL_DIR" >> "$prof"
        echo "aurelion: added $INSTALL_DIR to PATH in $prof — restart your shell"
        break
      fi
    done
    ;;
esac

echo "aurelion: installed to $INSTALL_DIR/aurelion"
"$INSTALL_DIR/aurelion" --version || true
