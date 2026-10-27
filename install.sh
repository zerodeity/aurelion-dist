#!/bin/sh
# AURELION installer — downloads the prebuilt binary for your platform and
# installs it to ~/.local/bin (no sudo).
#
#   curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/install.sh | sh
#
# Env:
#   AURELION_VERSION=vX.Y.Z    pin a version/tag (default: latest, incl. betas)
#   AURELION_INSTALL_DIR=DIR   install location (default: ~/.local/bin)
#   AURELION_REQUIRE_SIGNATURE=1  refuse to install without minisign to check
#                              the release signature
#   NO_COLOR=1                 plain output, no styling
#
# Everything runs from `main`, called on the last line: a `curl | sh` pipe
# cut short ends inside a definition, so a partial script runs nothing.
set -eu

info() { printf '  %s\n' "$1"; }
die() {
  printf '\n%serror:%s %s\n' "$RED" "$RST" "$1" >&2
  exit 1
}

download() { # url dest — curl's own progress bar on a TTY, silent otherwise
  if [ "$TTY" = 1 ]; then
    curl -fSL --progress-bar "$1" -o "$2"
  else
    curl -fsSL "$1" -o "$2"
  fi
}

# The shell profile that puts INSTALL_DIR on PATH: one that already holds
# the installer's block (a re-run adds no second one), else the first that
# exists, else a new one for the user's shell (a fresh macOS account has
# no profile at all). Prints the profile, and "already" when it has the
# block.
path_profile() {
  line="export PATH=\"$INSTALL_DIR:\$PATH\""
  for prof in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$prof" ] && grep -qF "$MARKER" "$prof" && grep -qF "$line" "$prof"; then
      printf '%s already\n' "$prof"
      return
    fi
  done
  for prof in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
    if [ -f "$prof" ]; then
      printf '%s\n' "$prof"
      return
    fi
  done
  case "${SHELL:-}" in
    */zsh) printf '%s\n' "$HOME/.zshrc" ;;
    # macOS Terminal starts bash as a login shell, which reads
    # .bash_profile and not .bashrc.
    */bash) if [ "$os" = macos ]; then printf '%s\n' "$HOME/.bash_profile"; else printf '%s\n' "$HOME/.bashrc"; fi ;;
    *) printf '%s\n' "$HOME/.profile" ;;
  esac
}

main() {
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
    BOLD=$(printf '\033[1m')
    DIM=$(printf '\033[2m')
    GREEN=$(printf '\033[32m')
    RED=$(printf '\033[31m')
    RST=$(printf '\033[0m')
    TTY=1
  else
    BOLD=''
    DIM=''
    GREEN=''
    RED=''
    RST=''
    TTY=0
  fi
  OK="${GREEN}✓${RST}"

  # ---- header ----
  printf '\n  %sAURELION%s  %sinstaller%s\n\n' "$BOLD" "$RST" "$DIM" "$RST"

  # ---- requirements ----
  command -v curl >/dev/null 2>&1 || die "curl is required."
  command -v tar >/dev/null 2>&1 || die "tar is required."
  if command -v sha256sum >/dev/null 2>&1; then
    sha_kind=sum
  elif command -v shasum >/dev/null 2>&1; then
    sha_kind=shasum
  else
    die "a sha256 tool (sha256sum or shasum) is required."
  fi
  if [ -z "$os" ] || [ -z "$arch" ]; then
    die "unsupported platform: $os_raw/$arch_raw"
  fi
  asset="aurelion-${os}-${arch}.tar.gz"
  info "${OK} platform   ${BOLD}${os}-${arch}${RST}"

  # ---- resolve release ----
  if [ -n "${AURELION_VERSION:-}" ]; then
    tag="$AURELION_VERSION"
  else
    tag=$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=1" |
      grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[^"]*"([^"]+)".*/\1/')
  fi
  [ -n "$tag" ] || die "no release found for $REPO."
  info "${OK} release    ${BOLD}${tag}${RST}"

  base="https://github.com/$REPO/releases/download/$tag"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  # ---- download ----
  printf '\n%s  downloading %s%s\n' "$DIM" "$asset" "$RST"
  download "$base/$asset" "$tmp/$asset" || die "download failed."
  curl -fsSL "$base/sha256sums.txt" -o "$tmp/sha256sums.txt" || die "could not fetch checksums."

  # ---- signature ----
  # A release's sha256sums.txt is minisign-signed with AURELION's release key,
  # the key `aurelion update` pins (crates/aurelion/src/update/signature.rs),
  # and the signature's trusted comment names the release tag. With minisign
  # installed both are checked; without it only the checksum below is.
  PUBKEY="RWTYDrAGVq6o7mUSXgXddDuctD0V0t/mDm6EqcH8OStUBPTFkvsRzAeu"
  if command -v minisign >/dev/null 2>&1; then
    curl -fsSL "$base/sha256sums.txt.minisig" -o "$tmp/sha256sums.txt.minisig" ||
      die "could not fetch the checksums' signature."
    sig_out=$(minisign -V -P "$PUBKEY" -m "$tmp/sha256sums.txt" -x "$tmp/sha256sums.txt.minisig" 2>&1) ||
      die "the checksums are not signed with AURELION's release key."
    signed_tag=$(printf '%s\n' "$sig_out" | sed -n 's/^Trusted comment: //p' | awk '{ print $NF }')
    [ "$signed_tag" = "tag:$tag" ] || die "the signed checksums belong to another release (${signed_tag:-none}), not $tag."
    info "${OK} signature  verified"
  elif [ "${AURELION_REQUIRE_SIGNATURE:-}" = 1 ]; then
    die "AURELION_REQUIRE_SIGNATURE=1, but minisign is not installed."
  else
    info "${DIM}- signature  not checked (install minisign to check it)${RST}"
  fi

  # ---- verify ----
  want=$(awk -v a="$asset" '$2 == a { print $1 }' "$tmp/sha256sums.txt")
  [ -n "$want" ] || die "no checksum published for $asset."
  if [ "$sha_kind" = sum ]; then
    got=$(sha256sum "$tmp/$asset" | awk '{ print $1 }')
  else
    got=$(shasum -a 256 "$tmp/$asset" | awk '{ print $1 }')
  fi
  [ "$got" = "$want" ] || die "checksum mismatch for $asset."
  info "${OK} checksum   verified"

  # ---- install ----
  tar -xzf "$tmp/$asset" -C "$tmp" || die "could not extract $asset."
  mkdir -p "$INSTALL_DIR"
  mv "$tmp/aurelion" "$INSTALL_DIR/aurelion"
  chmod +x "$INSTALL_DIR/aurelion"
  if [ "$os" = macos ]; then
    xattr -d com.apple.quarantine "$INSTALL_DIR/aurelion" 2>/dev/null || true
  fi
  info "${OK} installed   ${BOLD}${INSTALL_DIR}/aurelion${RST}"

  # ---- PATH ----
  pathprof=""
  pathnote=""
  case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
      pathnote="off"
      found="$(path_profile)"
      case "$found" in
        *" already")
          pathprof="${found% already}"
          pathnote="already"
          ;;
        *)
          # $PATH is written literally into the profile, not expanded here.
          # shellcheck disable=SC2016
          if printf '\n%s\nexport PATH="%s:$PATH"\n' "$MARKER" "$INSTALL_DIR" >>"$found" 2>/dev/null; then
            pathprof="$found"
            pathnote="added"
          fi
          ;;
      esac
      ;;
  esac

  # ---- done ----
  printf '\n  %s%sAURELION %s installed.%s\n\n' "$BOLD" "$GREEN" "$tag" "$RST"
  case "$pathnote" in
    added) printf '  %sAdded %s to your PATH in %s.%s\n' "$DIM" "$INSTALL_DIR" "$pathprof" "$RST" ;;
    already) printf '  %s%s is on your PATH in %s.%s\n' "$DIM" "$INSTALL_DIR" "$pathprof" "$RST" ;;
    off) printf '  %s%s is not on your PATH.%s\n' "$DIM" "$INSTALL_DIR" "$RST" ;;
  esac
  if [ -n "$pathnote" ]; then
    # shellcheck disable=SC2016 # $PATH is printed literally, for the user to copy.
    printf '  %sRestart your shell, or run:%s export PATH="%s:$PATH"\n\n' "$DIM" "$RST" "$INSTALL_DIR"
  fi
  printf '  %sActivate%s   aurelion activate <key>\n' "$BOLD" "$RST"
  printf '  %sRun%s        aurelion\n' "$BOLD" "$RST"
  printf '  %sUpgrade%s    aurelion update\n\n' "$BOLD" "$RST"
}

main "$@"
