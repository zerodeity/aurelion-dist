# Configuration

Everything AURELION does can be set in a TOML file: the model, the rules, the tools, the servers and the look. Most settings have a sensible default, so a config of two lines is a fine start. This page explains where settings come from and how to change them, then lists the settings by section. The comments in each example name the defaults.

## Where settings come from

Settings are read in layers. A later layer wins over an earlier one:

1. the built-in defaults;
2. your global config, `~/.config/aurelion/config.toml`;
3. the project's config, `.aurelion/config.toml` in the folder you start in;
4. environment variables such as `AURELION_MODEL`;
5. flags such as `--model`, for one run.

A table in a later layer merges into the same table of an earlier one, key by key, so a project can change one setting of `[tools]` without repeating the rest. `[[permissions]]` and `[[hooks]]` add up, the global ones first, so your global deny rules and hooks always stay. An `[[mcp]]` or `[[lsp]]` entry replaces an earlier one of the same name.

**The project's config needs trust.** A repository decides what is in its `.aurelion/config.toml`, so in a folder you haven't [trusted](modes-and-safety.md#trusted-folders), AURELION keeps only the harmless settings from it: model names (but not a `provider/model` route), the theme, the effort, caching, compaction sizes, the interface, formatting, and memory settings (but not hosted memory). It may lower your spend caps and the checks' fix rounds, turn the completion guard or the checks off, and turn the sandbox on, but never the other way round. Everything that could run a command, turn approvals off, change where requests go, send data out or spend more is dropped, with a warning at startup. Trust the folder and restart, and the whole file applies.

**Some settings are yours alone.** Whatever the trust, a project's config can't set `[env]`, `[update]`, `egress_allow_local`, the `env` table of an MCP server, or an MCP server's OAuth secret. Only your global config can.

`yolo = true` in any config file counts only in a trusted folder. Elsewhere, only `--yolo`, `AURELION_YOLO=1` or `/yolo` turn approvals off.

## Change settings

Edit the file, or use the command line. `config set` writes the global config unless you add `--project`, and refuses a change that would leave the config invalid:

```sh
aurelion config                            # the files, the folders, and the settings in effect
aurelion config set model claude-sonnet-4-5
aurelion config set exec.backend docker --project
aurelion config get tools.timeout_secs     # the project's value wins over the global one
aurelion config unset exec.backend
aurelion config list                       # every key you set, per file
aurelion config check                      # validate both files; exits non-zero on an error
aurelion config edit                       # open the file in $VISUAL or $EDITOR, then validate it
```

`/config` in a session shows where the files live, and `/reload` reads the config again.

`aurelion schema` prints a JSON Schema of the config file. Point your editor's TOML support at it to get completion and checks as you type.

A [profile](models.md#profiles) is a named set of overrides, picked per run with `--profile` or `AURELION_PROFILE`:

```toml
[profiles.cheap]
model = "claude-haiku-4-5"
effort = "low"

[profiles.cheap.tools]
timeout_secs = 300
```

## Model and provider

[Models and providers](models.md) explains these in depth.

```toml
provider = "anthropic"            # one of 84; `aurelion providers` lists them
model = "claude-sonnet-4-5"       # the model id (on Azure, the deployment name)
model_small = "claude-haiku-4-5"  # side jobs: compaction, memory, titles
vision_model = "claude-haiku-4-5" # describes images for a text-only model, same provider
decision_model = "claude-haiku-4-5"   # the decision_evaluate judge; unset: model_small, then model
fallback = ["claude-haiku-4-5"]   # tried in order when the model is busy
effort = "medium"                 # off, low, medium (the default), high or xhigh
max_tokens = 0                    # 0: the model's full output limit
service_tier = "auto"             # OpenAI: auto, default, flex, priority; Anthropic: auto, standard_only
prompt_cache = true               # Anthropic prompt caching (the default)
cache_ttl = "5m"                  # how long the cache lives: 5m or 1h

base_url = "https://llm.example.com/v1"   # another endpoint for the provider
protocol = "chat"                 # how to talk to it: chat, responses or anthropic
openai_api = "auto"               # for provider openai: auto, responses or chat
reasoning_echo = "auto"           # send streamed reasoning back to OpenAI-compatible servers: auto, on or off

api_key = "op://Private/Anthropic/credential"   # a key, or where it lives
api_keys = ["$KEY_ONE", "$KEY_TWO"]             # a pool of keys
api_key_file = "/opt/keys/aurelion.key"         # a file that holds the key (a full path)

claude_cli_resume = true          # claude-cli: resume one Claude Code session per session
```

- `api_key` may be the key itself, a variable such as `$MY_KEY`, or a reference to a secret manager: `op://vault/item/field` (1Password), `vault://<path>#<field>` (HashiCorp Vault), `bw://<item>/<field>` (Bitwarden) or `keychain://<service>/<account>` (the macOS Keychain, or the Secret Service on Linux). `aurelion secrets check` tests that the references in your global config resolve.
- `api_keys` adds keys to a pool with `api_key`: a key that hits a rate limit cools down, and one that is rejected is retired.
- `api_key_file` names a file, readable only by you, that holds the key. The setup wizard keeps the key in `config.key` this way when there is no system credential store. A key written in `api_key` wins over it.
- With `openai_api = "auto"`, the `openai` provider uses the Responses API for reasoning models on api.openai.com, and Chat Completions for the rest.
- `reasoning_echo = "auto"` sends a server's streamed reasoning back to it in the history, as DeepSeek needs with tools, and stops for a server that refuses it.

```toml
[routing]
mode = "auto"            # off (the default) or auto: short chats start on model_small
max_simple_chars = 160   # the longest prompt still counted as short

[moa]
default_preset = "default"

[moa.presets.default]
references = ["openai/gpt-5.5", "openrouter/deepseek/deepseek-v4-pro"]
aggregator = "anthropic/claude-opus-4-8"   # the acting model; unset: the session's
fanout = "user_turn"     # or per_iteration: consult them on every model call
timeout_secs = 120       # how long a reference may take

[claude]
silence_secs = 120       # claude-subscription: stop a call that goes quiet this long (30 to 3600)
```

## Interface and updates

```toml
theme = "phosphor"       # phosphor, phosphor-amber, ember-dark, dusk, blood, ink, violet, cobalt, or your own

[ui]
animations = true        # false keeps the flow view, readouts and cards still
screen_reader = false    # true: a linear transcript with no boxes or redraws

[update]
mode = "notify"          # notify (the default), auto or off
```

[The cockpit](cockpit.md#themes) covers themes, and [Getting started](getting-started.md#update) the update modes. `[update]` counts only in your global config.

## Approvals and safety

[Modes and safety](modes-and-safety.md) explains each of these.

```toml
yolo = false                       # true skips approvals, in trusted folders only
permission_reviewer = "off"        # smart: a cheap model screens approvals first

max_spend_usd = 5.0                # per session, subagents included; unset: no cap
max_spend_usd_per_turn = 1.0       # per prompt

egress_allow = ["pypi.org", "*.github.com"]   # hosts the web tools may reach without asking
egress_allow_local = false         # true: the web tools may reach localhost and your LAN

[tools]
ask = ["bash", "browser"]          # the tools that always ask; replaces the default list
timeout_secs = 120                 # how long a tool call may run
sandbox = false                    # true: confine every bash command
output_safety = true               # mask secrets in tool output, mark web output as untrusted
defer_mcp = true                   # MCP tools load only when the agent searches for them
verify_gate = true                 # nudge the agent once to run a build or test after editing code
webfetch_readability = true        # webfetch turns article pages into Markdown

[web]
allow_domains = ["*.python.org"]   # when set, the only hosts the web tools may read
deny_domains = ["example.com"]     # always refused; wins over allow_domains

[[permissions]]
tool = "bash"
pattern = "git push*"              # a glob over the command, or over the path for file tools
action = "deny"                    # allow, ask or deny; the last matching rule wins
```

- `aurelion config` prints the `ask` list in effect.
- `bash_sandbox = true` at the top level does the same as `[tools] sandbox`, and wins over it. A project in an untrusted folder can't turn the sandbox off.
- `defer_mcp` at the top level does the same as `[tools] defer_mcp`.
- `egress_allow = ["*"]` opens every host to the web tools, never to provider traffic.
- Caps count metered providers only: on a Claude plan the cost is shown, not capped.

## Where commands run

`[exec]` sends `bash` commands somewhere other than your machine. See [Modes and safety](modes-and-safety.md#where-commands-run).

```toml
[exec]
backend = "docker"        # local (the default), docker, ssh, singularity, modal, daytona or vercel

[exec.docker]
image = "rust:1-bookworm" # the default image; one long-lived container per project
container = "dev"         # or reuse a running container
network = false           # no network inside the container (the default)
egress = "allowlist"      # open, none, or allowlist: only HTTP(S) to the hosts below
egress_allow = ["pypi.org", "*.github.com"]
extra_args = []           # more docker run arguments
shell = "bash"

[exec.ssh]
host = "me@build-box"     # required: user@host, or an ssh_config alias
remote_dir = "/srv/project"   # required: where the project maps to
port = 22
identity_file = "~/.ssh/id_ed25519"
extra_args = []
shell = "bash"

[exec.singularity]
image = "docker://ubuntu:24.04"   # required: a .sif file or a docker:// image
binary = "apptainer"      # the default, falling back to singularity
cleanenv = true
containall = false
extra_args = ["--nv"]
shell = "bash"

[exec.modal]
image = "python:3.12-slim"
gpu = "T4"
cpu = 2.0
memory_mb = 4096
timeout_secs = 3600       # the sandbox's lifetime
persist = false           # true keeps it when AURELION exits
python = "python3"        # a Python with modal installed
remote_dir = "/workspace"
shell = "bash"

[exec.daytona]
image = "python:3.12"     # or snapshot = "<name>"
cpu = 2
gpu = 0
memory_mb = 4096
timeout_secs = 3600       # idle time before Daytona stops it
persist = false
api_url = "https://app.daytona.io/api"
shell = "bash"

[exec.vercel]
timeout_secs = 2700
persist = false
project = "my-project"    # default: VERCEL_PROJECT_ID
team = "my-team"          # default: VERCEL_TEAM_ID
shell = "bash"
```

`[exec.daytona]` also takes `snapshot` and `remote_dir`, and `[exec.vercel]` takes `image` and `remote_dir`. Modal needs `pip install modal` and `MODAL_TOKEN_ID` and `MODAL_TOKEN_SECRET`, Daytona needs `DAYTONA_API_KEY` and a local `ssh`, and Vercel needs its `sandbox` CLI or `VERCEL_TOKEN`.

## Tools, servers and formatting

[Tools](tools.md) covers these.

```toml
format_on_save = true      # run the file's formatter after an edit

[[mcp]]
name = "fs"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "."]
env = { API_TOKEN = "${API_TOKEN}" }   # global config only
enabled_tools = ["read_file", "list_directory"]   # only these; or disabled_tools = [...]
trust = "read"             # ask (the default) or read: read-only tools run without asking
sampling = false           # true: the server may ask your model for completions
enabled = true             # false keeps it configured but stopped

[[mcp]]
name = "corp"
url = "https://mcp.corp.example/mcp"
headers = { Authorization = "Bearer $CORP_TOKEN" }
oauth_client_id = "aurelion-cli"           # for a server without dynamic sign-up
oauth_client_secret = "${CORP_MCP_SECRET}" # global config only
oauth_scopes = ["mcp.read"]
oauth_redirect_port = 8765

[[lsp]]
extensions = [".go"]
command = "gopls"
args = []
```

`disabled_tools` wins over `enabled_tools`, and an empty `enabled_tools` blocks all the server's tools.

## Checks after a turn

```toml
[verify]
enabled = true                          # the default
commands = ["npm test", "npm run lint"] # unset: found from the project
max_fix_rounds = 2                      # at most 10
```

See [Undo and review](undo-and-review.md#checks-after-a-turn).

## Context and memory

[Memory and context](memory-and-context.md) explains these.

```toml
compact_after_tokens = 0     # 0: compact near the model's window; or a token count
compact_on_complete = 0      # 0: off; unset: half the window, at most 250,000 tokens
fact_extraction = true       # file your instructions and decisions after each turn

[compaction]
mode = "auto"                # auto, native or local
native_threshold_tokens = 150000

[context]
engine = "default"           # or plugin:<name>

[memory]
active_max_tokens = 600      # recalled memory per turn; 0 turns recall off
project_char_limit = 6000
user_char_limit = 3000
vector = true                # the vector index, when an embeddings endpoint is set
write_approval = false       # true: memory writes wait for /memory approve
profile_isolation = "user"   # user, all or off

[[memory.backend]]
kind = "hindsight"           # mem0, supermemory, honcho, hindsight, retaindb, byterover or http
base_url = "http://localhost:8888"   # the default for hindsight; the hosted ones default to their service
api_key_env = "HINDSIGHT_API_KEY"
project = "team-x"
dialectic = false            # Honcho only
```

## Agents

[Agents](agents.md) explains these.

```toml
[subagents]
model = "claude-sonnet-4-5"  # unset: the session's model
effort = "low"
max_depth = 2
max_live = 8
orchestrate = true

[[agent]]
name = "reviewer"
description = "reviews a change for bugs"
prompt = "You review code changes and report concrete bugs only."
model = "claude-sonnet-4-5"
tools = ["bash"]
readonly = false

[autopilot]
enabled = true               # the completion guard (the default)
max_continues = 3            # at most 20
max_minutes = 30             # at most 240

[advisory]
enabled = false              # the watchdog that reviews each finished turn
focus = "missed requirements and regressions"
```

## Skills

[Memory and context](memory-and-context.md#skills) explains these.

```toml
[skills]
review = true
review_min_tools = 8
review_model = "claude-haiku-4-5"
review_max_tokens = 2048
nudge_interval = 15
write_approval = false
external_dirs = ["~/team-skills"]
create_dir = "~/brain/skills"

[skills.config]
"ddg.region" = "de-de"

[curator]
enabled = true
interval_hours = 168
consolidate = false
model = "claude-haiku-4-5"
```

## Automation

[Automation](automation.md) explains these.

```toml
[cron]
failure_repeat_alert_hours = 6   # 0: alert on every failure

[kanban]
board = "team"
max_workers = 4
interval_secs = 30
failure_limit = 2
stale_secs = 3600
review_dispatch = true
dispatch_in_serve = true
configured_lanes_only = false

[kanban.lanes.coder]
model = "claude-sonnet-4-5"
provider = "anthropic"
profile = "cheap"
skills = ["test-driven-development"]
concurrency = 1
max_spend = 2.0
timeout_secs = 7200
reviewer = "reviewer"
yolo = false

[[hooks]]
event = "pre_tool_use"
command = "~/.config/aurelion/hooks/guard.sh"
matcher = "bash"
fail_closed = true          # block when the hook can't give an answer
```

A hook may name `tools = ["bash", "write"]` instead of a `matcher`, to fire for those exact tools.

## Serve and the API

[Serve and chat](serve-and-chat.md) explains these.

```toml
notify_telegram = false      # true: tell the paired Telegram chat when long jobs finish

[serve]
approval_timeout_secs = 300
live_edits = true
attach_paths = true
media_strict = false
media_allow_dirs = []
message_targets = []
boot_deliver = "telegram"
heartbeat_secs = 30
watchdog = true

[serve.discord]
admin_actions = []

[[serve.route]]
name = "support"
channel = "slack"
account = "T0123"
chat = "C0SUPPORT*"
sender = "*"
model = "claude-haiku-4-5"
workdir = "/srv/helpdesk"
system_prompt_append = "Answer as the support bot."
tools = ["read", "grep"]
memory_scope = "support"

[api]
bind = "127.0.0.1"
port = 8642
api_key = "a-long-random-key"   # AURELION_API_SERVER_KEY wins over it
```

## Telemetry

AURELION sends no telemetry unless you set an endpoint. With one, it exports a span for each turn, model call and tool call as OTLP over HTTP:

```toml
[telemetry]
otlp_endpoint = "http://localhost:4318"   # spans go to <endpoint>/v1/traces
include_content = false                   # true adds prompts, replies and tool input and output, with secrets masked, up to 8 KB each
```

The standard `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` and `OTEL_EXPORTER_OTLP_HEADERS` variables work too, and win over the config. For Langfuse, set `LANGFUSE_PUBLIC_KEY` and `LANGFUSE_SECRET_KEY`, and `LANGFUSE_HOST` for a server of your own.

## Environment variables

Most top-level settings can come from the environment, which wins over both files: `AURELION_PROVIDER`, `AURELION_MODEL`, `AURELION_MODEL_SMALL`, `AURELION_API_KEY`, `AURELION_BASE_URL`, `AURELION_THEME`, `AURELION_EFFORT`, `AURELION_YOLO`, `AURELION_SERVICE_TIER`, `AURELION_PROMPT_CACHE`, `AURELION_CACHE_TTL`, `AURELION_PROTOCOL`, `AURELION_OPENAI_API`, `AURELION_REASONING_ECHO`, `AURELION_FORMAT_ON_SAVE`, `AURELION_CLAUDE_CLI_RESUME`, `AURELION_FACT_EXTRACTION`, `AURELION_BASH_SANDBOX`, `AURELION_DEFER_MCP` and `AURELION_NOTIFY_TELEGRAM`. A yes-or-no variable takes `1`, `true`, `yes` or `on`, and `0`, `false`, `no` or `off`.

`AURELION_API_KEY` and `AURELION_BASE_URL` stay with the provider they were first used with: when you switch to another provider, it gets its own key and endpoint.

Others change behavior that has no config key:

| Variable | What it does |
| --- | --- |
| `AURELION_PROFILE` | The [profile](models.md#profiles) to use. `--profile` wins. |
| `AURELION_NO_UPDATE=1` | No startup update check. |
| `AURELION_NOTIFY` | Desktop notifications: `always`, `off`, or unset for when the terminal is in the background. |
| `AURELION_SCREEN_READER=1` | Screen reader mode. |
| `AURELION_WEBSEARCH_BACKEND` | Pin `websearch` to `tavily`, `exa`, `brave`, `firecrawl`, `searxng` or `ddg`. |
| `AURELION_BROWSER_BACKEND` | A cloud browser for the browser tools. |
| `AURELION_EMBEDDINGS_URL` · `_KEY` · `_MODEL` | Search memory by meaning. |
| `AURELION_IMAGE_KEEP_TURNS` | Images older than this many prompts are left out of requests (3 by default; `0` keeps them). |
| `AURELION_BASH_COMPACT=0` | Keep noisy command output word for word. |
| `AURELION_REPETITION_GUARD=0` | Turn off the guard against a model repeating itself. |
| `AURELION_NO_BUILTIN_SKILLS=1` | Turn the built-in skills off. |
| `AURELION_CLAUDE_KEEP_AUTH_ENV=1` | Pass your Anthropic key variables to Claude Code. |

The tool, chat and server pages name the variables of their own features.

### The `[env]` table

`[env]` in your global config sets environment variables at startup, for those not already set:

```toml
[env]
TAVILY_API_KEY = "tvly-…"
AURELION_NOTIFY = "always"
```

Values expand `$VAR`. It takes only variables AURELION reads (`AURELION_*`, `*_API_KEY`, `*_TOKEN`, `AWS_*`, `GOOGLE_*`, `OPENAI_*`, `ANTHROPIC_*` and the providers' key variables), never `PATH`, `HOME` or the like. A project's `[env]` is ignored.

## Back up and move

```sh
aurelion backup                          # config, skills, memory and sessions, to a .tar.gz here
aurelion backup out.tar.gz --no-sessions
aurelion backup out.tar.gz --include-secrets
aurelion restore out.tar.gz              # refuses to overwrite; --force does
```

The archive holds `config.toml`, with any key written in it, and only you can read it. The credential stores are left out unless you pass `--include-secrets`: sign-ins, `connections.json`, the license, `config.key`, a device node's key, plugins' private data and the X refresh token. A restore refuses absolute paths, `..` and anything outside the archive's own folders.

**Next:** [Troubleshooting](troubleshooting.md)
