# Agents

One agent is rarely the fastest way through a big job. In the cockpit, AURELION's lead agent can hand work to subagents: one to research a question, several at once to cover more ground, or a graph of steps that feed each other. Writers get their own copy of your repository and their changes are merged back. Every subagent runs under your rules. This page covers subagents, your own named agents, background agents and the commands that put several models to work on one question.

## Subagents

The lead agent spawns subagents with its `task` tool. Each subagent gets its own session and a clean context, works on its part, and returns a report. The lead reads the reports and carries on, so its own context stays small.

`task` runs in three shapes:

| Shape | What happens |
| --- | --- |
| Single | One subagent on one task. |
| Parallel | Several subagents at once, each with its own task. The reports come back together, one section each. |
| Graph | Up to 16 steps that depend on each other. They run in waves: a step starts once the steps it depends on are done, and it gets their reports. When a step fails, the steps that depend on it are skipped. |

You see a spawn as a `⇉` row in the stream, and each subagent as a row in the Workers pane on the left: `Workers 3 live · 1 done · 2 wait`. Focus the pane, pick a worker with `↑` `↓`, and `Enter` opens its session in an inspector. [The cockpit](cockpit.md#the-left-column) shows the pane.

In parallel and graph runs, the reports also land on a shared blackboard, `.aurelion/blackboard.json`, so later steps and later subagents can read what earlier ones found.

A few more things the lead can ask of a subagent:

- **A structured answer.** Given a JSON schema, the subagent's final answer is checked against it, with one retry to fix the format. The raw report is always kept too.
- **Images.** Up to 8 images the subagent must see, such as screenshots.
- **Background work.** A subagent can run detached while the lead keeps going. Its report arrives when it is done, or the lead waits for it (`agents_wait`) or pauses its turn until the background work finishes (`sessions_yield`). The lead can also steer a running one with a new instruction, stop it, or start it again.

`task` is part of the interactive app. `aurelion -p`, editors over ACP and `aurelion serve` run without it.

### What a subagent may do

A plain subagent is a researcher. It has read-only tools: `read`, `glob`, `fsearch`, `grep`, `ls`, `ast_grep`, `repo_map`, `webfetch` and `websearch`.

To change files, the lead uses the built-in `worker` agent. A worker also has `write`, `edit`, `multiedit`, `ast_edit` and `bash`, and implements a bounded change: it edits, runs the tests and reports back.

Subagents run under the same approvals, permission rules, hooks and bash sandbox as your session:

- a call that would ask shows its approval card in your session, as the lead's would;
- where nobody can answer a card (a cron job, `/swarm`, `/review`), the call is refused with the reason;
- an unknown web host is refused, since a subagent can't show a network card;
- in plan mode, subagents are bound by plan mode too.

### Parallel writers

Two subagents editing the same folder at once would trip over each other. So in a git repository you trust, each subagent in a parallel or graph run that can write gets its own git worktree: a separate checkout that starts from your current files, uncommitted changes included.

When the writers finish, their changes are applied to your folder one after another. A file that two writers both changed is a conflict: the first writer's change wins, and the others are reported, not applied. Nothing is overwritten in silence.

In a folder you haven't trusted, or outside git, the writers share your folder instead, and AURELION says so.

### Which model subagents use

Subagents run `[subagents] model` when you set it, and otherwise the session's own model. A named agent with its own `model` uses that one.

```toml
[subagents]
model = "claude-sonnet-4-5"   # unset: the session's model
effort = "low"                # off, low, medium, high or xhigh; unset: the provider's default
max_depth = 2                 # how deep subagents may spawn subagents (1: no nesting)
max_live = 8                  # subagents running at once, across the whole tree
orchestrate = true            # the lead plans and delegates (the default)
```

- `max_depth = 2`, the default, lets a subagent spawn subagents of its own once. Their subagents can't.
- With `orchestrate = true`, the lead agent plans the work, hands substantial parts to subagents and the worker, and puts the results together. With `false`, it does the work itself and spawns a subagent only when it decides to.
- With `claude-cli` as your provider, subagents never run as Claude Code. They run on `claude-subscription` with the same model, under AURELION's tools and approvals.
- Subagents count toward your [spend caps](modes-and-safety.md#spend-caps).

## Your own agents

Define named agents in your config. The lead sees their names and descriptions, and can pick one for a task:

```toml
[[agent]]
name = "explorer"
description = "maps a codebase and reports its structure"
prompt = "You are a codebase explorer. Map the structure and report what you find."

[[agent]]
name = "tester"
description = "writes and runs tests"
prompt = "You write focused tests and run them."
model = "claude-haiku-4-5"
tools = ["bash", "write", "edit"]
```

- `prompt` is the agent's instructions, and `description` is the line the lead reads when it chooses.
- An agent starts with the research tools. `tools` adds more, such as `bash` or `edit`.
- `readonly = true` keeps an agent to the research tools, whatever `tools` says.
- `model` runs it on another model of the same provider.
- If two definitions share a name, the first one wins. Defining your own `worker` replaces the built-in one.

`agents_list` shows the agents the lead can spawn. A cron job runs a named agent with `--agent`, see [Automation](automation.md). In a folder you haven't trusted, the project config's `[[agent]]` tables are ignored.

## Background agents

`/background` (or `/bg`) hands a prompt to a worker that runs on its own while you keep working. Its report shows up in the stream when it is done.

```text
/background update the changelog for the last five commits
/background                       # list them, with their state
/background steer 2 skip the docs folder
/background cancel 2
```

`steer` sends the worker a new instruction, which it reads at its next step, after its current tool call.

## Several minds on one question

These commands put more than one model call to work, each in its own way:

| Command | What it does |
| --- | --- |
| `/review [focus]` | A subagent reviews your uncommitted changes, with read-only tools, and reports its findings. A focus such as `error handling` aims it. |
| `/swarm <goal>` | Sends the goal to every `[[agent]]` you defined at once. Their reports land on the blackboard, and the lead puts them together. With no agents defined, one explorer goes. |
| `/debate <proposition>` | A proposer and a reviewer argue over two rounds. The reviewer must name concrete flaws or concede. You see the position that survived and what each attack found. |
| `/worlds <task>` | Three independent attempts at the task, judged and listed best first. |
| `/drill` | A practice round from this project: one agent writes an exercise around a real Rust function, another solves it in the sandbox. A drill counts as solved when it passes its test cases, and a solved drill is saved as a skill. |
| `/moa <prompt>` | One turn on a Mixture-of-Agents preset: reference models advise, one model acts. See [Models and providers](models.md#mixture-of-agents). |

The `mixture_of_agents` tool does the same for a single question the agent asks, and `decision_evaluate` gives a calibrated judgment: yes-or-no odds, a choice between options, or a score. See [Tools](tools.md#extension-tools).

## Finishing the job

Two helpers watch the end of each turn.

**The completion guard** is on by default. When a turn worked on the todo list and stops with tasks still open, the agent is told to continue. A nudge the agent answers without doing anything ends it, and a message you queued always goes first.

```toml
[autopilot]
enabled = true
max_continues = 3   # nudges per turn, at most 20
max_minutes = 30    # time per turn, at most 240
```

**The advisory watchdog** is off by default, since it costs one more model call per turn. When on, a second model reviews each finished turn. Its note is shown in the stream and given to the agent before the next turn. It uses your small model when you set one.

```toml
[advisory]
enabled = true
focus = "missed requirements and regressions"
```

For a goal that takes many turns, `/goal` keeps the agent working until a judge says it is done. See [Automation](automation.md#goals-and-loops).

## Other sessions and remote agents

Your running AURELION sessions can see each other. The deferred tools `sessions_list`, `sessions_history`, `sessions_send` and `presence` let an agent find your other sessions, read them and send them a message.

Agents elsewhere can be called over the Agent2Agent protocol. `a2a_call` calls a remote agent you name in `AURELION_A2A_PEERS=name=url,…`, and `aurelion a2a serve` offers this agent to others. See [Serve and chat](serve-and-chat.md#agent2agent).

**Next:** [Memory and context](memory-and-context.md)
