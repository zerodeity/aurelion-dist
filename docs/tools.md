# Tools

Tools are how the agent acts: it reads and edits files, runs commands, searches the web, drives a browser and calls other models. AURELION ships a core set that is always on, a shelf of extension tools the agent loads only when it needs them, and room for any MCP server or plugin you add. This page lists them and shows how to add your own.

## Tools in the cockpit

Every call is a row in the stream: the tool, one line of why, what went in and what came back. A call that needs your approval waits on a card. [The cockpit](cockpit.md#the-stream) shows how to read a row, and [Modes and safety](modes-and-safety.md) decides which calls ask.

```text
/tools                          # every tool, with on and off marks
/tools disable browser,webfetch # turn tools off for this session
/tools disable browser --save   # and keep it off in this project
/tools enable browser           # turn it back on
/tools reset                    # everything back on
```

`[tools] timeout_secs` sets how long a call may run (120 seconds by default).

## The core tools

The agent has these from the start, with no search needed.

### Files and code

| Tool | What it does |
| --- | --- |
| `read` | Read a file, in numbered lines: up to 2,000 lines or 64 KB per call, in pages. Reads PDFs as text, and shows PNG, JPEG, GIF and WebP images to the model. |
| `write` | Create or overwrite a file. Overwriting needs the whole file read first. Keeps the file's encoding. |
| `edit` | Replace a string in a file: the exact text first, then a close match. The reply quotes what it replaced and shows the diff. |
| `multiedit` | Several exact replacements in one file, all or nothing. |
| `apply_patch` | A patch across many files: add, update, move and delete. It is checked in full before anything is written. |
| `ls` | A directory tree, with file sizes. |
| `glob` | Find files by pattern, such as `app/**/*.ts`. |
| `fsearch` | Fuzzy, typo-tolerant file search for a name you half know, with filters by type, size, age and content. |
| `grep` | Search file contents with a regular expression: matching lines, files, or counts. |
| `repo_map` | A ranked outline of a code tree: its functions, types and classes, the most-used first. |
| `ast_grep` | Search code by its syntax tree. |
| `ast_edit` | Rewrite code selected by its syntax tree. It previews a diff before it writes. |
| `lsp` | Ask a language server: diagnostics, hover, definition, references, symbols, and renames across files. There when a server is set up or found; see [Language servers](#language-servers). |

`glob`, `grep` and `ls` respect `.gitignore`, skip dotfiles unless asked, and never look inside `.git`. A `grep` across folders skips `.env` and other secret files; name one as the path to search it. `ast_grep` and `ast_edit` know Rust, Python, TypeScript, TSX, JavaScript and Go.

After an `edit`, `write` or `multiedit`, AURELION runs the file's formatter (`rustfmt`, `gofmt` or `prettier`) when one is installed, but only on a file that was formatted before the edit, so a file you keep unformatted stays as you wrote it. The result says how many lines the formatter changed. The project's own formatter setup runs only in a trusted folder. `format_on_save = false` turns formatting off.

### Shell and code

| Tool | What it does |
| --- | --- |
| `bash` | Run a shell command. See below. |
| `execute_code` | Run a Python script that calls the read-only tools (`read`, `grep`, `glob`, `ls`, `repo_map`, `ast_grep`) in a loop, to batch many reads into one step. Only what it prints comes back. |
| `tool_forge` | Build a small tool of the agent's own, as a standalone Rust program, and run it later. Forged tools persist. |

`bash` keeps long work going. A command can start in the background and return a job id at once, and a command still running after 60 seconds moves to the background on its own. The agent then reads its output, waits for it or stops it. Interactive programs (a REPL, a prompt, `ssh`) run as interactive jobs, with a real terminal when they need one: the agent types into them and sends keys such as `Ctrl+C`. Long output keeps its first 4 KiB and its last 24 KiB, and the job's log holds all of it. A command runs with no terminal of its own, so a prompt fails at once instead of hanging.

[Modes and safety](modes-and-safety.md#the-shell) covers what `bash` may do on its own, the sandbox, and running commands in Docker, over SSH or in a cloud sandbox.

### The web

| Tool | What it does |
| --- | --- |
| `webfetch` | Fetch a URL as readable Markdown. JSON, text and PDFs come back as text. |
| `websearch` | Search the web, with titles, links and snippets. |
| `browser` | Read a page in your Chrome: open a URL, or the current tab, and get its title and text. |
| `browser_act` | Act in your Chrome: navigate, click, type, press keys, scroll, wait, and take a screenshot. |

`websearch` uses the first service you have a key for: Tavily (`TAVILY_API_KEY`), Exa (`EXA_API_KEY`), Brave (`BRAVE_API_KEY`), Firecrawl (`FIRECRAWL_API_KEY`), SearXNG (`SEARXNG_URL`), then DuckDuckGo, which needs no key. When one fails, the next one answers. `AURELION_WEBSEARCH_BACKEND=brave` pins one: `tavily`, `exa`, `brave`, `firecrawl`, `searxng` or `ddg`.

The browser tools drive a Chrome you start yourself, with `--remote-debugging-port=9222`. AURELION never launches it, and `aurelion doctor` checks that it can reach it. Both browser tools ask before they run. To use a cloud browser instead, set `AURELION_BROWSER_BACKEND` to `browserbase`, `browser-use`, `steel`, `hyperbrowser` or `lightpanda`.

Every web request passes the network rules in [Modes and safety](modes-and-safety.md#the-network): a new host asks first.

### Planning and asking

| Tool | What it does |
| --- | --- |
| `todo` | The agent's task list for a job. It survives restarts and compaction, and shows in the Todos pane. |
| `ask_user` | Ask you a question with a few options, or several questions in a row. |
| `plan_write` | In plan mode, write the plan to `.aurelion/PLAN.md`. The one write plan mode allows. |

### Memory and skills

| Tool | What it does |
| --- | --- |
| `remember` · `recall` · `forget` | Facts that last across sessions: for this project, or for all your projects. |
| `session_search` | Full-text search over your past sessions: prompts, answers and tool output. |
| `skills` | List the skill packs and load one's instructions. |
| `skill_manage` | Create, update and delete skill packs. It asks before it runs. |

[Memory and context](memory-and-context.md) covers these.

### Agents and automation

| Tool | What it does |
| --- | --- |
| `task` | Spawn subagents: one, several in parallel, or a graph of steps that depend on each other. |
| `agents_list` · `agents_wait` · `sessions_yield` | See the agents `task` can spawn, wait for background ones, or pause the turn until they finish. |
| `llm_task` | One call to a model with no tools, returning JSON checked against a schema. |
| `cronjob` | Schedule a job, or suggest one for you to accept. |

See [Agents](agents.md) and [Automation](automation.md).

## Deferred tools

Every tool's description costs context in every request, so the less common ones stay out until the agent needs them. The always-on `tool_search` finds a deferred tool by name or purpose and loads it on the spot. A server with hundreds of tools then costs nothing until one is used.

MCP tools are deferred too, by default:

```toml
[tools]
defer_mcp = true   # the default; false sends every MCP tool's schema in every request
```

## Extension tools

These come deferred. Most need a key or a program first.

| Tool | What it does | Needs |
| --- | --- | --- |
| `tts` · `tts_voices` | Text to speech, and the voices a backend offers. | OpenAI, ElevenLabs, Azure Speech (`AZURE_SPEECH_KEY`, `AZURE_SPEECH_REGION`), Fish Audio (`FISH_API_KEY`), Inworld (`INWORLD_API_KEY`) or Gradium (`GRADIUM_API_KEY`); or local `say`, `piper` or `espeak-ng`; or NeuTTS voice cloning (`AURELION_NEUTTS_REF_AUDIO`, `AURELION_NEUTTS_REF_TEXT`). |
| `transcribe` | Audio or video to text. | An OpenAI, Groq, Deepgram or SenseAudio (`SENSEAUDIO_API_KEY`) key, or local `whisper-cli` with `AURELION_WHISPER_MODEL`. |
| `image_generate` | Generate or edit images. | OpenAI, `FAL_KEY`, `REPLICATE_API_TOKEN`, or `AURELION_COMFYUI_URL`. |
| `video_generate` · `music_generate` | Video and music jobs on fal.ai or Replicate. | `FAL_KEY` or `REPLICATE_API_TOKEN`. |
| `video_understand` | Sampled frames of a video, with its transcript. | `ffmpeg`. |
| `doc_extract` | Text from DOCX, XLSX, PPTX, ODT, ODS, ODP and EPUB. | Nothing. |
| `diff_render` | A diff as text, terminal colors, or an HTML file. | Nothing. |
| `canvas` | A live HTML page in your browser, on this machine only, that the agent writes and updates. Scripts in it never run. | Nothing. |
| `portal` | Share a local dev server through a private link. `public: true` reaches it from the internet through a Cloudflare quick tunnel. | `cloudflared`, for public links. |
| `code_mode` | One Python script that calls any tool as a function, to batch many calls. Each call still passes your rules and approvals. | Python 3. |
| `computer` | Screenshots, mouse and keyboard on your desktop (macOS, X11, Wayland). It asks before every action. | `AURELION_COMPUTER_USE=1`, or `readonly` for screenshots only. |
| `browser_fill_credential` | Type a Keychain or 1Password secret into a login field. The model never sees the secret. | The page's origin must match the secret's. |
| `meeting` | Join a Google Meet, Zoom, Teams or Slack huddle as a note-taking bot: live captions, a transcript and a summary. | Chrome. |
| `x_search` | Search recent posts on X. | `X_BEARER_TOKEN` or `XAI_API_KEY`. |
| `wiki_read` · `wiki_write` · `wiki_search` · `wiki_list` | A wiki of linked Markdown pages in `.aurelion/wiki/`. | Nothing. |
| `feishu_doc_read` and the `feishu_drive_*` tools | Read Feishu or Lark docs, and read and answer their comments. | `AURELION_FEISHU_APP_ID`, `AURELION_FEISHU_APP_SECRET`. |
| `github_identity_status` · `github_publish` | Which GitHub account `gh` and git would use; then publish the work as a draft pull request. | The `gh` CLI, signed in. |
| `mixture_of_agents` | Ask several models, and combine one answer. | `AURELION_MOA_MODELS=provider/model,…` |
| `decision_evaluate` | A calibrated judge: yes-or-no odds, a choice between options, or a score. | `decision_model`, or the small model. |
| `kanban` | The kanban board. | Nothing. See [Automation](automation.md). |
| `sessions_list` · `sessions_history` · `sessions_send` · `presence` | See your other running sessions, read them and message them. | Nothing. |
| `node_list` · `node_exec` · `node_read` · `node_screen` | Run commands, read files and see the screen on a paired device. | A paired device. See [Editors and devices](editors-and-devices.md). |
| `a2a_call` | Call a remote agent over the Agent2Agent protocol. | `AURELION_A2A_PEERS=name=url,…` |

By default these ask before they run: `computer`, `browser_fill_credential`, `code_mode`, `canvas`, `portal`, `meeting`, `github_publish`, `kanban`, `wiki_write`, `a2a_call`, `node_exec`, `node_read` and `node_screen`. [Modes and safety](modes-and-safety.md#rules) shows how to change that.

## MCP servers

Add any Model Context Protocol server, and its tools join the agent's as `mcp__<server>__<tool>`. They show in the stream as `⬡ server.tool`.

The quickest way is the built-in catalog:

```sh
aurelion mcp catalog              # filesystem, github, playwright, context7, sqlite, postgres, …
aurelion mcp install context7     # add one to your global config (--project for this project)
aurelion mcp list                 # what you have, and its state
```

Or add one yourself:

```sh
aurelion mcp add fs --command npx --arg -y --arg @modelcontextprotocol/server-filesystem --arg .
aurelion mcp add brave --command npx --arg -y --arg @brave/brave-search-mcp-server --env BRAVE_API_KEY
aurelion mcp add cloud --url https://mcp.example.com/mcp --header 'Authorization=Bearer ${MCP_TOKEN}'
aurelion mcp disable fs           # keep it, but don't start it
aurelion mcp remove fs
```

Hosted services sign in with OAuth:

```sh
aurelion connect list             # github, linear, notion, sentry, atlassian, stripe, figma, …
aurelion connect add linear       # add it and sign in, in the browser
aurelion mcp login <name>         # sign in to any remote server; mcp logout forgets it
```

In the config, a server is an `[[mcp]]` table:

```toml
[[mcp]]
name = "fs"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "."]
disabled_tools = ["write_file"]       # or enabled_tools = [...] to allow only those

[[mcp]]
name = "brave"
command = "npx"
args = ["-y", "@brave/brave-search-mcp-server"]
env = { BRAVE_API_KEY = "${BRAVE_API_KEY}" }

[[mcp]]
name = "cloud"
url = "https://mcp.example.com/mcp"
headers = { Authorization = "Bearer $MCP_TOKEN" }
trust = "read"
```

What to know:

- **Every MCP tool asks** before it runs. `trust = "read"` lets the tools a server marks read-only (and not destructive) run without asking. That means you trust the server to label its tools honestly. Its other tools still ask, and your own rules always win.
- **A local server starts with a clean environment.** `PATH`, `HOME` and the like pass, but your provider keys and AURELION's own tokens don't. Name what a server needs in its `env` table; `${VAR}` reads it from your shell. `aurelion mcp add --env` and `mcp install` write that for you. Only your global config can set `env`.
- **Remote servers** use `url` instead of `command`. Headers expand `$VAR`, `${VAR:-default}` and `$(command)`. An expired session reconnects on its own. For a server without dynamic sign-up, set `oauth_client_id`, `oauth_client_secret`, `oauth_scopes` and `oauth_redirect_port` in your global config.
- **Servers can change.** When a server's tool list changes, AURELION installs the new tools once the running turn ends.
- **Resources and prompts.** A server that offers them adds `mcp_resources_list`, `mcp_resource_read`, `mcp_prompts_list` and `mcp_prompt_get`.
- **Questions from a server** (elicitation) show as prompts in the cockpit.
- **Sampling.** `sampling = true` lets a server ask your model for completions: rate-limited, token-capped, with no tools, in the cockpit only.
- **Under `claude-cli`**, Claude Code gets only the `trust = "read"` servers, and only their read-only tools.

`/mcp` shows each server's health in a session, and `/mcp reconnect <server>` restarts one. The rail's MCP tab shows each server with its calls.

## Language servers

The `lsp` tool talks to language servers. With no `[[lsp]]` in your config, AURELION starts the ones it finds on your `PATH`: `rust-analyzer`, `typescript-language-server`, `pyright-langserver`, `gopls` and `clangd`. To choose your own:

```toml
[[lsp]]
extensions = [".go"]
command = "gopls"
args = []
```

Language servers hear every save, so their errors come back with the edit that caused them. `rename` applies its changes on disk.

## Plugins

Runtime plugins add tools, slash commands and chat channels, as programs that talk to AURELION over JSON-RPC. Their tools are always deferred.

```sh
aurelion plugin install ./my-plugin       # or gh:owner/repo[/subdir][@ref]
aurelion plugin enable my-plugin          # installed plugins start disabled
aurelion plugin list
aurelion plugin info my-plugin            # what its manifest asks for
```

A plugin's manifest names the environment variables it wants; `enable` passes them only once you approve each one.

**Next:** [Agents](agents.md)
