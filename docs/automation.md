# Automation

AURELION doesn't need you at the keyboard. Run one prompt from a script or a CI job, run a file of prompts in parallel, schedule jobs that report to a chat, hand a board of cards to worker agents, and hook your own programs into every step. This page covers each, from the shell and from the cockpit.

## One prompt from the shell

`-p` runs one prompt with no interface, prints the answer and exits:

```sh
aurelion -p "explain this repo"
aurelion -p summarize the open TODOs           # the words are the prompt
aurelion -p - < task.md                        # the prompt from stdin
```

A run in `-p`:

- has your full toolset: the built-in tools, your MCP servers, language servers and plugins. It has no subagents.
- can't show an approval card. A call that would ask is denied, and the run prints one line that says why it asked and, where there is one, the flag that would allow it. `--yolo` allows every call; use it only where that is safe.
- doesn't run the after-turn checks, and never looks for updates.

Options for one run:

```sh
aurelion -p "fix the failing test" --max-turns 20    # stop after 20 model requests
aurelion -p "fix the failing test" --max-spend 2     # stop once the run has cost $2
aurelion -p "plan the refactor" --plan               # plan mode: read and plan only
aurelion -p "list the endpoints" --json-schema schema.json   # the answer as JSON matching the schema
aurelion -p "triage" --model claude-haiku-4-5 --profile ci -s gh-issues
```

`--json-schema` takes a file or inline JSON. After the turn, the final answer is asked for as JSON that matches it, and only that JSON is printed. An answer that isn't valid JSON, or breaks the schema, fails the run.

With an agent CLI as the provider (`claude-cli`, `codex-cli`, `gemini-cli`), one request is a whole run of that tool, so `--max-turns` counts AURELION's requests, not the turns the other tool takes inside each one.

### JSON output

`--output-format json` prints one JSON object when the run ends. The streamed answer and the progress go to stderr instead.

```sh
aurelion -p "fix the failing test" --output-format json
```

```json
{
  "session_id": "01a17741-…",
  "result": "Fixed the off-by-one in pager.go; go test ./... passes.",
  "stop_reason": "completed",
  "turns": 7,
  "cost_usd": 0.0412,
  "input_tokens": 48210,
  "output_tokens": 1893,
  "exit_code": 0
}
```

- `result` is the answer: the text after the last tool call.
- `stop_reason` is `completed`, `max_turns`, `aborted` or `error`. A `--json-schema` answer that fails is an `error`.
- `turns` counts the model requests sent.
- A run that fails before it starts, such as an empty prompt from stdin, a bad schema or a `--resume` session that isn't there, prints no JSON object, only the error on stderr.

`exit_code` and the process's own exit code are what count.

### Exit codes

`aurelion -p` and `aurelion batch` exit with:

| Code | Meaning |
| --- | --- |
| `0` | Success. |
| `1` | The run failed: an error, a turn that didn't finish (the spend cap, `--max-turns`), or a batch item that didn't pass. |
| `2` | A usage error: a bad flag or value, such as `--max-spend 0`. |
| `3` | AURELION is locked: this machine has no valid license (`aurelion activate <key>`). |

### In CI

A CI runner is a machine like any other: activate it once with `aurelion activate <key>`, and give it the provider key in an environment variable. A step then looks like this:

```sh
aurelion -p "Read the failing test output in ci.log and fix the cause." \
  --max-turns 30 --max-spend 3 --output-format json > aurelion.json
```

Give a CI run a spend cap and a turn limit, and keep `--yolo` for runners you can throw away. [Modes and safety](modes-and-safety.md) covers the rules and the sandbox that still apply.

## Batch runs

`aurelion batch` runs one headless agent per line of a JSONL file:

```text
{"id": "fix-1", "prompt": "Fix the failing test in pager_test.go.", "check": "go test ./..."}
{"id": "docs-2", "prompt": "Document the exported functions.", "cwd": "/srv/app", "model": "claude-haiku-4-5"}
```

```sh
aurelion batch prompts.jsonl --concurrency 4 --timeout 900 --max-spend 1 --out runs/today
```

Each line has a `prompt` and may have:

| Field | What it does |
| --- | --- |
| `id` | The item's name. Ids must be unique, since a resumed run goes by them. |
| `cwd` | The folder the item runs in. |
| `model` | Another model for this item. |
| `setup` | A shell command run before the turn. |
| `check` | A shell command run after the turn. A failing check fails the item. |
| `snapshot` | A git commit to run in: a fresh folder with that commit's files and no history. It is trusted for the item only when its source folder is. |
| `grade` | A shell command run after the turn whatever its outcome. Its exit decides whether the item passed. |

Blank lines and lines starting with `#` are skipped.

- `--concurrency` runs items in parallel, `--timeout` bounds each item in seconds (its `setup` and `check` too), and `--max-spend` caps each item's cost.
- `--worktree` runs each item in its own git worktree, removed afterwards.
- Approvals are denied, as in `-p`. `--yolo` allows every call.
- The results go to `<out>/results.jsonl`, one row per item: its status (`ok`, `error`, `timeout` or `check_failed`), the final text, turns, tool calls, tokens, cost and time. The run's sessions stay in `<out>/sessions`, apart from yours.
- Run the same command with the same `--out` to resume. `--retry-failed` also runs again the items that didn't pass. The exit code counts every item, the skipped ones too.
- `--trajectories` saves each item as a ShareGPT conversation.

`aurelion batch export --sessions all -o out.jsonl --format openai` turns stored sessions into chat JSONL, `--from <out>/sessions` for a batch run's own.

## Scheduled jobs

A cron job runs a prompt on a schedule, as a headless agent turn. Its result goes to a file or a chat.

```sh
aurelion cron add nightly --schedule "every weekday at 9am" --prompt "Summarize yesterday's commits."
aurelion cron add pinger --every 300 --prompt "Check the status endpoint and say if it is down."
aurelion cron add cleanup --cron "0 3 * * SAT" --prompt "Tidy the tmp folder."
aurelion cron list            # every job, with its next run
aurelion cron run nightly     # run it now
aurelion cron off pinger      # pause it (also: pause); on or resume starts it again
aurelion cron rm pinger
```

Jobs belong to a folder, in `.aurelion/cron/jobs.json`. They run while AURELION is open in that folder, or while `aurelion serve` runs there; when both are, the serve runs them. Due jobs are checked every 20 seconds. Each run gets its own session, which you can resume, and the open app announces it.

In the cockpit, `/cron` takes the same verbs: `list`, `add`, `edit`, `run`, `pause`, `resume`, `rm` and `incidents`. The Jobs tab of the rail shows the jobs, and a failed run turns its count red. The agent can schedule a job too, with its `cronjob` tool, which asks you first.

### Schedules

`--schedule` (or `-s`) takes words or a cron expression:

- `"every weekday at 9am"`, `"every 2h"`, `"in 30m"`, `"monday, friday at noon"`, `"daily at 18:00"`;
- a cron expression such as `"0 9 * * MON-FRI"`, in local time;
- an ISO date and time, for one run.

The flags `--every <seconds>`, `--at HH:MM` (daily, local time), `--once <epoch-ms>` and `--cron "<expr>"` do the same. A job on an interval first runs at the first check after you add it. A run that crashed stays due.

### What a job runs

```sh
aurelion cron add brief -s "every weekday at 8am" --skill briefing --prompt "Brief me."
aurelion cron add disk -s "every 5m" --no-agent --script disk.sh --deliver telegram
aurelion cron add issues -s "every 15m" --script new-issues.py --prompt "Triage these."
aurelion cron add digest -s "daily at 18:00" --context-from issues --continuity --prompt "Write the digest."
```

- `--skill NAME` loads a skill before the prompt. Repeat it for several.
- `--script FILE` runs a file from `~/.config/aurelion/scripts/` first, without AURELION's own keys in its environment. Its output becomes the agent's context. A last line `{"wakeAgent": false}` skips the run without a model call.
- `--no-agent` sends the script's output as the message, with no model call. Empty output sends nothing.
- `--context-from JOB` puts that job's latest output before the prompt. Repeat it for several.
- `--continuity` gives each run the job's own previous output.
- `--agent NAME` runs the prompt with one of your [named agents](agents.md#your-own-agents).
- `--workdir`, `--model` and `--timeout` set the folder, the model and a time limit for the run.

Outputs are kept in `.aurelion/cron/output/`. `aurelion cron edit` changes a job in place: only the flags you give change, and an empty value clears `--script`, `--model` or `--deliver`.

```sh
aurelion cron edit brief -s "every 2h" --add-skill style --model ""
```

A cron run can't show an approval card, so a call that would ask is refused, and so is an unknown web host.

### Where results go

`--deliver` takes:

- a file path: the result is appended to it;
- `origin`: the chat that asked for the job (the default for jobs made in a chat);
- a platform, such as `telegram`, `slack`, `discord`, `matrix`, `mattermost`, `signal`, `email` or `ntfy`: that platform's home channel. Send `/sethome` in a chat to make it the home channel, or run `aurelion cron home set slack C0123`. `aurelion cron home` lists them;
- one chat: `slack:C0123`, `slack:C0123:<thread>`, `telegram:<chat id>`, or `chat:<plugin platform>:<channel>`;
- `all`: every home channel. A comma list sends to each target in it.

Chat platforms other than Telegram post through a running `aurelion serve`. A job that fires in the open app hands its message to the serve, which posts it within seconds. With no serve connected to that platform, the delivery fails and says what to start. Secrets in a result are masked before it leaves the machine, and files the result names are attached in chats.

`--continuable` lets someone answer in the chat a result went to: the reply gets an answer with that result in context, once, for up to a day.

### When a job fails

A job that fails the same way again alerts once, then again every `[cron] failure_repeat_alert_hours` (6 by default; `0` alerts on every failure). Numbers in the error don't make it a new failure. A different error alerts at once, and a good run re-arms the alert. Every run is still recorded.

```sh
aurelion cron incidents             # failures: alerted, resolved, closed
aurelion cron incidents --ack 3     # silence that failure for good
```

### Blueprints and suggestions

A blueprint is a ready-made job with a few blanks to fill:

```sh
aurelion cron blueprint                        # the catalog
aurelion cron blueprint show price-watch       # its blanks and defaults
aurelion cron blueprint ci-watch interval=15 branch=main deliver=slack
```

The catalog covers code chores (`repo-digest`, `ci-watch`, `pr-queue`, `todo-sweep`, `kanban-standup`, and one that checks your dependencies) and everyday ones (`morning-brief`, `weekly-review`, `disk-watch`, `custom-reminder`, `news-digest`, `price-watch`). A skill you install can add to it with a `blueprint:` block in its header (`schedule`, and optionally `deliver` and `prompt`).

`/blueprint <name>` in the app or a chat, with no values, has the agent ask you for each one, then set up the job. In a chat, the job reports back to that chat.

Suggestions are jobs offered for your yes. The agent can suggest one instead of creating it, at most five wait at once, and `catalog` offers starters that fit this folder:

```sh
aurelion cron suggestions             # what waits
aurelion cron suggestions catalog
aurelion cron suggestions accept 1    # or: dismiss 1, never offered again
```

`/suggestions` does the same in the app and in chats.

## Kanban

The kanban board holds cards that worker agents pick up on their own. A card waits in its lane until a worker is free, runs, and hands off its result to the cards that depend on it.

```sh
aurelion kanban add "research the payments API" --assignee researcher
aurelion kanban add "write the client" --assignee coder --parent 1 --contract acme/app
aurelion kanban list                  # the board, by status
aurelion kanban show 2                # its runs, hand-offs and comments
aurelion kanban dispatch              # start workers for ready cards
```

- A card with an assignee (its lane) is ready for a worker. One without waits in triage.
- `--parent` makes a card wait until its parents are done. Its worker reads their hand-offs.
- `--contract OWNER/REPO` completes a card only on a pull request whose required checks pass. `local-only` needs no pull request.
- After 2 failed runs in a row, a card is blocked. `aurelion kanban unblock` puts it back.
- A card can go to review, where a reviewer run checks it before it is done.
- `--board NAME` uses a named board, shared by all your projects. Without it, each folder has its own board.

Other verbs: `move`, `update`, `assign`, `comment`, `archive`, `link`, `unlink`, `block`, `complete`, `promote`, `events` and `boards`. `aurelion kanban <verb> --help` explains each.

`aurelion serve` runs the dispatcher for you. `aurelion kanban dispatch` runs it in the foreground, `--once` for one round, `--all` for every named board too.

Lanes set how their workers run:

```toml
[kanban]
board = "team"            # the board to use when none is named
max_workers = 4           # workers at once, across lanes
interval_secs = 30        # how often the dispatcher looks
failure_limit = 2         # failed runs in a row before a card is blocked

[kanban.lanes.coder]
model = "claude-sonnet-4-5"
concurrency = 2           # workers of this lane at once
skills = ["test-driven-development"]
max_spend = 2.0           # USD per run
timeout_secs = 7200
reviewer = "reviewer"     # the lane that reviews this lane's cards
```

A lane can also set `provider`, a config `profile` and `yolo` (which applies only in a trusted folder). `configured_lanes_only = true` runs only the lanes you configured, `stale_secs` reclaims a card whose worker shows no sign of life, `review_dispatch = false` stops reviewer runs, and `dispatch_in_serve = false` keeps the dispatcher out of `aurelion serve`.

In the app, `/kanban` takes the same verbs, and the Jobs tab shows the cards. In a chat served by `aurelion serve`, `/kanban subscribe [N]` posts the board's events (or card N's) to that chat. The agent's `kanban` tool asks before it runs.

## Hooks

Hooks are your own programs, run at fixed points of a session. They can watch what happens, block a tool call, rewrite its input, or answer an approval for you.

```toml
[[hooks]]
event = "pre_tool_use"
command = "python3 ~/.config/aurelion/hooks/check.py"
matcher = "bash"          # a glob over the tool name; leave it out for every tool

[[hooks]]
event = "post_tool_use"
command = "~/bin/log-tool-use"
matcher = "mcp__*"
```

A hook gets a JSON payload on stdin: `hook_event_name`, `session_id` and `cwd`, plus `tool`, `tool_use_id` and `input` for tool events (and `output` after the call). It answers with its exit code and, optionally, JSON on stdout:

| Answer | Effect |
| --- | --- |
| Exit 0 with `{"decision": "deny", "reason": "…"}` | Block the call, with the reason. |
| Exit 2 | Block the call. The reason is what the hook printed. |
| Exit 0 with `{"updatedInput": {…}}` | Run the call with this input instead. |
| Exit 0 with `{"hookSpecificOutput": {"permissionDecision": "ask"}}` | Send the call to your approval card, even in BYPASS. |
| Exit 49 | Stop the whole turn after this call. |
| Exit 0 with nothing to say | Carry on. |
| Any other exit | Carry on, with a warning. |

A hook has 10 seconds. One that fails, times out or prints something unreadable lets the call through with a warning, unless you set `fail_closed = true`, which blocks instead. Use it for hooks whose job is to deny.

The events:

| Event | When it runs |
| --- | --- |
| `pre_tool_use` · `post_tool_use` | Before and after each tool call. After a call, `{"updatedOutput": "…"}` replaces what the model sees (at most 64 KB). |
| `pre_llm_call` | Before every model request. A block stops the request. |
| `post_llm_call` | After each model response, with the model, token counts, stop reason and the text. It can't block. |
| `session_start` | Once, before the first model request. What it prints (up to 8 KB) joins the model's context. |
| `user_prompt_submit` | When you send a prompt (the payload adds `prompt`). A block rejects the prompt; otherwise what it prints joins the context. |
| `stop` | When the turn is about to end with an answer. A block sends the reason back to the model and the turn goes on, at most 3 times a turn, never in subagents or plan mode. |
| `subagent_start` · `subagent_stop` | Around each subagent. The matcher is the agent's name. |
| `pre_compact` · `post_compact` | Around a compaction. The matcher is `manual` or `auto`. A `pre_compact` block cancels it. |
| `permission_request` | When an approval card is about to show. The matcher is the tool. `{"decision": "allow"}` or `"deny"` answers for you; anything else shows the card. |
| `api_error` | When a provider request fails, with the status and message. The matcher is the model. |
| `kanban_event` | For each kanban event, such as `completed` or `blocked`, while `aurelion serve` or `aurelion kanban dispatch` runs. The matcher is the event kind. |
| `session_end` | Once, when the session ends. |

Each event adds its own fields to the payload:

| Event | Fields it adds |
| --- | --- |
| `pre_tool_use` · `permission_request` | `tool`, `tool_use_id` and `input`. |
| `post_tool_use` | The same, and `output`. |
| `pre_llm_call` · `user_prompt_submit` | `prompt`, the prompt of the turn. |
| `post_llm_call` | `model`, `usage` (`input_tokens` and `output_tokens`), `stop_reason`, and `text`, the response. |
| `stop` | `last_assistant_message`, the answer the turn would end with, and `stop_hook_active`, which is `true` when a stop hook has already sent this turn back. |
| `subagent_start` | `agent` (its name), `label` (the short label it shows), `depth` (1 for a subagent of the main agent) and `prompt`. |
| `subagent_stop` | `agent`, `label`, `depth`, `success`, and `result`: its report, or the error. |
| `pre_compact` | `trigger`: `manual` or `auto`. |
| `post_compact` | `trigger`, and `summary`, the new summary. |
| `api_error` | `model`, `status` (the HTTP status, or `null`), `class` (the kind of failure, such as `rate_limited`, `auth`, `overloaded`, `network` or `timeout`) and `message`. |
| `kanban_event` | `kind`, `card` (its number), `title`, `board` (its name, `workspace` for a folder's own board), `board_ref` (the name, or `workspace:<folder>`), `run`, `lane`, `detail`, and `at` (Unix time in seconds). Its `session_id` is `kanban`. |
| `session_start` · `session_end` | Nothing more. |

Long text is cut at 8 KB: `text`, `last_assistant_message`, a subagent's `prompt` and `result`, `summary` and `message`. A `session_start` or `user_prompt_submit` hook can answer with `{"additionalContext": "…"}` instead of plain text. For `user_prompt_submit`, `stop` and `pre_compact`, `{"decision": "block", "reason": "…"}` blocks, like exit 2.

The answers take the shapes Claude Code's hooks use. Hooks in your global config always run. A project's hooks run only in a [trusted folder](modes-and-safety.md#trusted-folders), and enabled plugins can add hooks of their own.

`aurelion serve` has hooks of its own, for chat and daemon events: see [Serve and chat](serve-and-chat.md#gateway-hooks).

## Goals and loops

Some work takes more than one turn. These commands keep the agent going without you:

```text
/goal --max 30 Make every test in ./api pass.
verify: go test ./api/...
scope: only files under api/
stop when: the tests pass twice in a row
```

- `/goal <text>` sets a standing goal. After each turn, a judge model reads the reply against the goal and decides: done, continue or blocked. Lines starting with `verify:`, `constraints:`, `scope:` or `stop when:` say what done means. `--max` caps the turns (20 by default). `/goal show`, `pause`, `resume` and `clear` manage it.
- `/subgoal <criterion>` adds a criterion the goal must also meet.
- `/loop [interval] <prompt>` runs a prompt again after each turn, or every interval such as `10m`. `--times N` stops after N runs (10 by default, 100 on an interval), and `--until <condition>` once a judge sees the condition hold. `/loop pause`, `resume` and `stop` manage it.
- `/heartbeat every 30m <prompt>` (or `/hb`) runs a prompt on an interval, but only while the session is idle. The interval is 60 seconds or more.
- `/queue <prompt>` runs a prompt as its own turn after the current one.

When the judge can't be reached, the agent's own word that the goal is complete or blocked decides.

**Next:** [Serve and chat](serve-and-chat.md)
