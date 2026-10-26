# Commands

Slash commands drive AURELION from the prompt. Type `/` to see them as you type, or press `Ctrl+K` for the palette, which groups them and lets you filter by name or description. A command that needs an argument fills the prompt and waits for it; the others run at once. This page lists every command, in the palette's groups.

In the tables, `<x>` is required and `[x]` is optional.

## Session

| Command | What it does |
| --- | --- |
| `/new` | Start a fresh session. |
| `/resume [id]` | Pick a recent session to resume. With an id prefix, jump straight to it. A resumed session switches back to the model it ran on, without changing your default. |
| `/sessions` | List recent sessions in the stream. |
| `/fork` | Copy this session into a new one and continue there. |
| `/tree` | Show the session tree, with `⎇` where it branches. |
| `/branch <n>` | Continue from message `n`. Nothing is rewritten: the old path stays in the tree. `/branch @k` continues from the end of turn `k`. |
| `/rewind [before <n>]` | Put files back from this session's checkpoints. Alone, it undoes the last file step; `/rewind 3` the last three; `/rewind before <n>` everything since message `n`. The conversation stays. |
| `/undo [n]` | Undo the last `n` turns (default 1): revert their file edits and the conversation. The undone prompt comes back in the prompt for you to edit. |
| `/diff [path]` | Show what the agent changed this session, or `git diff` when it changed nothing. |
| `/compact [focus]` | Summarize the history to free context. Focus text steers the summary. `/compact --preview` shows the summary without applying it, and `/compact here <n>` keeps the last `n` messages word for word. The options combine. |
| `/context` | A token breakdown of the live context. |
| `/export [path]` | Write the transcript to `.aurelion/exports/`, or to the path you give. |
| `/pin [text]` | Pin text so it survives every compaction word for word. Alone, it pins your last message. |
| `/pins` | List the pins. |
| `/unpin <n>` | Remove pin `n`. |
| `/facts [forget <label>]` | Show the session's key facts: files changed, commands run, your instructions in your own words, decisions and their reasons, open tasks. `forget` removes one. |
| `/title [text]` | Show or set the session's title. |

[Undo and review](undo-and-review.md) covers snapshots and undo. [Memory and context](memory-and-context.md) covers compaction, pins and key facts.

## Model and providers

| Command | What it does |
| --- | --- |
| `/model [id]` | Alone, open the model picker: every connected provider's models, grouped, with their context size and price. With an id, switch at once. `/model <provider>:<id>` switches provider and model together. Either way, the choice is saved as your default. |
| `/provider` | Connect another provider: pick it, paste its key, pick a model. `/provider list` shows the connected ones, and `/provider remove <id>` forgets one. Also `/connect`. |
| `/moa <prompt>` | Run one turn on the default Mixture-of-Agents preset: reference models advise, one model acts. |
| `/theme [name]` | Switch the theme. Alone, cycle to the next one. `/theme list` shows the built-in themes and yours. |
| `/personality [name]` | Set a personality for this session, such as `concise`, `teacher` or `reviewer`. `/personality none` removes it. |
| `/layout [name]` | Pick the layout: `rails`, `focus`, `cockpit` or `split`. Alone, list them. `left`, `right`, `both` and `reset` collapse or restore the sidebars. |
| `/thinking [level]` | Set the thinking level: `off`, `low`, `medium`, `high` or `xhigh`. It applies from the next turn. |
| `/setup` | Run the setup wizard again. Also `/login`. |

See [Models and providers](models.md) and [The cockpit](cockpit.md).

## Run and review

| Command | What it does |
| --- | --- |
| `/plan` | Toggle plan mode: read-only planning. `/plan` again builds the plan, in AUTO with approvals on. |
| `/approval <mode>` | Set how tool calls are approved: `ask` is AUTO, `all` is ASK, `yolo` is BYPASS. |
| `/yolo` | Toggle tool approvals off and on. In plan mode it can't turn them off. |
| `/swarm <goal>` | Fan a goal out to all your configured `[[agent]]` workers at once, then combine their reports. |
| `/debate <proposition>` | A proposer and a reviewer argue over a claim for a few rounds. The reviewer must find real flaws or concede, and you see what survived. |
| `/worlds <task>` | Three parallel attempts at a task, judged, best first. |
| `/drill` | A practice drill from this project: one agent writes an exercise around a real Rust function, another solves it in the sandbox, and a solved drill is saved as a skill. |
| `/commit` | Split your uncommitted changes into small, self-contained commits, in dependency order. Needs a trusted folder. |
| `/review [focus]` | A subagent reviews your uncommitted changes. Add a focus to aim it. |
| `/steer <message>` | Send a message into the running turn, without waiting for it to finish. |
| `/goal [--max N] <text>` | Set a standing goal. The agent keeps working toward it, and a judge checks each turn. Add `verify:`, `constraints:`, `scope:` or `stop when:` lines to say what done means. `--max` caps the turns (default 20). `/goal show`, `pause`, `resume` and `clear` manage it. |
| `/subgoal <criterion>` | Add a criterion the goal must also meet. `/subgoal remove N` and `/subgoal clear` take them away. |
| `/loop [interval] <prompt>` | Run a prompt again after each turn, or every interval (such as `10m`). `--times N` stops after `N` runs, `--until <condition>` once a judge sees it hold. `/loop pause`, `resume` and `stop` manage it. |
| `/heartbeat every <interval> <prompt>` | A recurring prompt that fires only while the session is idle. The interval is 60 seconds or more. `/heartbeat pause`, `resume` and `clear` manage it. Also `/hb`. |
| `/queue [prompt]` | Queue a prompt to run as its own turn after the current one. Alone, list the queue. `/queue clear` empties it. After `Esc` the queue is held, and `/queue resume` runs it. |
| `/prompt` | Write the prompt in `$VISUAL` or `$EDITOR`, like `Ctrl+X` `Ctrl+E`. Also `/editor`. |
| `/background [prompt]` | Run a prompt as a detached background agent. `/background list` shows them, and `/background cancel <id>` stops one. Also `/bg`. |
| `/kanban [verb]` | The kanban board: cards, lanes, links and runs. `list`, `show N`, `add "title" --lane L`, `comment`, `block`, `unblock`, `complete` and `events`; `--board B` picks a named board. |

See [Modes and safety](modes-and-safety.md), [Agents](agents.md) and [Automation](automation.md).

## Memory and skills

| Command | What it does |
| --- | --- |
| `/remember <fact>` | Store a fact that lasts across sessions in this project. `--user` stores it for all your projects. |
| `/recall <term>` | Search the facts you stored. |
| `/forget <term>` | Remove the facts that match. `--user` removes from your user memory. |
| `/memory [verb]` | List the memory. `pending`, `diff`, `approve` and `reject` review memory writes that wait for your approval, and `approval on` or `off` decides whether they wait. `import` brings in Claude Code's memory for this project. |
| `/skills [verb]` | List the skills. `pending`, `diff`, `approve` and `reject` review skill writes that wait for your approval, and `approval on` or `off` decides whether they wait. `import [dir]` and `export [dir]` move skill files in and out. |
| `/bundles` | List the skill bundles. `/<bundle>` loads one. |
| `/learn [name] [url or path…] [focus]` | Turn this session, or a web page, file or folder, into a skill. |
| `/refine [focus]` | Run the skill and profile review on the last turns now. |
| `/journey [show <id>]` | A timeline of the skills and memories AURELION learned, to look through. `/journey delete <id>` prunes one. |
| `/curator [verb]` | Skill upkeep: archive unused skills, merge near-duplicates, and undo either. `status`, `run` (with `--dry-run` or `--consolidate`), `pin`, `unpin`, `archive`, `restore`, `rollback` and `ledger`. |
| `/cron [verb]` | Scheduled jobs: `list`, `add NAME -s "every weekday at 9am" --prompt …`, `edit NAME …`, `run`, `pause`, `resume`, `rm`, and `incidents` (with `--ack N`) for their failures. |
| `/blueprint [name] [slot=value …]` | Ready-made automations. Alone, list them. With a name and no values, the agent asks for each value, then sets the job up. `/blueprint show <name>` shows one's blanks. |
| `/suggestions [verb]` | Suggested automations that wait for your yes: `accept N`, `dismiss N`, `catalog` and `clear`. |

See [Memory and context](memory-and-context.md) and [Automation](automation.md).

## Info and app

| Command | What it does |
| --- | --- |
| `/help` | The key list. Also `/?`. |
| `/voice` | Dictate into the prompt, like `F7`. Press again to transcribe. Dictation needs a build with voice support; release builds have none, and `/voice` says so. |
| `/rerun [n]` | Ask a prompt again (default: the last one), with what the agent knows now. |
| `/status` | The session, model, mode, context use, cost against your cap, MCP servers, jobs and git branch. |
| `/version` | The version and build, and the update channel. |
| `/tokens` | Tokens and cost for this session. Also `/cost`. |
| `/usage` | Your real account usage, from the provider. A ChatGPT plan shows its quota. On a Claude plan, run `/usage` inside `claude`; on an API key, use `/tokens`. |
| `/config` | Where the config files and sessions live. |
| `/tools [verb] [names]` | List the tools with on and off marks. `/tools disable <names>` and `/tools enable <names>` turn some off or on for this session, and `--save` keeps a tool off in this project. `/tools reset` turns them all back on. |
| `/mcp [reconnect <server>]` | Each MCP server's health: `●` ready, `✗` failed (with why), `◌` connecting. `reconnect` restarts one. |
| `/trust yes` | Trust this folder. Typed alone, `/trust` says whether it is trusted. |
| `/trust no` | Take trust back from this folder. |
| `/btw <question>` | A quick side question. No tools, and nothing saved to the session. |
| `/init [focus]` | Write an `AGENTS.md` for this project, or improve the one there. |
| `/copy [n]` | Copy the last reply, or the `n`-th last, to the clipboard. |
| `/redraw` | Repaint the whole screen. |
| `/reload` | Reload the config, `AGENTS.md`, memory and skills from disk. |
| `/debug` | Write a redacted debug bundle under `.aurelion/debug/`, for a bug report. |
| `/quit` | Leave AURELION. Also `/exit` and `/q`. |

## Your own commands

Put a Markdown file in `.aurelion/commands/` in a project, or in `~/.config/aurelion/commands/` for every project. Its name becomes a command, and its text is sent as the prompt:

```markdown
<!-- .aurelion/commands/fix-issue.md -->
Fix issue $1 in this repository. Read the issue, write a failing test,
then make it pass. Notes from me: $ARGUMENTS
```

Then `/fix-issue 42 keep it small` sends that text, with `$1` as `42` and `$ARGUMENTS` as everything you typed after the command. `$1`, `$2`, … are the words in order. Built-in commands win over a file with the same name.

Skills work the same way: `/<skill-name> [args]` runs a skill with its instructions, and `/<bundle>` loads a skill bundle. [Memory and context](memory-and-context.md) covers skills.

**Next:** [Modes and safety](modes-and-safety.md)
