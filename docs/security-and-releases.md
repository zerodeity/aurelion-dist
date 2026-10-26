# Security and releases

You run AURELION on your own machine, with your code and your keys, so you should know what you install and what leaves the machine. This page explains how releases are signed and checked, how updates work, where your keys are kept, what AURELION sends where, and how to check your own setup.

## Signed releases

Every release has four builds: macOS on Apple silicon and Intel, and Linux on x64 and arm64. Beside them are two files:

- `sha256sums.txt`, the SHA-256 checksum of each build;
- `sha256sums.txt.minisig`, a [minisign](https://jedisct1.github.io/minisign/) signature of that file, made with AURELION's release key.

The signature also covers a trusted comment that names the release, such as `tag:v0.10.1-beta`. A signature made for one release can't pass for another, so an old build can't be passed off as a new one.

AURELION's public release key is:

```text
RWTYDrAGVq6o7mUSXgXddDuctD0V0t/mDm6EqcH8OStUBPTFkvsRzAeu
```

The same key is built into AURELION itself. Releases up to v0.6.11-beta came before signing, and AURELION never installs them.

### Check a download yourself

Download your build, `sha256sums.txt` and `sha256sums.txt.minisig` from the same release, then:

```sh
minisign -V -m sha256sums.txt -P RWTYDrAGVq6o7mUSXgXddDuctD0V0t/mDm6EqcH8OStUBPTFkvsRzAeu
shasum -a 256 -c sha256sums.txt --ignore-missing     # on Linux: sha256sum -c sha256sums.txt --ignore-missing
```

The first command checks the signature and prints the trusted comment: make sure it names the release you downloaded. The second checks your build against its checksum.

### The installer

The install script checks every download against the release's checksums. When `minisign` is installed, it checks the signature first. To refuse an install unless the signature can be checked:

```sh
curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/install.sh | AURELION_REQUIRE_SIGNATURE=1 sh
```

[Getting started](getting-started.md#install) covers the installer's other options.

## Updates

```sh
aurelion update            # install the newest release now
aurelion update --check    # only say whether there is one
```

A plain `aurelion` launch also looks for a new release, at most once a day, without holding up the start. What happens next is up to you:

```toml
# ~/.config/aurelion/config.toml
[update]
mode = "notify"   # the default: show the new version on the welcome screen
# mode = "auto"   # also install it, then restart into it
# mode = "off"    # no check at all
```

- Only your global config sets the mode. A project's config can't.
- `AURELION_NO_UPDATE=1` turns the check off whatever the config says, for CI, pinned installs and offline machines. `aurelion -p` never checks.
- Betas count as releases.

Every update, by hand or automatic, follows the same steps:

1. Read the list of releases from GitHub, and pick the newest. Only a version newer than yours is installed; an update never goes back.
2. Download `sha256sums.txt` and its signature, and check the signature against the built-in key, trusted comment included. An unsigned release, or one signed with any other key, is refused: `release vX is not signed with AURELION's release key — not installing`.
3. Download the build and check it against the signed checksum.
4. Only then replace the binary. If any step fails, the running binary stays as it was.

## Your license

Official builds need a license key. `aurelion activate <key>` activates a machine once. After that, AURELION runs on a signed token kept in `~/.config/aurelion/license.json`, and renews it in the background, at most once an hour, when it starts.

The license check sends the license server only what it needs to tie your license to this machine and to confirm that you run an official AURELION build. Your code, prompts, sessions and keys are never part of it.

## What AURELION sends where

| What | Where it goes | When |
| --- | --- | --- |
| Your prompts, the files and output the agent works with, the conversation | The model provider you chose. On a Claude plan, through your own `claude` command. | Every model request. Secrets in tool output are masked before the model sees them. |
| Web requests and searches | The site the agent fetches, or the search service: Tavily, Exa, Brave or Firecrawl when you set its key, SearXNG when you set its address, else DuckDuckGo. | When the agent uses the web tools. A new host asks first. |
| A request for the release list, and the downloads | GitHub | The daily update check, and `aurelion update`. |
| License data (above) | AURELION's license server | When you activate, and at most once an hour after that. |
| Tool calls and data you send them | Your MCP servers, chat platforms, webhooks, hosted memory, embeddings endpoint and cloud sandboxes | Only those you configure. |
| Traces of each turn | Your OpenTelemetry endpoint or Langfuse | Only when you set one. Content only with `include_content = true`. |
| A shared session | GitHub, as a gist | Only when you run `aurelion share --gist`. |
| Skill and plugin installs, and remote skill searches | GitHub, skills.sh or ClawHub, as the source names | Only when you run `aurelion skills install`, `aurelion skills search --remote` or `aurelion plugin install`. |

AURELION collects no usage analytics. Model prices come from a list built into AURELION; it fetches a fresh one from models.dev only when you add `models.dev` to `egress_allow`.

Everything else stays on your machine: your sessions, memory, logs and the snapshots for undo live in the data folder (`aurelion config` prints where) and in each project's `.aurelion/` folder.

## Where your keys are kept

- **A key you give the setup wizard** goes to your system's credential store: the macOS Keychain, or the Secret Service on Linux. Without one, it goes to `~/.config/aurelion/config.key`, which only you can read.
- **Keys of providers you connect in a session** are kept in `connections.json` beside your config, readable only by you.
- **Sign-ins** with `aurelion connect` and `aurelion mcp login` are saved in files only you can read. A Claude plan's sign-in stays with the `claude` command.
- **Keys in your config** can be references to a secret manager instead, such as `op://` for 1Password. See [Configuration](configuration.md#model-and-provider).

AURELION keeps its keys away from what it runs. Commands the agent runs, and the local MCP servers it starts, get none of AURELION's provider, search or chat keys. Give a server the key it needs in its `env` table. `aurelion backup` leaves the credential stores out unless you pass `--include-secrets`.

## Check your setup

`aurelion security audit` looks over your setup for weak spots, on your machine only:

```sh
aurelion security audit           # the findings, worst first
aurelion security audit --fix     # also fix file permissions that are too open
aurelion security audit --json    # the findings as JSON
```

It checks:

- the permissions of your config and credential files and folders;
- keys and tokens written in plain text in the config;
- approval bypass (`yolo`) and broad allow rules;
- whether the bash sandbox and output safety are on;
- an `[api]` server open beyond your machine, or with a weak key;
- wildcards in `egress_allow`;
- hooks and MCP servers that a project's config starts;
- MCP servers that aren't pinned to a version, or that carry a secret in their arguments, in a plain header, or over plain HTTP;
- an emergency stop that is still engaged.

A finding names the file, says what is wrong and how to fix it:

```text
CRITICAL (1)
  [yolo-enabled] Auto-approve (yolo) is on
      ~/.config/aurelion/config.toml: yolo = true runs every tool call without asking
      → remove `yolo = true`; use targeted [[permissions]] allow rules

WARN (1)
  [plaintext-api-key] Plaintext API key in config
      ~/.config/aurelion/config.toml stores a provider key inline
      → move it to an env var (e.g. OPENAI_API_KEY), `api_key_file`, or use `aurelion connect`
```

`--fix` changes only file permissions. The command exits with code 1 while a critical finding remains, so it fits in a script.

## More safeguards

[Modes and safety](modes-and-safety.md) covers the protections you work with every day: approval modes and cards, trusted folders, permission rules, the bash sandbox, the network rules for the web tools, output safety, spend caps, the emergency stop (`aurelion estop`) and the tamper-evident record of every approval (`aurelion ledger`).

Back to the [docs index](README.md).
