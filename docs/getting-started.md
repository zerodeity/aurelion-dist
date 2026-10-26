# Getting started

AURELION is an AI coding agent that lives in your terminal. You tell it what you want in plain words. It reads your code, runs commands, edits files and checks its own work, and you watch every step and approve what matters. This page takes you from install to your first finished turn.

## Install

AURELION runs on macOS (Apple silicon and Intel) and Linux (x64 and arm64). Windows is not supported.

```sh
curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/install.sh | sh
```

The installer:

- picks the build for your platform and the latest release (betas included);
- checks the download against the release's SHA-256 checksums, and checks their signature too when `minisign` is installed;
- puts `aurelion` in `~/.local/bin`, with no `sudo`;
- adds that folder to your `PATH` in `~/.zshrc`, `~/.bashrc` or `~/.profile` when it is missing. Restart your shell afterwards.

It needs `curl`, `tar`, and `sha256sum` or `shasum`.

Environment variables change what it does:

| Variable | What it does |
| --- | --- |
| `AURELION_VERSION=v0.10.1-beta` | Install that release instead of the latest. |
| `AURELION_INSTALL_DIR=~/bin` | Install there instead of `~/.local/bin`. |
| `AURELION_REQUIRE_SIGNATURE=1` | Refuse to install unless `minisign` can check the signature. |

```sh
curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/install.sh | AURELION_REQUIRE_SIGNATURE=1 sh
```

## Activate

Official release builds need a license key. Activate each machine once, with the key you were given:

```sh
aurelion activate <key>
```

Until you do, AURELION prints `AURELION is locked` and exits with code 3. `aurelion doctor` shows the license state, among its other checks.

## Your first run

Go to a project and start AURELION:

```sh
cd ~/code/my-project
aurelion
```

With no config yet, the setup wizard opens. It has five short steps:

1. **Provider.** Pick one of 84 model providers. Type to filter. A `✓` means its key is already in your environment.
2. **Key.** Paste the API key, or press `Enter` to use the one in your environment. That key stays in your environment, not in the config. For any other endpoint, type `https://host/v1 <key>`. A local server needs no key.
3. **Verify.** AURELION checks the key with a cheap request and lists the models. Type to search, `↑` `↓` to pick, `Enter` to go on. If the check fails, nothing is saved.
4. **Trust.** `y` trusts this folder, `n` starts without trusting it. [Modes and safety](modes-and-safety.md) explains what trust turns on.
5. **Summary.** `Space` or `←` changes the theme. `Enter` saves `~/.config/aurelion/config.toml` and starts.

The key goes to your system's credential store when there is one (the macOS Keychain, or the Secret Service on Linux). Otherwise it goes to `~/.config/aurelion/config.key`, which only you can read.

Run the wizard again any time with `aurelion setup`, or `/setup` inside the app.

## Connect a model

The wizard covers API keys and local servers. Subscriptions sign in from the command line instead.

### A Claude Pro or Max plan

Claude Pro and Max plans run only through the official Claude Code CLI. Install [Claude Code](https://claude.com/claude-code), run `claude` once and log in, then connect:

```sh
aurelion connect claude
```

This makes `claude-subscription` your provider. Claude is the model; AURELION runs the tools, the approvals and the sandbox. Usage counts against your Claude plan. To hand whole turns to Claude Code instead, pick `claude-cli` in `/provider`. [Models and providers](models.md) explains the difference.

### Other sign-ins

```sh
aurelion connect codex        # your ChatGPT plan, with a device code
aurelion connect copilot      # your GitHub Copilot plan, with a device code
aurelion connect openrouter   # OpenRouter, in the browser
```

### An API key

Export the provider's own variable before you start, and the wizard finds it:

```sh
export ANTHROPIC_API_KEY=sk-ant-…
aurelion
```

`aurelion providers` lists every provider, the variable each one reads, and which keys you have set.

### A local model

Ollama, LM Studio, vLLM, llama.cpp and SGLang need no key:

```toml
# ~/.config/aurelion/config.toml
provider = "ollama"
model = "qwen3-coder"
```

`aurelion models` lists the models your provider offers.

## Start working

```sh
aurelion                           # open the cockpit in this folder
aurelion "add a --verbose flag"    # open it and send a first prompt
aurelion -c                        # continue the most recent session
aurelion --resume 3f2a             # resume a session by its id prefix
aurelion -p "explain this repo"    # print one answer, then exit
```

Type a task and press `Enter`. The agent works in turns. In each turn it thinks, calls tools and answers. You see every tool call as a row in the stream: what ran, why, and what came back.

A session starts in **AUTO** mode, with approvals on. Most reads and edits run on their own. A shell command that could change something waits for your answer on an approval card: `y` allows it once, `A` always, `n` denies. `Shift+Tab` switches modes. [Modes and safety](modes-and-safety.md) has the details.

Every turn that edits files starts with a snapshot. If you don't like a turn, press `Esc` on the empty prompt, then `u`: the files go back and the conversation stays. [Undo and review](undo-and-review.md) shows how.

![A finished turn in the cockpit: the prompt, the snapshot row, an Edit and a Bash tool row, and a passing check](../assets/svg/captures/turn.svg)

*A finished turn on a small Go project, in ASK mode. The `⟲ snapshot` row is the turn's undo point. Each tool row carries one line of why. The `· verify:` lines are the checks AURELION runs after an edit: the tests passed, and mutation testing had nothing to do, since it covers Rust files only. `verify V3: SOUND` means a reviewer model read the change against the request and found no flaw. At the end, the project's own check (`go test ./...`) passed, so the run chip reads `✓ VERIFIED`.*

Press `?` on an empty prompt to see the keys, and `/` or `Ctrl+K` to browse every command. To leave, press `Ctrl+D` on an empty prompt. AURELION prints a summary: the session's id, turns, cost and changed files, and the command that resumes it.

## Where things live

- `~/.config/aurelion/config.toml`: your global config.
- `.aurelion/config.toml` in a project: that project's config. It outranks the global one. In a folder you haven't trusted, AURELION keeps only its harmless settings, such as the theme and model names, and warns about the rest.
- `aurelion config` prints every path and the settings in effect. `aurelion config set <key> <value>` changes one.

## Update

```sh
aurelion update           # install the latest release now
aurelion update --check   # only say whether there is one
```

A bare `aurelion` launch also looks for a new release once a day. The check takes a few seconds at most and never holds up startup. `[update] mode` in your global config decides what happens next:

```toml
[update]
mode = "notify"   # the default: show the new version on the welcome screen
# mode = "auto"   # also download, check and install it, then restart into it
# mode = "off"    # no startup check at all
```

Only the global config can set the mode; a project's config can't. `AURELION_NO_UPDATE=1` turns the startup check off whatever the config says, for CI, pinned installs and offline machines. An update checks the release's signature before it trusts any checksum, and refuses a release that is not signed with AURELION's release key.

## Check a download by hand

Each release has a `sha256sums.txt` and its signature, `sha256sums.txt.minisig`. Download both from the same release as your tarball, then check the signature and the checksum:

```sh
minisign -V -m sha256sums.txt -P RWTYDrAGVq6o7mUSXgXddDuctD0V0t/mDm6EqcH8OStUBPTFkvsRzAeu
shasum -a 256 -c sha256sums.txt --ignore-missing   # Linux: sha256sum -c sha256sums.txt --ignore-missing
```

minisign prints a trusted comment such as `tag:v0.10.1-beta`. Check that it names the release you downloaded. [Security and releases](security-and-releases.md) has more on how releases are signed.

## Uninstall

```sh
aurelion uninstall          # remove the binary; it asks first (--yes skips the question)
aurelion uninstall --deep   # also remove the config, data, caches and the trust record
```

Your projects' `.aurelion/` folders stay. If the binary no longer runs, the uninstall script does the same job:

```sh
curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/uninstall.sh | sh
curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/uninstall.sh | sh -s -- --purge   # also the config and data
```

**Next:** [The cockpit](cockpit.md)
