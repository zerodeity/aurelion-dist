#!/bin/sh
# AURELION uninstaller. Removes the binary and the installer's PATH line.
#   --purge   also removes config, data, caches, and the trust record.
#
# (The in-binary `aurelion uninstall --deep` does the same global clean when
# the binary still runs; this script is the fallback when it does not.)
set -eu

INSTALL_DIR="${AURELION_INSTALL_DIR:-$HOME/.local/bin}"
MARKER="# added by aurelion installer"

purge=0
for a in "$@"; do
  [ "$a" = "--purge" ] && purge=1
done

if [ -f "$INSTALL_DIR/aurelion" ]; then
  rm -f "$INSTALL_DIR/aurelion"
  echo "removed $INSTALL_DIR/aurelion"
fi

# Drop the installer's two-line PATH block (the marker and the line after it).
for prof in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
  [ -f "$prof" ] || continue
  if grep -qF "$MARKER" "$prof" 2>/dev/null; then
    tmp="$(mktemp)"
    awk -v m="$MARKER" '
      index($0, m) { skip = 1; next }
      skip         { skip = 0; next }
      { print }
    ' "$prof" > "$tmp"
    mv "$tmp" "$prof"
    echo "removed PATH line from $prof"
  fi
done

if [ "$purge" = 1 ]; then
  case "$(uname -s)" in
    Darwin) data="$HOME/Library/Application Support/aurelion"; cache="$HOME/Library/Caches" ;;
    *) data="${XDG_DATA_HOME:-$HOME/.local/share}/aurelion"; cache="${XDG_CACHE_HOME:-$HOME/.cache}" ;;
  esac
  rm -rf "$HOME/.config/aurelion" "$data" "$cache/aurelion-forge" "$cache/aurelion-mutants"
  echo "purged config, data, and caches"
fi
