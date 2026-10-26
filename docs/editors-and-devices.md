# Editors and devices

AURELION isn't tied to its own screen. Your editor can drive it over the Agent Client Protocol, any MCP client can use its tools, and the agent can work on other machines you pair with it. This page also covers voice, containers and shell completion.

## Editors

`aurelion acp` runs AURELION as an [Agent Client Protocol](https://agentclientprotocol.com) agent over stdio, so an editor that supports ACP, such as Zed, can use it as its coding agent. In your editor's settings for external agents, set the command to `aurelion` with the argument `acp`.

```sh
aurelion acp
aurelion acp --profile work    # under a profile
```

What the editor gets:

- **Sessions in its folder.** Each session works in the folder the editor sends. The editor can also reopen a stored AURELION session.
- **Plan mode.** The editor can switch a session between the default mode and plan mode, and change the model.
- **A live view.** The answer streams in, and each tool call shows with its state.
- **Approvals in the editor.** A call that needs approval asks the editor, with allow once, allow always and reject. An approval left unanswered for 120 seconds is denied; `AURELION_ACP_PERMISSION_TIMEOUT_SECS` changes that. An editor that can't answer approvals gets them denied at once, so nothing hangs.
- **Cancel.** Stopping in the editor stops the turn.

A session has your full toolset: the built-in tools, plus the MCP servers, language servers and plugins from your config. MCP servers that the editor itself lists are not started, and a session that asks for them is refused, so you always know which servers run. Subagents are part of the interactive app only.

Prompts take text, links to files and embedded text. Images, audio and binary files are refused with an error.

## AURELION as an MCP server

`aurelion serve-mcp` offers AURELION's built-in tools to any MCP client over stdio: `read`, `write`, `edit`, `bash`, `grep`, `glob` and the rest, plus memory (`remember`, `recall`, `forget`), `session_search` and `skills`. Most clients take an entry like this:

```json
{
  "mcpServers": {
    "aurelion": { "command": "aurelion", "args": ["serve-mcp"] }
  }
}
```

The client decides what runs: AURELION's own approvals don't apply to tools called this way, so use the client's permission settings. `[tools] sandbox` and `[tools] timeout_secs` do apply, so `bash` runs in the sandbox when you turned it on.

```sh
aurelion serve-mcp --read-only
```

`--read-only` offers only the search tools for your past sessions (`session_search`, `sessions_history` and `recall`) and refuses everything else.

## Device nodes

A node is another machine the agent can work on: a build server, a Raspberry Pi, a second laptop. Pair it once, run the node there, and the agent can run commands, read files and see the screen on it, over an encrypted, authenticated connection.

**1. Open a pairing window** on the machine you run AURELION on:

```sh
aurelion node pair            # prints a code like ABCD-EFGH-JKLMN, and waits 5 minutes
```

It listens on port 7879. `--listen` changes the address, `--name` sets the name the device will know it by, and `--yes` approves the device without asking.

**2. Join from the device**, with the controller's address and the code:

```sh
aurelion node join 192.168.1.20:7879 --code ABCD-EFGH-JKLMN --name pi --caps exec,fs
```

Back on the controller, approve the device when asked. Each side keeps the other's key, so later connections need no code. A code works once, and five wrong tries close the window.

**3. Run the node** on the device:

```sh
aurelion node serve --caps exec,fs,screen --root ~/work
```

| Capability | What the agent may do |
| --- | --- |
| `exec` | Run shell commands in the node's folder. They run in the device's sandbox unless you start it with `--no-sandbox`. Output is capped at 64 KiB per stream, and a command runs at most 600 seconds. |
| `fs` | Read files and list folders under `--root` (the current folder by default). Nothing outside it can be reached, links included. A read returns at most 1 MiB. |
| `screen` | Take a screenshot: `screencapture` on macOS, `grim` or `import` on Linux. |

The node listens on port 7878 (`--listen` changes it) and announces itself on the local network over mDNS, unless `--no-mdns`. Every request is checked again on the device, which must still have the controller paired and the capability on, and the device keeps a log of each one.

```sh
aurelion node list            # paired devices, and nodes seen on the network
aurelion node revoke pi       # forget one, by id, id prefix or name
```

The agent reaches nodes with the deferred tools `node_list`, `node_exec`, `node_read` and `node_screen`. All but `node_list` ask before they run. Stopping a turn stops the command on the node too.

A node's keys live in `~/.config/aurelion/node/`, or in `AURELION_NODE_HOME`.

## Voice

**Talking to AURELION** with your microphone and speaker needs a build with voice support. Release builds have none, and `aurelion talk`, `F7` and `/voice` say so when you try them.

```sh
aurelion talk                          # OpenAI Realtime
aurelion talk --backend gemini --voice Puck
aurelion talk --backend local          # turn by turn: speech to text, a turn, text to speech
aurelion talk --wake                   # wait for a wake word from a wake-word plugin
```

**Phone calls** need no microphone on your machine, so they work in every build: `aurelion serve --voice-call` answers calls through Twilio. See [Serve and chat](serve-and-chat.md#phone-calls).

**Speech as tools** works in every build too: the `tts` tool turns text into an audio file, and `transcribe` turns audio or video into text. See [Tools](tools.md#extension-tools).

## Containers

To run commands in a container while AURELION runs on your machine, use the `docker` backend. See [Modes and safety](modes-and-safety.md#where-commands-run).

To run AURELION itself in a container: the Linux builds are self-contained, so they run in any Linux image. Install with the installer:

```dockerfile
FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://raw.githubusercontent.com/zerodeity/aurelion-dist/main/install.sh \
  | AURELION_INSTALL_DIR=/usr/local/bin sh
WORKDIR /workspace
ENTRYPOINT ["aurelion"]
```

A license is activated per machine, and a container is a machine of its own. Keep `~/.config/aurelion/` on a volume, where the license and your config live, and give the container a fixed host name (`docker run --hostname …`) or a fixed `/etc/machine-id`. Otherwise each new container is a new machine to activate.

Inside a container, the `bash` sandbox needs `bwrap` (the `bubblewrap` package), and `aurelion doctor` checks that it is installed. Where it can't run, sandboxed commands fail instead of running unconfined.

## Shell completion

```sh
aurelion completions zsh > ~/.zfunc/_aurelion
aurelion completions bash > ~/.local/share/bash-completion/completions/aurelion
aurelion completions fish > ~/.config/fish/completions/aurelion.fish
```

`elvish` and `powershell` work too.

**Next:** [Configuration](configuration.md)
