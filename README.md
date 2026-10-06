# AURELION

A lightning-fast AI coding agent for your terminal.

## Install

macOS and Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/install.sh | sh
```

The `aurelion` binary installs to `~/.local/bin` (no `sudo`). Supported platforms:

| OS    | Architectures                       |
| ----- | ----------------------------------- |
| macOS | Apple Silicon (arm64), Intel (x64)  |
| Linux | x64, arm64                          |

## Update

```sh
aurelion update          # install the latest version
aurelion update --check  # check whether a newer version is available
```

## Uninstall

```sh
aurelion uninstall         # remove the binary
aurelion uninstall --deep  # also remove config, data, and caches
```

## Verifying downloads

Every release ships a `sha256sums.txt`. The installer verifies each download
against it before installing, and so does `aurelion update`.

---

AURELION — created with ❤ by ZERO PRIME.
