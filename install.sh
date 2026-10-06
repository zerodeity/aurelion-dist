#!/bin/sh
# AURELION installer — downloads the prebuilt binary for your platform and
# installs it to ~/.local/bin (no sudo).
#
#   curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/install.sh | sh
#
# Env:
#   AURELION_VERSION=vX.Y.Z   pin a version/tag (default: latest, incl. betas)
#   AURELION_INSTALL_DIR=DIR  install location (default: ~/.local/bin)
#   NO_COLOR=1                plain output, no styling or animation
set -eu

REPO="zerodeity/aurelion-dist"
INSTALL_DIR="${AURELION_INSTALL_DIR:-$HOME/.local/bin}"
MARKER="# added by aurelion installer"

# ---- platform detection (overridable for tests) ----
os_raw="${AURELION_OS:-$(uname -s)}"
arch_raw="${AURELION_ARCH:-$(uname -m)}"
case "$os_raw" in Darwin | darwin | macos) os=macos ;; Linux | linux) os=linux ;; *) os="" ;; esac
case "$arch_raw" in arm64 | aarch64) arch=arm64 ;; x86_64 | amd64 | x64) arch=x64 ;; *) arch="" ;; esac

# Detection seam for tests: print the asset name and stop before anything else.
if [ "${AURELION_DRYRUN:-}" = "1" ]; then
  if [ -z "$os" ] || [ -z "$arch" ]; then
    echo "aurelion: unsupported platform $os_raw/$arch_raw" >&2
    exit 1
  fi
  echo "aurelion-${os}-${arch}.tar.gz"
  exit 0
fi

# ---- styling (auto-off when not a TTY or NO_COLOR is set) ----
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  G=$(printf '\033[38;5;46m')
  CY=$(printf '\033[38;5;51m')
  DIM=$(printf '\033[2m')
  BOLD=$(printf '\033[1m')
  RED=$(printf '\033[38;5;196m')
  RST=$(printf '\033[0m')
  TTY=1
else
  G=''; CY=''; DIM=''; BOLD=''; RED=''; RST=''; TTY=0
fi
OK="${G}✓${RST}"
BAD="${RED}✗${RST}"

banner() {
  printf '%s╔════════════════════════════════════════╗%s\n' "$CY" "$RST"
  printf '%s║%s      %sA U R E L I O N%s   ·   installer    %s║%s\n' "$CY" "$RST" "$BOLD$G" "$RST" "$CY" "$RST"
  printf '%s╚════════════════════════════════════════╝%s\n' "$CY" "$RST"
}

matrix() {
  [ "$TTY" = 1 ] || return 0
  cols=$(tput cols 2>/dev/null || echo 42)
  [ "$cols" -gt 42 ] 2>/dev/null && cols=42
  n=0
  while [ "$n" -lt 9 ]; do
    awk -v c="$cols" -v g="$G" -v r="$RST" 'BEGIN {
      srand();
      s = "01<>[]{}/|=+*#ABCDEF$%&";
      line = "";
      for (x = 0; x < c; x++)
        line = line (rand() < 0.5 ? substr(s, int(rand()*length(s))+1, 1) : " ");
      printf "%s%s%s\n", g, line, r;
    }'
    n=$((n + 1))
    sleep 0.04 2>/dev/null || true
  done
}

step() { printf '%s[%s/5]%s %s\n' "$CY" "$1" "$RST" "$2"; }

render_bar() { # cur total
  width=26
  case "$2" in '' | *[!0-9]*) total=0 ;; *) total=$2 ;; esac
  if [ "$total" -gt 0 ]; then
    pct=$((${1:-0} * 100 / total))
    [ "$pct" -gt 100 ] && pct=100
    fill=$((pct * width / 100))
  else
    pct=0
    fill=0
  fi
  bar=''
  i=0
  while [ "$i" -lt "$width" ]; do
    if [ "$i" -lt "$fill" ]; then bar="${bar}█"; else bar="${bar}░"; fi
    i=$((i + 1))
  done
  printf '\r      %s%s%s %3s%%' "$G" "$bar" "$RST" "$pct"
}

download() { # url dest
  if [ "$TTY" != 1 ]; then
    curl -fsSL "$1" -o "$2"
    return
  fi
  total=$(curl -fsSLI "$1" 2>/dev/null | awk 'tolower($1) == "content-length:" { v = $2 } END { gsub(/\r/, "", v); print v }')
  curl -fsSL "$1" -o "$2" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    render_bar "$(wc -c <"$2" 2>/dev/null || echo 0)" "$total"
    sleep 0.1 2>/dev/null || true
  done
  wait "$pid" || return 1
  render_bar "${total:-0}" "${total:-0}"
  printf '\n'
}

# ---- run ----
banner
matrix

printf '\n%s%srequirements%s\n' "$BOLD" "$G" "$RST"
missing=0
check() { # label  test-exit
  if [ "$2" = 0 ]; then printf '  [%s] %s\n' "$OK" "$1"; else printf '  [%s] %s\n' "$BAD" "$1"; missing=1; fi
}
command -v curl >/dev/null 2>&1
check "curl" $?
command -v tar >/dev/null 2>&1
check "tar" $?
if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then check "sha256 tool" 0; else check "sha256 tool" 1; fi
if [ -n "$os" ] && [ -n "$arch" ]; then
  printf '  [%s] platform: %s%s-%s%s\n' "$OK" "$CY" "$os" "$arch" "$RST"
else
  printf '  [%s] platform: %s/%s (unsupported)\n' "$BAD" "$os_raw" "$arch_raw"
  missing=1
fi
if [ "$missing" = 1 ]; then
  printf '\n%saurelion: missing requirements above — install them and retry.%s\n' "$RED" "$RST" >&2
  exit 1
fi
asset="aurelion-${os}-${arch}.tar.gz"

printf '\n'
step 1 "platform ${CY}${os}-${arch}${RST} ${OK}"

step 2 "resolving latest release"
if [ -n "${AURELION_VERSION:-}" ]; then
  tag="$AURELION_VERSION"
else
  tag=$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=1" |
    grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[^"]*"([^"]+)".*/\1/')
fi
if [ -z "$tag" ]; then
  printf '%saurelion: no release found for %s%s\n' "$RED" "$REPO" "$RST" >&2
  exit 1
fi
printf '      %s%s%s\n' "$DIM" "$tag" "$RST"
base="https://github.com/$REPO/releases/download/$tag"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

step 3 "downloading ${DIM}${asset}${RST}"
download "$base/$asset" "$tmp/$asset"
curl -fsSL "$base/sha256sums.txt" -o "$tmp/sha256sums.txt"

step 4 "verifying checksum"
want="$(awk -v a="$asset" '$2 == a { print $1 }' "$tmp/sha256sums.txt")"
if [ -z "$want" ]; then
  printf '%saurelion: no checksum for %s%s\n' "$RED" "$asset" "$RST" >&2
  exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
  got="$(sha256sum "$tmp/$asset" | awk '{ print $1 }')"
else
  got="$(shasum -a 256 "$tmp/$asset" | awk '{ print $1 }')"
fi
if [ "$got" != "$want" ]; then
  printf '%saurelion: checksum mismatch for %s%s\n' "$RED" "$asset" "$RST" >&2
  exit 1
fi
printf '      %s sha256 verified\n' "$OK"

step 5 "installing to ${CY}${INSTALL_DIR}${RST}"
tar -xzf "$tmp/$asset" -C "$tmp"
mkdir -p "$INSTALL_DIR"
mv "$tmp/aurelion" "$INSTALL_DIR/aurelion"
chmod +x "$INSTALL_DIR/aurelion"
if [ "$os" = macos ]; then
  xattr -d com.apple.quarantine "$INSTALL_DIR/aurelion" 2>/dev/null || true
fi

pathnote=""
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    for prof in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
      if [ -f "$prof" ]; then
        # $PATH is written literally into the profile, not expanded here.
        # shellcheck disable=SC2016
        printf '\n%s\nexport PATH="%s:$PATH"\n' "$MARKER" "$INSTALL_DIR" >>"$prof"
        pathnote="added ${INSTALL_DIR} to PATH in ${prof} — restart your shell"
        break
      fi
    done
    ;;
esac

printf '\n%s%s  AURELION %s installed%s\n' "$BOLD" "$G" "$tag" "$RST"
printf '%s  → %s/aurelion%s\n' "$DIM" "$INSTALL_DIR" "$RST"
[ -n "$pathnote" ] && printf '%s  %s%s\n' "$DIM" "$pathnote" "$RST"
printf '%s  run %saurelion%s%s to start · %saurelion update%s to upgrade\n' "$DIM" "$G" "$RST" "$DIM" "$G" "$RST"
