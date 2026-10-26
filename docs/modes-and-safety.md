# Modes and safety

AURELION acts on your machine, so you decide how much it may do on its own. Four modes set how often it asks. Approval cards ask without getting in your way. Trust is given per folder, rules and a sandbox bound the shell, and spend caps bound the bill. This page covers each, and where commands can run instead of your machine.

## The four modes

The mode chip at the left of the status row shows the mode. `Shift+Tab`, or a click on the chip, cycles PLAN → AUTO → ASK.

| Mode | What the agent may do |
| --- | --- |
| **PLAN** | Read and plan only. The tools that write files or run code are off, and `bash` asks before anything but plain read-only commands. The agent researches and writes its plan to `.aurelion/PLAN.md`. `/plan` again starts building it, in AUTO. |
| **AUTO** | The default. Your rules decide: most reads and edits run, and anything risky asks. |
| **ASK** | Every tool call that isn't read-only asks first. |
| **BYPASS** | No questions: approvals are skipped. Refusals still hold. |

A session starts in AUTO with approvals on. Trusting a folder doesn't change that.

**PLAN** suits work you want to see before it happens:

```text
/plan
Plan the move from the REST client to the generated SDK.
/plan
```

The first `/plan` enters plan mode, the second leaves it and hands the plan to the build. `aurelion --plan` starts a session in plan mode. Plan mode always keeps approvals on, even when bypass was on before, and leaving it always lands in AUTO.

**AUTO** asks before:

- `bash` commands, except plain read-only ones inside the folder, such as `ls`, `cat file` or `git status`;
- tools listed in `[tools] ask`. By default that includes `bash`, `execute_code`, `tool_forge`, `browser`, `browser_act` and `cronjob`, among others;
- every MCP tool, unless you trust its server's read-only tools (see [Tools](tools.md));
- edits to files that steer later sessions or the repository: `AGENTS.md`, `CLAUDE.md`, the `.aurelion/` folder, `.git` and `.github/workflows`.

**ASK** is `/approval all`. It suits a codebase you don't know yet.

**BYPASS** only starts when you ask for it: `/yolo` or `/approval yolo` in a session, `--yolo` or `AURELION_YOLO=1` for one run, or `yolo = true` in your config, which counts only in a trusted folder. `Shift+Tab` leaves bypass and never returns to it. BYPASS skips the questions, not the refusals: banned commands and your `deny` rules still stop a call.

### Under Claude Code

With the `claude-cli` provider, Claude Code runs its own tools, and the mode reaches it as its own permission mode. PLAN is Claude Code's plan mode. ASK runs it in its default mode, where a command or edit that would ask is refused. AUTO turns its permission checks off only in a folder you trust.

## Approval cards

When a call needs your answer, a card shows what it wants to do: the tool, and its command, file or URL. An edit shows the diff it would make.

![ASK mode: a Bash call waits for approval, and its card waits in the Inbox](../assets/svg/captures/approval.svg)

*A card in the Inbox (right) while `go vet` waits for approval in ASK mode. The status row reads `? 1 need you`. The `· verify:` lines in the stream are the checks AURELION runs after an edit: the tests passed, and mutation testing had nothing to do, since it covers Rust files only. `verify V3: SOUND` means a reviewer model read the change and found no flaw.*

| Key | What it does |
| --- | --- |
| `y` | Allow once. |
| `Shift+A` | Always allow. Only when the card offers it. The card says what it covers and how long it lasts. |
| `n` | Deny. The agent is told, and carries on. |
| `Esc` | Clear your draft first, then deny. The next `Esc` stops the turn. |

"Always" on a file tool covers the file's folder inside the project, and the card names the folder. On one of the files that steer later sessions, it covers that file alone. On `bash`, it covers that exact command.

How long "always" lasts depends on the folder:

- **In a folder you trust**, the grant is saved to `.aurelion/allowlist.toml` in that folder, and later sessions there load it. The card says `saved to .aurelion/allowlist.toml`. Grants on the files that steer later sessions, and on risky commands (such as ones that delete or overwrite files, use `sudo`, or pipe into a shell), are never saved: they last for the session.
- **Anywhere else**, "always" lasts for the session.

To review or take back saved grants, open `.aurelion/allowlist.toml`. Each entry names a tool and either an exact `subject` (a command or a file) or a folder `pattern`:

```toml
[[allow]]
tool = "bash"
subject = "cargo test"

[[allow]]
tool = "write"
pattern = "/work/app/web/**"
```

Delete an entry, or the whole file. The change applies from your next session; `/new` starts one. Your `deny` rules always win over a saved grant. The file sits in `.aurelion/`, so the agent can't change it without asking you.

In the wide layout the card waits in the rail's Inbox, so it never covers the stream. Give the rail the keys (`Tab`, `Alt+1` or a click), press the card's number, then `y`, `A` or `n`. Elsewhere it shows over the stream.

A card can't be answered by accident. It acts only after it has been on screen for 400 ms and your keys have paused for 400 ms. Typing in the prompt never answers it, and your draft is kept. [Keys](keys.md#approval-and-question-cards) has every rule.

**Questions** work the same way. When the agent can't decide something itself, it asks with a few options: press an option's number, or type your own answer.

## Trusted folders

A repository controls what is inside it: its instructions, its config, its build scripts. AURELION runs none of that on its own until you trust the folder.

```text
/trust yes     # trust this folder
/trust no      # take trust back
/trust         # say whether it is trusted
```

The setup wizard asks too. AURELION keeps the list of trusted folders outside the project, so a repository can't trust itself.

Trust belongs to the exact folder you trust. Run `/trust yes` in the folder you start AURELION in. If you trust `~/code/app` and then start in `~/code/app/web`, that session is untrusted: the project config is trimmed, `AGENTS.md` is information only, the checks don't run, and under Claude Code AUTO keeps its permission checks on. Only AURELION's own use of git looks further: snapshots, `/commit`, staging, `/diff`, `@diff` and `@staged`, and `--worktree` count a trusted top folder of the repository for its subfolders too. A worktree that `--worktree` makes counts as trusted when its repository's main folder is.

In a trusted folder:

- the project's `.aurelion/config.toml` applies in full, after a restart;
- `AGENTS.md`, `CLAUDE.md` and the project's rules are binding instructions;
- the project's formatters run after an edit, and its checks run after a turn (see [Undo and review](undo-and-review.md));
- snapshots use git, so they also cover edits made outside AURELION's tools;
- `/commit`, staging and `--worktree` work.

In a folder you haven't trusted:

- the project's config keeps only harmless settings, such as the theme and model names. Anything that could run commands, turn off approvals or change where requests go is ignored, with a warning;
- instruction files load as information, not as instructions;
- AURELION runs no git of its own. Undo uses its own copies of the files it changed.

Trust never turns approvals off.

## Rules

Rules decide what asks, what runs and what is refused. List the tools that must always ask:

```toml
[tools]
ask = ["bash", "browser"]   # replaces the default list
timeout_secs = 120          # the default per-call timeout
```

For finer control, write permission rules. Each one names a tool, an optional glob over what the call touches (the command for `bash`, the path for file tools), and an action: `allow`, `ask` or `deny`. When several rules match, the last one wins.

```toml
[[permissions]]
tool = "bash"
pattern = "git push*"
action = "deny"

[[permissions]]
tool = "read"
pattern = "*.env"
action = "ask"
```

A `read` rule also holds for the other tools that return the file a call names, such as `grep` on that file or `lsp`.

`/tools disable <name>` turns a tool off for the session, and `--save` keeps it off in this project.

To answer fewer cards, let a cheap model screen them first. It approves, denies, or passes the call on to you:

```toml
permission_reviewer = "smart"
```

## The shell

`bash` is the most powerful tool, so it has the most guards:

- **Banned commands** such as `rm -rf /`, disk wipes and piping a download into a shell are refused outright, in every mode.
- **Plain read-only commands** inside the folder (`ls`, `cat file`, `git status`, `ls | wc -l`) run without asking.
- **Everything else** follows your mode and rules.
- **Text typed into a running job** asks too, line by line.
- **Long work goes to the background.** A command still running after 60 seconds keeps going as a job, and the agent checks on it.

Commands start without the keys AURELION holds: no provider keys, no search or chat keys, no `AURELION_*` secrets. The credentials your own tools read, such as `GITHUB_TOKEN` or your cloud credentials, pass through.

### The sandbox

Turn the sandbox on to confine every `bash` command:

```toml
[tools]
sandbox = true    # or AURELION_BASH_SANDBOX=1
```

Commands then run with no network, can write only to the project and the temp folder, and can't read your credential stores. It uses Seatbelt on macOS and bubblewrap (`bwrap`) on Linux. Where neither works, commands fail instead of running unconfined.

## The network

The agent's web tools (`webfetch`, `websearch`, `browser`) reach only hosts you allow. A new host raises a card that names the host and the full URL: `y` allows that request, `Shift+A` always allows the host, and `n` denies. "Always" saves the host to `egress_allow` in your global config, so it lasts across sessions and covers its subdomains.

```toml
# ~/.config/aurelion/config.toml
egress_allow = ["pypi.org", "api.github.com"]
egress_allow_local = false   # true lets the web tools reach localhost and your LAN
```

- Local and private addresses ask like any unknown host, unless you set `egress_allow_local = true` in your global config.
- In BYPASS a new host is allowed without a card.
- Cloud metadata addresses are always refused, even in BYPASS.
- Subagents and cron jobs can't show a card, so an unknown host is refused there.
- Every redirect is checked like the first request.
- Model providers are not affected: a local Ollama keeps working.

To limit which sites the web tools may read at all:

```toml
[web]
allow_domains = ["*.python.org", "developer.mozilla.org"]   # empty: any host
deny_domains = ["example.com"]                              # wins over allow
```

## Output safety

On by default, output safety masks secrets (API keys, tokens) in what tools return before the model sees it, and marks web and MCP output as untrusted content, not instructions.

```toml
[tools]
output_safety = true   # the default; false turns it off (not recommended)
```

## Spend caps

Set a cap, and the agent stops before the next request once a session, or a single prompt, has cost that much. Subagents count toward it.

```toml
max_spend_usd = 5.0            # per session
max_spend_usd_per_turn = 1.0   # per prompt
```

```sh
aurelion -p "fix the failing test" --max-spend 2   # one run's cap
```

The status row then shows spend against the cap, such as `$1.84 / $5`. Caps count metered providers only. On a Claude plan (`claude-subscription` or `claude-cli`) the cost is shown but never capped.

## The emergency stop

One command halts every agent, subagent, cron job and `aurelion serve` turn that shares your home folder, before its next model call or tool run:

```sh
aurelion estop "deploy window"   # engage, with a reason
aurelion estop --status          # is it on?
aurelion estop --clear           # let them run again
```

## A record of every decision

AURELION keeps a tamper-evident record of approvals and denials.

```sh
aurelion ledger list     # the latest: time, tool, decision, subject
aurelion ledger verify   # check the whole record; exits 1 at the first altered entry
```

## Where commands run

By default `bash` runs on your machine. Set `[exec] backend` to run it elsewhere. Your mode and rules still apply, and the remote side is the boundary instead of the local sandbox.

| Backend | Where commands run |
| --- | --- |
| `local` | Your machine (the default). |
| `docker` | One long-lived container per project, with the project mounted at the same path. |
| `ssh` | A remote host, with key authentication only. Files are not synced. |
| `singularity` | Apptainer or Singularity, with the project bind-mounted. |
| `modal` · `daytona` · `vercel` | A cloud sandbox per project, created on first use. Changed files sync up before each command and back after it. |

```toml
[exec]
backend = "docker"

[exec.docker]
image = "rust:1-bookworm"
network = false     # no network inside the container
shell = "bash"      # "sh" for alpine

[exec.ssh]
host = "build-box"
remote_dir = "/srv/project"   # the project maps here
```

The cloud sandboxes are deleted when AURELION exits, unless you set `persist = true`. In a folder you haven't trusted, the project's config can't set `[exec]`. `aurelion doctor` checks the backend. The cloud sandboxes run outside the local sandbox. [Configuration](configuration.md) lists every backend's settings.

**Next:** [Undo and review](undo-and-review.md)
