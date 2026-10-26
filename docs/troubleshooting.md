# Troubleshooting

When something doesn't work, AURELION can usually tell you why. `aurelion doctor` checks your setup line by line, the log keeps every failed request, and one command writes a redacted report you can send to the team. This page shows those tools, what to do when AURELION crashes, and answers to common problems.

## Check your setup

```sh
aurelion doctor
aurelion doctor --offline    # skip the network checks
```

`doctor` checks the config files, the active profile and config warnings, the provider and model, whether a key is there (it shows where the key comes from, never the key), whether the provider answers, the sandbox, `git`, `python3`, your language servers and MCP server commands, the session and config folders, the license, and Chrome's debugging port.

```text
✓ sandbox          sandbox-exec (Seatbelt)
✓ git              /usr/bin/git
✗ api key          missing  → export ANTHROPIC_API_KEY=… or run `aurelion setup`
! license          not activated  → run `aurelion activate <key>`
```

Each line is `✓`, `!` or `✗`, with a fix after the arrow. `doctor` exits with code 1 when any line is `✗`. The network checks give up after 5 seconds.

## Read the log

```sh
aurelion logs              # the last 50 lines
aurelion logs -n 200
aurelion logs -f           # follow new lines as they come
```

AURELION writes one log file a day, `aurelion.log.<date>`, in a `logs` folder beside your sessions, and keeps the newest 7. `aurelion config` prints where. On macOS that is `~/Library/Application Support/aurelion/logs`, and on Linux `~/.local/share/aurelion/logs`.

By default the log holds warnings and errors: failed requests, retries and fallbacks to another model, each with the provider's request id. For more, start AURELION with a log level:

```sh
RUST_LOG=info aurelion     # adds a line per prompt, per model request (timings and tokens) and per tool call
RUST_LOG=debug aurelion    # much more
```

Use a plain level such as `info` or `debug`. Filters by component don't work in release builds: they turn logging off, warnings included.

## Send a report

```sh
aurelion diagnostics                 # writes aurelion-diagnostics-<time>.txt here
aurelion diagnostics report.txt --days 7
```

The file holds the recent warnings and errors from the log (3 days by default), `doctor`'s checks, and your version and platform. API keys are masked, web addresses are cut to their host, and it has no MCP endpoints and nothing from your sessions. Read it before you send it.

In a session, `/debug` writes a redacted debug bundle under `.aurelion/debug/` for the same purpose.

## When AURELION crashes

If AURELION crashes, it puts your terminal back the way it was and prints a message like this:

```text
thread 'main' panicked at f412:88:9:
<what went wrong>
```

`f412:88:9` names the place in AURELION's code where it happened. Send the whole message to the team, with your version (`aurelion --version`) and what you were doing. Copy it as it is: the team needs every part of it.

A crash in background work while the cockpit is open goes to the log instead of the screen. `aurelion logs` shows it, and `aurelion diagnostics` includes it.

Your session is safe either way: AURELION saves it as it goes, so `aurelion -c` picks up where you left off.

## Common problems

**AURELION says it is locked, or exits with code 3.** This machine has no valid license. Run `aurelion activate <key>`. `aurelion doctor` shows the license state.

**The model doesn't answer, or the key is refused.** Run `aurelion doctor`: it names the provider, the model and where the key comes from, and tries a request. `aurelion providers` shows the key variable each provider reads, and which ones you have set. If you switched providers, remember that `AURELION_API_KEY` stays with the provider it was first used with.

**A Claude plan doesn't work.** `claude-subscription` and `claude-cli` run through the official Claude Code CLI: install it, run `claude` once and log in, then `aurelion connect claude`. On `claude-subscription`, a call that goes quiet for 120 seconds is stopped; `[claude] silence_secs` changes that. When your plan's limit is reached, AURELION waits for the reset when it is near, and ends the turn when it is far off.

**A tool call was refused without a card.** It needed an approval where nobody could answer: a cron job, `/swarm` or `/review`, `aurelion -p`, a batch run or a server. The refusal says why. Allow the call with a [rule](modes-and-safety.md#rules), or run the work where you can approve it.

**Web requests keep asking.** Each new host asks once. Press `Shift+A` on the card to allow the host for good, or add it to `egress_allow` in your global config. Subagents and cron jobs can't ask, so they need the host in `egress_allow`.

**The browser tools can't connect.** They drive a Chrome you start yourself, with `--remote-debugging-port=9222`. `aurelion doctor` checks the port.

**Commands fail with the sandbox on (Linux).** The sandbox needs `bwrap`: install the `bubblewrap` package. Where the sandbox can't run, commands fail instead of running unconfined.

**An MCP server shows `✗`.** `/mcp` shows why. A local server doesn't get your keys from the environment, so name what it needs in its `env` table, in your global config. `/mcp reconnect <server>` restarts it, and `aurelion mcp list` shows its state from the shell.

**The project's config, rules or `AGENTS.md` seem ignored.** In a folder you haven't trusted, AURELION keeps only the harmless parts of the project's config and reads instructions as information. Run `/trust yes` in the folder you start AURELION in, then restart. A subfolder of a trusted folder is not trusted on its own. The startup warning names what was ignored.

**`yolo = true` doesn't skip the approvals.** It counts only in a trusted folder. `/yolo` turns approvals off for the session anywhere.

**The run chip says `! DONE · unverified`.** The checks failed, or AURELION knows of none for this project. Checks run only in a trusted folder, and only when their program is installed. Name them with `[verify] commands`. See [Undo and review](undo-and-review.md#checks-after-a-turn).

**`Shift+Enter` sends the prompt instead of a new line.** Some terminals can't tell it apart. Use `Ctrl+J` or `Alt+Enter`, or end the line with `\` and press `Enter`. [Keys](keys.md) has the rest.

**The screen looks wrong.** `/redraw` repaints it. A theme with too little contrast in your terminal: try `/theme` for another.

**The session feels slow or forgetful.** A full context slows every request. `/context` shows what fills it, and `/compact` frees it. See [Memory and context](memory-and-context.md#compaction).

**`aurelion serve` won't start.** One serve runs per user. `aurelion serve --status` asks the one that runs, and `aurelion serve --stop` stops it. After an update, restart the serve.

**An update is refused.** AURELION installs only releases signed with its release key, and says `not signed with AURELION's release key — not installing` otherwise. Don't work around it: download the release from the releases page and [check it by hand](getting-started.md#check-a-download-by-hand).

**Something runs away.** `aurelion estop "reason"` halts every agent, subagent, cron job and serve turn that shares your home folder, before its next step. `aurelion estop --clear` lets them run again.

## Start fresh

```sh
aurelion backup before-reset.tar.gz   # keep a copy first
aurelion uninstall --deep             # the binary, config, data, caches and the trust record
```

Then install again. Your projects' `.aurelion/` folders stay; delete one to reset that project.

**Next:** [Security and releases](security-and-releases.md)
