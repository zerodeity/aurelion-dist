# Serve and chat

`aurelion serve` is AURELION without a screen: a daemon that runs your scheduled jobs and the kanban board, answers you in the chat apps you already use, takes signed webhooks, reports what it does to your own endpoints, and can even answer the phone. Two more servers let other software use AURELION: an OpenAI-compatible API and an Agent2Agent endpoint. This page covers all three.

## Start the daemon

Start it in the folder it should work in:

```sh
cd ~/code/my-project
aurelion serve             # cron, kanban, and every chat whose keys are set
aurelion serve --status    # ask the running daemon how it is doing
aurelion serve --stop      # stop it
```

The daemon:

- runs the folder's [cron jobs](automation.md#scheduled-jobs), so the app open in the same folder leaves them to it. `--no-cron` leaves cron to the app instead;
- runs the [kanban](automation.md#kanban) dispatcher, unless `[kanban] dispatch_in_serve = false`;
- answers the chat platforms you configured, below;
- runs `BOOT.md` once at startup, unless `--no-boot`.

One `aurelion serve` runs per user. `--profile <name>` runs it under a [profile](models.md#profiles). After you update AURELION, restart the daemon.

### What a serve turn may do

Every turn the daemon runs (a chat message, a webhook, `BOOT.md`) is a headless agent turn in the daemon's folder, with AURELION's built-in tools. Your MCP servers and plugins' tools are not part of it, since a serve turn faces the network.

A call that needs approval waits for the person who started the turn in a chat (see [Approvals in a chat](#approvals-in-a-chat)). Anywhere else, it is denied. The after-turn checks don't run here.

### Run it as a service

```sh
aurelion service install                          # in this folder, as a launchd or systemd user service
aurelion service install --workdir ~/code/app -- --telegram --no-boot
aurelion service status
aurelion service logs
aurelion service uninstall
```

`--dry-run` prints the service file without writing or starting anything. Arguments after `--` go to `aurelion serve`.

The daemon watches itself. It rewrites a `serve.heartbeat` file in the data folder every 30 seconds (`[serve] heartbeat_secs`), and `aurelion serve --status` falls back to that file when the daemon doesn't answer within 5 seconds. A daemon that stops responding writes a dump to `serve-watchdog.log` and exits with code 75, so the service manager restarts it. `[serve] watchdog = false` turns that off, and `kill -USR2 <pid>` writes the same dump on demand.

## Chat platforms

Each platform starts when its flag is given and its keys are set. Slack and Discord also start on their own when their tokens are in the environment. Nobody can talk to the bot until they are on the platform's allow list. ntfy has no sender identity, so there you acknowledge that the topic name is the only secret.

| Platform | Flag | What it needs | Who may talk |
| --- | --- | --- | --- |
| Telegram | `--telegram` | `AURELION_TELEGRAM_TOKEN` | A chat that pairs (below), or chat ids in `AURELION_TELEGRAM_ALLOW`. |
| Slack | `--slack` | `SLACK_APP_TOKEN` (`xapp-`) and `SLACK_BOT_TOKEN` (`xoxb-`), for Socket Mode | `SLACK_ALLOWED_USERS` |
| Discord | `--discord` | `DISCORD_BOT_TOKEN` | `DISCORD_ALLOWED_USERS` |
| Matrix | `--matrix` | `AURELION_MATRIX_HOMESERVER`, `AURELION_MATRIX_TOKEN` | `AURELION_MATRIX_ALLOW` (senders and inviters) |
| Mattermost | `--mattermost` | `AURELION_MATTERMOST_URL`, `AURELION_MATTERMOST_TOKEN` | `AURELION_MATTERMOST_ALLOW` |
| IRC | `--irc` | `AURELION_IRC_SERVER` (`host:port`; port 6697 when none is given), `AURELION_IRC_NICK`, `AURELION_IRC_CHANNELS`, and `AURELION_IRC_PASSWORD` for SASL. The connection uses TLS; `AURELION_IRC_TLS=0` makes it plain (port 6667 by default). | `AURELION_IRC_ALLOW` (nicks) |
| Signal | `--signal` | A signal-cli HTTP daemon at `AURELION_SIGNAL_URL` (default `http://127.0.0.1:8080`), and `AURELION_SIGNAL_ACCOUNT` | `AURELION_SIGNAL_ALLOW` |
| Email | `--email` | `AURELION_EMAIL_IMAP`, `AURELION_EMAIL_SMTP` (`host:port` each), `AURELION_EMAIL_USER`, `AURELION_EMAIL_PASSWORD`, `AURELION_EMAIL_FROM` | `AURELION_EMAIL_ALLOW`, and each mail must pass DMARC (below) |
| ntfy | `--ntfy` | `AURELION_NTFY_TOPIC` (use a long random name), and either `AURELION_NTFY_ALLOW=topic-is-secret` or `AURELION_NTFY_TOKEN` for a server with access control. `AURELION_NTFY_SERVER` defaults to `https://ntfy.sh`, and `AURELION_NTFY_REPLY_TOPIC` sends replies to another topic. | Anyone who knows the topic. Without the acknowledgement or a token, `--ntfy` refuses to start. |
| Twitch | `--twitch` | `AURELION_TWITCH_TOKEN`, `AURELION_TWITCH_NICK`, `AURELION_TWITCH_CHANNELS`. It answers @mentions and `!ask`. | `AURELION_TWITCH_ALLOW` |
| X | `--x` | `AURELION_X_USER_TOKEN`, or `AURELION_X_CLIENT_ID` and `AURELION_X_REFRESH_TOKEN`. Mentions and direct messages. | `AURELION_X_ALLOW` |
| Nostr | `--nostr` | `AURELION_NOSTR_NSEC`, `AURELION_NOSTR_RELAYS`. Direct messages. | `AURELION_NOSTR_ALLOW` (public keys) |

```sh
export SLACK_APP_TOKEN=xapp-… SLACK_BOT_TOKEN=xoxb-… SLACK_ALLOWED_USERS=U0123ABCD
aurelion serve
```

**IRC nicks are not proven.** Anyone can take a nick unless the network enforces registration, so prefer SASL and a channel only registered users may join.

**Telegram pairing.** When a chat you haven't allowed writes to the bot, the daemon prints a six-digit code on its own output. Send `/pair <code>` from that chat to pair it. A code lasts 10 minutes and works once, and five wrong tries burn it and hold off new codes for another 10 minutes.

**Email** must pass DMARC (or aligned DKIM or SPF), as the receiving server's `Authentication-Results` header reports it. `AURELION_EMAIL_AUTHSERV_ID` names which server's header counts. `AURELION_EMAIL_AUTH=off` goes back to trusting the From address alone, for an inbox whose server adds no such header.

### Platforms that call in

Some platforms deliver messages to a web address instead. `--hooks` opens one listener for them, and `--hooks-platforms` picks which:

```sh
aurelion serve --hooks 8788 --hooks-platforms whatsapp,teams,line
```

Each platform gets its own path, such as `/whatsapp`, and reads its own variables:

| Platform | What it needs | Who may talk |
| --- | --- | --- |
| `whatsapp` (WhatsApp Cloud API) | `AURELION_WHATSAPP_TOKEN`, `AURELION_WHATSAPP_PHONE_ID`, `AURELION_WHATSAPP_APP_SECRET`, `AURELION_WHATSAPP_VERIFY_TOKEN` | `AURELION_WHATSAPP_ALLOW` |
| `teams` (Microsoft Teams bot) | `AURELION_TEAMS_APP_ID`, `AURELION_TEAMS_APP_PASSWORD`, optionally `AURELION_TEAMS_TENANT` | `AURELION_TEAMS_ALLOW` |
| `gchat` (Google Chat app) | `AURELION_GCHAT_PROJECT_NUMBER` (or `AURELION_GCHAT_AUDIENCE`), and a service account key in `AURELION_GCHAT_SERVICE_ACCOUNT` or `GOOGLE_APPLICATION_CREDENTIALS` (or a command in `AURELION_GCHAT_TOKEN_COMMAND`) | `AURELION_GCHAT_ALLOW` |
| `twilio` (SMS) | `AURELION_TWILIO_ACCOUNT_SID`, `AURELION_TWILIO_AUTH_TOKEN`, `AURELION_TWILIO_FROM`, `AURELION_TWILIO_PUBLIC_URL` | `AURELION_TWILIO_ALLOW` (numbers) |
| `feishu` (Feishu or Lark) | `AURELION_FEISHU_APP_ID`, `AURELION_FEISHU_APP_SECRET`, `AURELION_FEISHU_VERIFICATION_TOKEN`, optionally `AURELION_FEISHU_ENCRYPT_KEY` and `AURELION_FEISHU_DOMAIN` | `AURELION_FEISHU_ALLOW` |
| `line` | `AURELION_LINE_CHANNEL_SECRET`, `AURELION_LINE_TOKEN` | `AURELION_LINE_ALLOW` |
| `msgraph` (Teams chats through Microsoft Graph) | `AURELION_MSGRAPH_TENANT_ID`, `AURELION_MSGRAPH_CLIENT_ID`, `AURELION_MSGRAPH_CLIENT_SECRET`, `AURELION_MSGRAPH_CLIENT_STATE` | `AURELION_MSGRAPH_ALLOW` |
| `bluebubbles` (iMessage) | `AURELION_BLUEBUBBLES_URL`, `AURELION_BLUEBUBBLES_PASSWORD`, and best a separate `AURELION_BLUEBUBBLES_WEBHOOK_SECRET` | `AURELION_BLUEBUBBLES_ALLOW` |
| `nextcloud` (Nextcloud Talk) | `AURELION_NEXTCLOUD_URL`, `AURELION_NEXTCLOUD_SECRET` | `AURELION_NEXTCLOUD_ALLOW` |
| `synology` (Synology Chat) | `AURELION_SYNOLOGY_TOKEN`, `AURELION_SYNOLOGY_INCOMING_URL` | `AURELION_SYNOLOGY_ALLOW` |
| `gmail` (through Pub/Sub push) | `AURELION_GMAIL_CLIENT_ID`, `AURELION_GMAIL_CLIENT_SECRET`, `AURELION_GMAIL_REFRESH_TOKEN`, and `AURELION_GMAIL_PUSH_AUDIENCE` or `AURELION_GMAIL_PUSH_TOKEN` | `AURELION_GMAIL_ALLOW` (senders) |

Every request is checked against the platform's own signature or token before anything else happens. The listener binds to `127.0.0.1` unless you give a host, so put it behind your reverse proxy or tunnel. In LINE groups, and in Teams group chats and channels through Microsoft Graph, only messages that mention the bot count.

For Teams and Google Chat, a shared secret in an `X-Aurelion-Secret` header can stand in for the platform's own signed token, but only when you opt in with `AURELION_TEAMS_INSECURE_SHARED_SECRET=1` or `AURELION_GCHAT_INSECURE_SHARED_SECRET=1`. A `?secret=` in the address also needs `AURELION_HOOKS_SECRET_IN_URL=1`, since proxies log addresses.

Chat plugins you enable connect on their own, see [Tools](tools.md#plugins).

## In a chat

Send a message and AURELION runs a turn in that chat's own session. One turn runs per chat at a time. A few commands control it, written with `/` or `!` (Slack keeps `/` for its own commands):

| Command | What it does |
| --- | --- |
| `/new` | Start a fresh session for this chat. Also `/reset`. |
| `/stop` | Stop the running turn. Also `/cancel`. |
| `/status` | What is going on. |
| `/help` | The commands. |
| `/approve [N]` · `/deny [N]` | Answer an approval. |
| `/sethome` | Make this chat where scheduled jobs post. `/sethome show` and `/sethome clear`. |
| `/kanban …` | Drive the [kanban board](automation.md#kanban). `/kanban subscribe [N]` posts its events here. |
| `/blueprint …` · `/suggestions …` | Set up [ready-made automations](automation.md#blueprints-and-suggestions). |

Replies stream into one message that grows as the text arrives, on Slack, Mattermost, Telegram, Discord, Matrix, Feishu, Teams and Google Chat. `[serve] live_edits = false` sends each reply whole. A running `aurelion serve` shows its chats in the cockpit's Jobs tab.

### Approvals in a chat

When a tool needs approval, the chat shows `Approval needed (#N)`. Only the person whose message started the turn can answer, with `/approve N` or `/deny N`. Discord, LINE and WhatsApp show buttons for it, and Slack and Telegram use their own. An unanswered approval is denied after 5 minutes:

```toml
[serve]
approval_timeout_secs = 300
```

### Files

A reply can send files. When it writes `MEDIA:<path>`, or names the absolute path of a document, image, audio, video, data or archive file, that file goes to the chat as an attachment. This works on Telegram, Discord, Slack, Matrix, Mattermost, Signal, email, ntfy, WhatsApp, Feishu, BlueBubbles, Gmail and chat plugins that support files. Credential files and system paths are never sent.

```toml
[serve]
attach_paths = false              # only MEDIA: tags send files, not plain paths
media_strict = true               # only files in the folder, temp folders, media_allow_dirs, or written in the last 30 minutes
media_allow_dirs = ["~/reports"]
```

`media_strict` is for bots in shared chats, where someone could try to talk the agent into sending your files.

### Tools only chats have

In a chat turn, the agent also has `send_message`, `react`, `edit_message` and `delete_message`. `send_message` posts to the sender's own chats, plus the chats you list:

```toml
[serve]
message_targets = ["slack:C0123*", "telegram:-100123456"]

[serve.discord]
admin_actions = ["create_thread", "pin"]   # turns on discord_admin, with these actions only
```

`discord_admin` can create threads and channels, pin and unpin, add and remove roles, and time members out. It is off until `admin_actions` lists what it may do.

### Who may run what

Beyond the allow lists, a sender policy can narrow the tools a sender's turns may use. Put it in `chat-policy.toml` in the data folder, or name the file with `AURELION_CHAT_TOOL_POLICY`:

```toml
[[rule]]
platform = "slack"                  # a glob; "*" is the default
user = "U01*"                       # a glob over the platform's user id
allow = ["read", "grep", "glob"]    # only these tools
deny = ["bash"]
read_only = true                    # no tool that changes anything
```

The last rule that matches wins.

### Routes

A route gives some chats an agent setup of their own: a model, a folder, extra instructions or fewer tools.

```toml
[[serve.route]]
name = "support"
channel = "slack"                 # the platform, or "*"
chat = "C0SUPPORT*"               # a glob over the chat
model = "claude-haiku-4-5"
workdir = "/srv/helpdesk"
system_prompt_append = "Answer as the support bot. Never change files."
tools = ["read", "grep", "websearch"]
```

A route can also match on `account` (the bot or workspace) and `sender`, and set a `memory_scope` that keeps its sessions apart. Every field a route sets must match. The most specific route wins (sender, then chat, then account, then platform), and on a tie the first one. A route's `tools` can only narrow the sender policy, never widen it.

With `notify_telegram = true` and `--telegram`, the paired Telegram chat also hears when a cron job, a webhook job, or a chat turn longer than a minute finishes.

## BOOT.md

`~/.config/aurelion/BOOT.md` is a startup checklist in plain words, such as "check last night's cron failures and tell me which". The daemon runs it once each time it starts, as a headless turn. The answer goes to `[serve] boot_deliver` (any [delivery target](automation.md#where-results-go)), else to every home channel, else to the log. An answer of `[silent]` goes nowhere. `--no-boot`, or deleting the file, stops it.

```toml
[serve]
boot_deliver = "telegram"
```

## Gateway hooks

A folder under `~/.config/aurelion/hooks/` is a hook the daemon loads at startup:

```text
~/.config/aurelion/hooks/deploy-alert/
├── HOOK.yaml     # name, description, events: [turn.failed, "kanban.*", gateway.startup], timeout: 30
└── handler.sh    # or handler.py, or an executable named handler
```

For each event it subscribes to, the handler runs in the background:

- the event's JSON is on stdin: `id`, `event`, `session`, `platform`, `summary`, `usage` and `ts`;
- `AURELION_HOOK_EVENT` and `AURELION_HOOK_NAME` are set, and AURELION's own keys are not;
- it has a time limit, and a failure is logged without holding anything up.

The events are `gateway.startup` (its summary names the connected platforms), `gateway.shutdown`, `turn.started`, `turn.completed`, `turn.failed`, `cron.fired`, `cron.completed`, `cron.failed`, `kanban.<kind>`, `boot.completed` and `boot.failed`. `*` is a wildcard. Hermes's names (`gateway:startup`, `agent:start`, `agent:end`) work too.

Placing the folder is the opt-in. Only your config folder is read, never a project's, so a repository can't add a hook. Read a handler before you place it, as you would any program.

## Webhooks in

`--webhook` lets other systems start a turn:

```sh
export AURELION_WEBHOOK_SECRET=…
aurelion serve --webhook 8790          # or host:port; the host defaults to 127.0.0.1
```

A request is `POST /hook/<name>` with two headers:

```text
X-Aurelion-Timestamp: <unix seconds>
X-Aurelion-Signature: v2=<hex HMAC-SHA256 of "<timestamp>.<name>.<body>", keyed with the secret>
```

A request that is unsigned, badly signed, more than 5 minutes off, or a replay of one already accepted gets `401`. The old body-only `sha256=` signature is refused unless `AURELION_WEBHOOK_LEGACY_SIGNATURE=1`, since it can be replayed.

The prompt is the body's JSON `prompt` field, or the raw body. `--webhook-template` wraps it in a prompt of your own, where the body takes the place of the placeholder:

```sh
aurelion serve --webhook 8790 --webhook-template 'A deploy event arrived: {{body}}. Check the service.'
```

`AURELION_NOTIFY_URL` gets a JSON POST each time a cron or webhook job finishes.

## Events out

`--event-webhook <url>` (repeatable, or a comma list in `AURELION_EVENT_WEBHOOKS`) posts every turn and cron event to your own endpoint as JSON. Each delivery has 5 seconds and 3 retries, and never holds up a turn.

With `AURELION_EVENT_WEBHOOK_SECRET` set, each delivery is signed:

```text
X-Aurelion-Timestamp: <unix seconds>
X-Aurelion-Signature-V2: v2=<hex HMAC-SHA256 of "<timestamp>.<body>">
X-Aurelion-Signature: sha256=<hex HMAC-SHA256 of the body>
```

Check the `v2` header, refuse a timestamp far from your clock, and remember each event's `id` to drop repeats. The older `sha256=` header is there for existing receivers, but it doesn't stop a replay.

## Metrics

The webhook port and `aurelion api` both answer `GET /metrics` in the Prometheus format, behind a bearer key. On the webhook port the key is `AURELION_METRICS_KEY`, else `AURELION_API_SERVER_KEY`, and with neither set the endpoint stays closed. On `aurelion api` it is the server's own key. `AURELION_METRICS_PUBLIC=1` opens both without a key.

## Phone calls

`--voice-call` answers phone calls through Twilio Media Streams. A caller talks to a realtime voice model, which can use the agent's read-only tools and ask the agent for more.

```sh
export AURELION_TWILIO_AUTH_TOKEN=… OPENAI_API_KEY=…
export AURELION_VOICE_CALL_PUBLIC_URL=https://voice.example.com
export AURELION_VOICE_CALL_ALLOW=+15551230000        # callers, in E.164 form, comma-separated
export AURELION_VOICE_CALL_PIN=482913                 # 4 digits or more
aurelion serve --voice-call 8791
```

- Point your Twilio number's voice webhook at `/voice/incoming` on the public address.
- `AURELION_VOICE_CALL_BACKEND=gemini` uses Gemini Live (with `GEMINI_API_KEY` or `GOOGLE_API_KEY`) instead of OpenAI Realtime. `AURELION_VOICE_CALL_VOICE` picks the voice.
- Caller ID can be faked, so a listener that isn't on a loopback address needs the PIN, and won't start without one.

Calls need no microphone on your machine, so they work in every build. Talking to AURELION through your own microphone, with `aurelion talk`, needs a build with voice support; see [Editors and devices](editors-and-devices.md#voice).

## The OpenAI-compatible API

`aurelion api` serves AURELION as an OpenAI-compatible endpoint, so any tool that speaks that API can use it. Each request runs one full agent turn in the folder you started it in.

```sh
export AURELION_API_SERVER_KEY=…
aurelion api                          # 127.0.0.1:8642
aurelion api --bind 0.0.0.0 --port 9000
```

```sh
curl http://127.0.0.1:8642/v1/chat/completions \
  -H "Authorization: Bearer $AURELION_API_SERVER_KEY" -H "Content-Type: application/json" \
  -d '{"model": "aurelion", "messages": [{"role": "user", "content": "List the TODOs in this repo."}]}'
```

- `GET /v1/models` lists `aurelion` and `aurelion:<your model>`. `"model": "aurelion:<id>"` runs a request on another model.
- The system and earlier messages become the session's history, and the last user message is the prompt. `"stream": true` streams the answer.
- Turns use the built-in tools. A call that needs approval is denied, and the model carries on. `--yolo` allows every call. Your config's own `yolo` never applies here.
- The key comes from `AURELION_API_SERVER_KEY` or `[api] api_key`. Without one, the server binds only to loopback.

```toml
[api]
bind = "127.0.0.1"
port = 8642
api_key = "a-long-random-key"   # AURELION_API_SERVER_KEY wins over it
```

## Agent2Agent

`aurelion a2a` speaks the Agent2Agent protocol, so other agents can call this one, and this one can call them.

```sh
export AURELION_A2A_TOKEN=…
aurelion a2a serve                                     # 127.0.0.1:8643
aurelion a2a serve --addr 0.0.0.0:8643 --public-url https://agent.example.com/
aurelion a2a card                                      # print this agent's card
aurelion a2a call https://agent.example.com/ "Summarize the open issues"
```

- The agent card is at `/.well-known/agent-card.json`.
- Turns use the built-in tools, with approvals denied. Each conversation keeps one session.
- Callers need the bearer token. `--insecure-local` runs without one, on a loopback address only.
- `a2a call` takes `--token` (default `AURELION_A2A_TOKEN`) and `--context-id` to continue a conversation.

In a session, the agent calls remote agents with the `a2a_call` tool, from the peers you name in `AURELION_A2A_PEERS=name=url,…`. It asks before each call.

**Next:** [Editors and devices](editors-and-devices.md)
