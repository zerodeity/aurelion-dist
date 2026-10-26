# Memory and context

A model only knows what is in its context. AURELION decides what goes there: your project's instructions, what it remembered from earlier sessions, the facts of this session, and skills it loads when a task calls for one. When the context fills up, it compacts the conversation into a summary and keeps going. This page shows each piece and how to steer it.

## Instructions

At the start of a session, AURELION reads the instruction files from your folder up to the top of the file system:

- `AGENTS.md`
- `CLAUDE.md`
- `.cursorrules`
- `.aurelion/CONTEXT.md`

The nearest file comes last, so the most specific one wins. Up to 8 files are read, at most 16 KB each and 32 KB in all.

A subfolder can have instruction files of its own. They join the context when the agent first touches a file in that subfolder.

In a [trusted folder](modes-and-safety.md#trusted-folders) these files are binding instructions. In a folder you haven't trusted, they are shown to the agent as information from the repository, not as orders.

`/init` writes an `AGENTS.md` for the project, or improves the one there. `/reload` reads the instructions, memory and skills again without a restart.

### Rules for some files only

A rule is a Markdown file with a short header that says when it applies. Put rules in `.aurelion/rules/` in a project, or in `~/.config/aurelion/rules/` for all your projects. A project rule wins over a user rule with the same file name.

```markdown
---
description: Go style
globs: ["*.go", "cmd/**"]
---
Wrap errors with %w. Table tests for every exported function.
```

- `globs`: the rule joins the context whenever the agent touches a matching file.
- `alwaysApply: true`: the rule is always there.

Rules are read fresh on every request, so an edit counts from the next turn. A project's rules load only in a trusted folder.

## Memory

Memory is what AURELION keeps between sessions. It lives in plain files you can read and edit:

| File | What it holds |
| --- | --- |
| `.aurelion/MEMORY.md` | Facts about this project. The agent may fill it up to 6,000 characters. |
| `~/.config/aurelion/USER_MEMORY.md` | Facts for all your projects, up to 3,000 characters. |
| `~/.config/aurelion/USER.md` | What AURELION knows about you: your role, your preferences. You can write it yourself. It is shown to the agent as background, never as instructions. |

The project memory is part of every request, so a change shows in the very next turn. Beside it, `.aurelion/memory.db` holds a searchable store of what was learned.

You can add and remove facts yourself:

```text
/remember the staging database is read-only
/remember --user I prefer small commits
/recall staging
/forget staging
/memory                # list the memory
```

The agent does the same with its `remember`, `recall` and `forget` tools. After each turn, a short side call also files your instructions, the decisions taken and anything worth keeping. `fact_extraction = false` turns that call off; the files changed, commands run and open tasks are still filed.

### Recall

At each turn, AURELION looks up the memories that fit your prompt and adds them to the context. The stream shows a row when it does, such as `⌁ recalled 1 memory · m shows them`.

```toml
[memory]
active_max_tokens = 600   # the most recalled memory per turn; 0 turns recall off
project_char_limit = 6000
user_char_limit = 3000
```

Recall searches by words. To also search by meaning, point AURELION at any OpenAI-compatible embeddings endpoint:

```sh
export AURELION_EMBEDDINGS_URL=https://api.openai.com/v1
export AURELION_EMBEDDINGS_MODEL=text-embedding-3-small   # the default
export AURELION_EMBEDDINGS_KEY=…                          # on api.openai.com, OPENAI_API_KEY works too
```

AURELION then keeps a vector index beside the memory. `[memory] vector = false` turns the index off again.

### Approve memory writes

To see every memory write before it lands:

```toml
[memory]
write_approval = true
```

Writes then wait for you:

```text
/memory pending          # what waits
/memory diff 3           # one write, as a diff
/memory approve 3        # or: approve all
/memory reject all
```

`aurelion memory pending`, `diff`, `approve` and `reject` do the same from the shell.

### Bring memory with you

```sh
aurelion import claude     # Claude Code: memory, skills, MCP servers and settings
aurelion import hermes     # Hermes Agent
aurelion import openclaw   # OpenClaw
```

Each takes `--dry-run` to show the plan first. `/memory import` brings Claude Code's memory for the current project into a session.

### Hosted memory

`[[memory.backend]]` adds an outside memory beside the built-in one. Facts AURELION learns are copied to it, and each turn's recall merges its results. Mem0, Supermemory and Honcho work with only a key, and Hindsight with a server you run:

```toml
[[memory.backend]]
kind = "mem0"                  # or "supermemory", "honcho", "hindsight"
api_key_env = "MEM0_API_KEY"   # the default for mem0
project = "team-x"             # the namespace; default "aurelion", or "aurelion-<profile>" under a profile
```

- The default key variables are `MEM0_API_KEY`, `SUPERMEMORY_API_KEY`, `HONCHO_API_KEY` and `HINDSIGHT_API_KEY`.
- `base_url` points at another server. Hindsight defaults to a server you run yourself, at `http://localhost:8888`.
- `dialectic = true` puts Honcho's own answer about you first in recall.
- `forget` removes only facts that contain your term word for word, and Honcho doesn't support it.
- These follow each service's published API. They are tested against local stand-ins, not yet against the live services.

`kind = "retaindb"` and `kind = "byterover"` talk to those services. `kind = "http"` talks to a server of your own, with a `base_url` that answers `POST /remember`, `POST /recall` and `POST /forget` in JSON.

### Memory and profiles

Each [profile](models.md#profiles) keeps its own user memory: with a profile active, `USER_MEMORY.md` and `USER.md` live in `~/.config/aurelion/profiles/<name>/`. The project memory is shared, unless you set:

```toml
[memory]
profile_isolation = "all"   # "user" is the default; "off" shares everything
```

With `all`, the profile also keeps its own `MEMORY.md` and memory store in `.aurelion/profiles/<name>/`.

## Key facts and pins

**Key facts** are the session's record of what matters: the files changed, the commands run, your instructions in your own words, the decisions taken and why, and the open tasks. They are filed as you go and kept word for word through every compaction.

```text
/facts                    # show them
/facts forget <label>     # remove one
```

**Pins** are text you choose to keep word for word through every compaction:

```text
/pin always target Go 1.22    # pin this text
/pin                          # pin your last message
/pins                         # list them
/unpin 2
```

With the stream focused, `p` pins the selected block.

## Compaction

A long session fills the context window. Compaction replaces the older part of the conversation with a dense summary of the task, the decisions, the state and the next steps. Pins and key facts survive it word for word. The full history stays in the session, so `/branch` and `/tree` still reach every message.

The Ctx tab of the rail shows how full the context is. From 75% it offers a preview: press `c` with the stream or the rail focused to see what a compaction would summarize and what it would keep. In the preview, `c` compacts, `p` lets you pin something first, `f` forks the session instead, and `Esc` closes it.

```text
/compact                      # compact now
/compact the API migration    # steer the summary
/compact --preview            # show the summary without applying it
/compact here 6               # keep the last 6 messages word for word
```

AURELION also compacts on its own:

- **When a request overflows** the model's window: it compacts and runs the turn again. The stream says so.
- **When the context nears the window's edge**: `compact_after_tokens = 0`, the default, means the model's window less room for one full answer and a small margin.
- **After a finished task**, once the conversation has grown large, so the next prompt starts lean.

```toml
compact_after_tokens = 0       # 0: near the model's window; or a token count
compact_on_complete = 120000   # unset: half the model's window, at most 250,000 tokens; 0: off
```

`compact_on_complete` counts the conversation only, not the instructions and tool list. Unset, it is half the model's context window, and never more than 250,000 tokens: 100,000 on a 200,000-token model. A number sets the size yourself, and `0` turns it off. It skips a session whose last compaction freed nothing.

### Compaction by the provider

Anthropic's API and OpenAI's Responses API can compact a conversation on their side. AURELION uses that where it can:

```toml
[compaction]
mode = "auto"                     # auto, native or local
native_threshold_tokens = 150000  # when the provider compacts; at least 50,000
```

- `auto`, the default, uses the provider's compaction on the official endpoints, with AURELION's own compaction as a fallback at 90% of the window.
- `native` asks for it on other endpoints too.
- `local` always uses AURELION's own.

[Hooks](automation.md#hooks) can run before and after a compaction, and a `pre_compact` hook can cancel one.

### A context engine of your own

A [plugin](tools.md#plugins) can take over how the context is built:

```toml
[context]
engine = "plugin:my-engine"   # "default" is the built-in one
```

## Past sessions

Every session is saved as you go, and nothing is lost: a rewind or a branch adds to the session's tree, it never deletes.

```sh
aurelion sessions list                         # newest first
aurelion sessions show 3f2a                    # print a transcript
aurelion sessions export 3f2a --format md -o session.md
aurelion sessions prune --older-than 90 --dry-run
aurelion sessions delete 3f2a
aurelion search "zebra migration"              # full-text search across every session
aurelion insights --days 30                    # sessions, turns, tokens, cost and tools
```

In a session, `/sessions` lists recent ones and `/resume` picks one. The agent searches your past sessions itself with its `session_search` tool: prompts, answers and tool output.

`aurelion share` turns a session into one HTML or Markdown file, with secrets masked:

```sh
aurelion share --last                  # your latest session, as HTML
aurelion share 3f2a --md --include-tools
aurelion share 3f2a --gist             # upload a secret gist (with gh, else GITHUB_TOKEN)
```

`aurelion trajectories export` writes sessions as training data, in ShareGPT, OpenAI or plain JSONL form, with secrets masked.

## Skills

A skill is a Markdown file of know-how for one kind of task: how to debug a flaky test, how to write a release note. The agent sees each skill's name and one-line description, and loads the full text only when a task calls for it, so skills cost little until used.

A skill is a folder with a `SKILL.md`:

```markdown
---
name: release-notes
description: Write release notes from the commits since the last tag
---
List the commits since the last tag with git log. Group them by …
```

AURELION finds skills in these places, the first winning on a name:

1. `.aurelion/skills/<name>/SKILL.md` in the project (in a trusted folder only);
2. `~/.config/aurelion/skills/<name>/SKILL.md`, yours for every project;
3. the folder in `[skills] create_dir`, then the folders in `[skills] external_dirs`, such as a team's shared skills;
4. enabled plugins;
5. the 39 skills built into AURELION.

The built-in skills cover debugging (systematic debugging, Python, Go, Rust, Node, frontend, Docker, Kubernetes, flaky tests, logs, profiling), review and git (code review, security review, simplifying code, safe refactoring, commit messages, pull request descriptions, GitHub issues, release checklists) and project work (test-driven development, API design, decision records, database migrations, dependency upgrades, CI trouble, incident write-ups, safe shell scripts, SQL tuning, diagrams and more).

- `aurelion skills customize <name>` copies a built-in skill into the project (or `--user`) to edit. `aurelion skills reset <name>` goes back to the built-in one.
- `AURELION_NO_BUILTIN_SKILLS=1` turns the built-in skills off.
- `AURELION_OPTIONAL_SKILLS=non-coding` adds five more: email drafting, meeting notes, data analysis with pandas, research summaries and writing.

Use them:

```text
/skills                     # list them
/release-notes v1.4         # run a skill with its instructions
```

```sh
aurelion -s release-notes,github -p "draft the notes for v1.4"   # preload skills for one run
```

### Install skills

```sh
aurelion skills install https://github.com/acme/skills#writing/release-notes
aurelion skills install gh:acme/skills/release-notes --user
aurelion skills install gh:acme/skills --all --rev v2.0
aurelion skills search "terraform" --remote
aurelion skills list                  # what you installed, its pinned commit, and whether it still matches
aurelion skills update                # shows the old and new commit and the file changes first
aurelion skills remove release-notes
```

- A source is a git URL with an optional `#path`, or a shorthand: `gh:owner/repo[/path][@rev]`, `skills.sh:owner/repo/skill`, `clawhub:<slug>` or `hermes:<category>/<skill>`.
- Skills install into the project, or into your user folder with `--user`.
- An install checks the skill's header, refuses text that looks like a prompt injection (unless `--force`), warns about bundled scripts and copies only plain files.
- Each install is pinned to a commit, with a checksum of every file. A skill whose files no longer match is skipped when skills load.
- `update` skips a skill you changed locally, unless `--force`, and never applies an update flagged for prompt injection.
- `AURELION_SKILLS_MIN_TRUST=verified` (or `community`, `official`) sets the lowest trust level a registry skill may have.
- `aurelion skills tap add owner/repo` adds a GitHub repository of skills as a source.

### Skills AURELION learns

AURELION writes skills from experience too:

- After a turn with 8 or more tool calls, a background review looks at what was done and may save a reusable skill, or a note about you to `USER.md`.
- Every 15th prompt carries a reminder to save what is worth keeping.
- `/learn [name] [url or path…] [focus]` turns this session, a web page, a file or a folder into a skill now. `/refine` runs the review on the last turns now.
- The agent's own `skill_manage` tool asks before it creates, changes or deletes a skill.

```toml
[skills]
review = true             # the background review
review_min_tools = 8      # tool calls a turn needs before it is reviewed
review_model = "claude-haiku-4-5"   # unset: the session's model
nudge_interval = 15       # 0 turns the reminder off
write_approval = false    # true: skill writes wait for /skills approve
external_dirs = ["~/team-skills"]
create_dir = "~/brain/skills"       # where new user skills go
```

With `write_approval = true`, `/skills pending`, `diff`, `approve` and `reject` (or `aurelion skills pending` and the rest) review the writes. `/journey` shows a timeline of the skills and memories AURELION learned, and `/journey delete <id>` prunes one.

### Keeping skills tidy

The curator looks after the skills you have: it archives skills that go unused and merges near-duplicates, and either can be undone.

```text
/curator status
/curator run --dry-run      # what it would do
/curator archive old-skill
/curator restore old-skill
/curator rollback
```

```toml
[curator]
enabled = true          # a run when the app starts, at most every interval
interval_hours = 168    # a week
consolidate = false     # true: a model also merges overlapping skills
model = "claude-haiku-4-5"   # for that pass; unset: the small model, else the session's
```

`aurelion curator` takes the same verbs from the shell.

### Bundles and settings

A bundle loads several skills at once with `/<bundle>`. `aurelion skills bundle create` makes one in `~/.config/aurelion/skill-bundles/`, and `/bundles` lists them.

Some skills declare settings. Set them by key:

```toml
[skills.config]
"ddg.region" = "de-de"
```

## The wiki

For notes that grow with a project, the deferred wiki tools keep linked Markdown pages in `.aurelion/wiki/`. `wiki_read`, `wiki_search` and `wiki_list` read them, and `wiki_write`, which asks first, writes them.

**Next:** [Automation](automation.md)
