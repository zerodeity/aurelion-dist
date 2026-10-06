# AURELION — prebuilt binaries

Public distribution for [AURELION](https://github.com/zerodeity/AURELION) (source is private).
Each release holds one tarball per target plus `sha256sums.txt`.

## Install (macOS + Linux)

```sh
curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/install.sh | sh
```

Targets: `macos-arm64`, `macos-x64`, `linux-x64`, `linux-arm64`.

## Update / uninstall (once installed)

```sh
aurelion update            # self-update to the latest release (--check to just look)
aurelion uninstall --deep  # remove the binary + all config/data/caches
```
