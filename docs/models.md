# Models and providers

AURELION works with the model you choose: 84 providers out of the box, from the big labs to gateways, cloud platforms and models on your own machine. Your Claude, ChatGPT or Copilot plan works too. You can switch models mid-session, keep several providers connected, fall back to another model when one is busy, and give side jobs a cheaper model.

## Providers

```sh
aurelion providers    # every provider, the key variable each reads, and which keys you have set
aurelion models       # the models your current provider offers
```

They come in five groups:

| Group | Examples |
| --- | --- |
| Popular | `anthropic`, `openai`, `openrouter`, `gemini`, `deepseek`, `xai`, and the subscription providers below |
| Model labs | `zai`, `kimi`, `minimax`, `qwen`, `groq`, `mistral`, `cerebras`, `perplexity`, `cohere`, … |
| Gateways and hosts | `ai-gateway`, `huggingface`, `opencode-zen`, `fireworks`, `together`, `deepinfra`, `nvidia`, `ollama-cloud`, … |
| Local | `ollama`, `lmstudio`, `vllm`, `llamacpp`, `sglang`, `litellm`, `llama-managed`, `apple-fm`, … |
| Cloud platforms | `bedrock`, `vertex`, `anthropic-vertex`, `azure`, `azure-foundry`, `cloudflare`, `copilot`, … |

Pick one in the setup wizard, with `/provider` in a session, or in your config:

```toml
# ~/.config/aurelion/config.toml
provider = "openrouter"
model = "anthropic/claude-sonnet-4.5"
```

## Switch models

`/model` alone opens the picker. It lists the models of every provider you have connected, grouped by provider, with each one's context window and its price per million tokens in and out. Type to filter by model, provider, or `free` and `paid`.

Or switch directly:

```text
/model claude-sonnet-4-5              # a model on the current provider
/model deepseek:deepseek-chat         # provider and model together
```

The choice is saved as your default. For one run without touching the config, pass flags:

```sh
aurelion --provider ollama --model qwen3-coder
aurelion -p "explain this repo" --model claude-haiku-4-5
```

`--base-url` and `--api-key` work the same way. Each session also remembers the model it ran on: when you resume it, AURELION switches back to that model for the session, without changing your default.

## Connect more providers

`/provider` (or `/connect`) connects another provider in a session: pick it, paste its key, pick a model. Its models then show up in `/model`.

```text
/provider                 # connect one
/provider list            # the connected providers
/provider remove groq     # forget one
```

Keys you connect this way are kept in `connections.json` beside your config, readable only by you. A provider also counts as connected when its usual key variable is set in your environment.

## Claude plans: two ways

A Claude Pro or Max plan runs only through the official Claude Code CLI. Install it, log in with `claude` once, then pick one of two providers:

| Provider | How it works |
| --- | --- |
| `claude-subscription` | Claude is the model; AURELION runs the tools, the approvals and the sandbox. Each model call goes through your installed `claude` with its own tools off. `aurelion connect claude` sets this up. |
| `claude-cli` | Each turn goes to Claude Code, which runs its own tools. AURELION shows its tool calls as cards, and your mode reaches it as its own permission mode (see [Modes and safety](modes-and-safety.md#under-claude-code)). |

Either way, usage counts against your Claude plan, and the cost AURELION shows is never capped. A few details:

- Claude Code bills your login, not an exported key or endpoint. So AURELION doesn't pass it `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_BASE_URL`. Under `claude-subscription` it also holds back `ANTHROPIC_FOUNDRY_API_KEY`, `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX` and `CLAUDE_CODE_USE_FOUNDRY`. `AURELION_CLAUDE_KEEP_AUTH_ENV=1` passes them all, for a gateway Claude Code is meant to use.
- Under `claude-cli`, Claude Code runs commands of its own, so it starts without the keys AURELION holds for other providers and its integrations, as [the shell](modes-and-safety.md#the-shell) does. Claude Code's own variables (`CLAUDE_*` and the other `ANTHROPIC_*`), `AWS_BEARER_TOKEN_BEDROCK` and your AWS and Google Cloud credentials pass. So `CLAUDE_CODE_USE_BEDROCK=1` or `CLAUDE_CODE_USE_VERTEX=1` still sends it to Bedrock or Vertex.
- Under `claude-cli`, each AURELION session keeps one Claude Code session and resumes it every turn. After a rewind, a branch, a compaction or a turn on another provider, it starts a fresh one, carrying the session's key facts. `claude_cli_resume = false` sends the whole conversation every turn instead.
- Subagents, `/review`, `/swarm` and cron jobs never run as Claude Code: they run on `claude-subscription` with the same model.
- Side jobs (titles, memory, key facts, summaries) run on Haiku through your plan, unless you set `model_small`.
- A `claude-subscription` call that goes quiet for 120 seconds is stopped. `[claude] silence_secs` changes that, between 30 and 3600.
- `/usage` inside `claude` shows your plan's usage.

`provider = "anthropic"` is different: it takes a Console API key (`ANTHROPIC_API_KEY`) and refuses subscription tokens.

## Other plans and agent CLIs

```sh
aurelion connect codex      # openai-codex: your ChatGPT plan, signed in with a device code
aurelion connect copilot    # copilot: your GitHub Copilot plan
```

`/usage` shows a ChatGPT plan's real quota.

`codex-cli` and `gemini-cli` hand each turn to your installed `codex` or `gemini`, on their own login. `qwen-oauth` reuses your Qwen CLI login. Under any of these agent CLIs, one AURELION request is a whole run of the other tool, so `--max-turns` counts AURELION's requests, not the turns inside each one.

## API keys

Each provider reads its own variable (`DEEPSEEK_API_KEY`, `OPENROUTER_API_KEY`, …). You can also set a key in the config:

```toml
api_key = "sk-…"                    # or a reference, see below
api_keys = ["$KEY_ONE", "$KEY_TWO"] # a pool: a rate-limited key cools down, a rejected one is retired
```

Rather than a key in plain text, `api_key` can name where the key lives: `op://` (1Password), `vault://`, `bw://` (Bitwarden) or `keychain://`. `aurelion secrets check` tests that they resolve.

`AURELION_API_KEY` and `AURELION_BASE_URL` override the key and endpoint, but stay with the provider they were first used with. When you switch to another provider, it gets its own key and endpoint, never these.

## Cloud platforms

The cloud providers sign in with your cloud account rather than one API key. `aurelion providers` lists every provider with what it needs, with a `✓` beside what it finds.

- **`bedrock`** takes a Bedrock API key in `AWS_BEARER_TOKEN_BEDROCK`. Without one, it signs each request with your AWS credentials: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (with `AWS_SESSION_TOKEN` for temporary ones), else the `AWS_PROFILE` profile (`default` when unset) of your AWS config and credentials files. A profile can hold static keys, a `credential_process`, an IAM Identity Center (SSO) login or a `role_arn` to assume. The region is `AWS_REGION` or `AWS_DEFAULT_REGION`, else `us-east-1`.
- **`vertex`** (Gemini and other models) and **`anthropic-vertex`** (Claude) take a Google access token in `GOOGLE_OAUTH_ACCESS_TOKEN`. Without one, they use the credentials file `GOOGLE_APPLICATION_CREDENTIALS` names, else gcloud's application default credentials (`gcloud auth application-default login`): a service account key, your user login or workload identity federation. Last, they ask `gcloud auth print-access-token`, and on a Google Cloud machine, its metadata server.
  - The project is `GOOGLE_CLOUD_PROJECT`, `VERTEX_PROJECT` or `GCLOUD_PROJECT`, else the one in the credentials file.
  - The region is `VERTEX_LOCATION` or `GOOGLE_CLOUD_LOCATION`, else `us-central1`. For Claude, `CLOUD_ML_REGION` comes first, and the default is `us-east5`.
- **`cloudflare`** (Workers AI) needs `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`. **`cloudflare-ai-gateway`** needs `CLOUDFLARE_AI_GATEWAY_API_KEY`, `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_GATEWAY_ID`.

## Custom endpoints and local models

Any OpenAI-compatible, Responses or Anthropic-compatible endpoint works:

```toml
provider = "custom"
base_url = "https://llm.example.com/v1"
protocol = "chat"          # chat | responses | anthropic
model = "my-model"
```

`base_url` also overrides a preset's endpoint, for a proxy or a self-hosted copy.

Local servers need no key:

```toml
provider = "ollama"        # or lmstudio, vllm, llamacpp, sglang
model = "qwen3-coder"
```

- `llama-managed` runs `llama-server` for you. Set `model` to the path of a `.gguf` file, or set `AURELION_LLAMA_MODEL_PATH`.
- `apple-fm` uses the on-device Apple Foundation Models, on macOS 26 or later.

## The small, vision and judge models

Side work doesn't need your biggest model:

```toml
model = "claude-opus-4-5"
model_small = "claude-haiku-4-5"     # compaction, memory, titles and other side jobs
decision_model = "claude-haiku-4-5"  # the judge behind the decision_evaluate tool
```

- `model_small` (or `--small-model` for one run) takes compaction, memory extraction and other background work.
- `vision_model` names a model on the same provider that can see. It describes images (a `read` of an image, a browser screenshot) when the main model takes only text. Unset, the small model does it if it can see.
- The Model tab in the rail names the lead, workers', small, fallback and vision models in use.

With `[routing] mode = "auto"` and a small model set, a short conversational turn starts on the small model. Once the turn calls a tool, the main model takes over.

```toml
[routing]
mode = "auto"
max_simple_chars = 160   # the longest prompt still counted as simple
```

## When a model is busy

A rate limit, a server error or a broken stream is retried with backoff, and each retry is announced with a `⟳` notice. If the retries run out, AURELION moves down your fallback chain:

```toml
fallback = ["claude-haiku-4-5", "claude-sonnet-4-5"]
```

The fallbacks are tried in order. The main model comes back when its cooldown ends. The Model tab shows the last fallback taken.

A context overflow is never retried blindly: AURELION compacts the conversation and replays the turn.

## Thinking and effort

```text
/thinking high     # off, low, medium, high or xhigh; from the next turn
```

`effort = "medium"` in the config sets the default. `Ctrl+T` expands the thinking in the stream, and `F3` shows it on its own.

## Cost and caching

- `/tokens` (or `/cost`) shows this session's tokens and cost. The status row shows the spend as it grows.
- `/usage` shows your account's real usage where the provider reports it.
- `prompt_cache = true` (the default) uses Anthropic prompt caching, and `cache_ttl = "1h"` keeps the cache an hour instead of five minutes.
- `service_tier` asks for a provider's processing tier: `auto`, `default`, `flex` or `priority` on OpenAI, `auto` or `standard_only` on Anthropic.
- `max_tokens = 0` (the default) gives the model its full output limit.

[Modes and safety](modes-and-safety.md#spend-caps) shows how to cap spend.

## Mixture of agents

A Mixture-of-Agents preset has reference models advise one acting model:

```toml
[moa]
default_preset = "default"

[moa.presets.default]
references = ["openai/gpt-5.5", "openrouter/deepseek/deepseek-v4-pro"]
aggregator = "anthropic/claude-opus-4-8"
fanout = "user_turn"   # or "per_iteration": consult them on every model call
```

`/model moa:default` makes the preset your model. `/moa <prompt>` runs one turn on the default preset.

## Identity and personality

`~/.config/aurelion/SOUL.md` replaces the agent's identity line, for every project. Only your config folder is read: a repository can't change who the agent is.

`/personality <name>` sets a tone for the session: `concise`, `helpful`, `technical`, `creative`, `teacher`, `reviewer`, `philosopher`, `hype`, or for fun `pirate`, `shakespeare` and `noir`. Add your own as `~/.config/aurelion/personalities/<name>.md`. `/personality none` removes it.

## Profiles

A profile is a named set of overrides for any top-level setting. Switch between them per run:

```toml
model = "claude-opus-4-5"

[profiles.cheap]
model = "claude-haiku-4-5"
effort = "low"

[profiles.local]
provider = "ollama"
model = "qwen3-coder"
[profiles.local.tools]
timeout_secs = 300
```

```sh
aurelion --profile cheap       # or AURELION_PROFILE=cheap; the flag wins
aurelion profiles              # list them, the active one marked with *
```

A profile merges over the file: nested tables merge key by key, and any other value is replaced. An unknown name is an error that lists the profiles you have. Each profile also keeps its own user memory; see [Memory and context](memory-and-context.md).

**Next:** [Tools](tools.md)
