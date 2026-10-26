# Keys

AURELION works from the keyboard, with the mouse as a shortcut. This page has every key: first the key list the app itself shows, then the full keymap for each place the keys can be.

## How focus works

Press `?` on an empty prompt, or `F1`, to open the key list in the app. Which keys act depends on where the focus is:

- **The prompt**, where you type. It has the focus by default.
- **The stream**, the conversation. `Esc` on an empty, idle prompt, or `Tab`, gives it the keys.
- **The rail** and the other panes. `Tab` moves on to them.
- **The review pane**, when you review an edit.
- **A card**, an approval or a question that waits for your answer.

Single letters and digits never act in the prompt: they are text. The stream, the review and the layouts take them only while the prompt is empty. The rail keeps them even over a draft, so you can answer a card without losing what you typed.

## The key list

This is what `?` shows, with each key explained. `Esc`, `F1` or `Ctrl+C` closes it.

### Input

| Key | What it does |
| --- | --- |
| `enter` | Send the prompt. On an empty prompt, open the last tool row. |
| `shift+enter · alt+enter · ctrl+j` | A new line in the prompt. |
| `esc` | Stop the turn, deny an approval, or step back. |
| `ctrl+r` | Search your prompt history. Press it again for an older match; `enter` recalls it. |
| `y / n / A` | Answer an approval: yes, no, or always. For a file tool, always covers its whole folder. |

### Navigation

| Key | What it does |
| --- | --- |
| `tab · alt+1–6` | `tab` moves to the next pane. `alt` with a digit picks a rail tab from anywhere. |
| `↑↓ · enter` | In the Workers pane: pick a worker, then open its session in an inspector. |
| `j k · y r b p · u U · m` | In the stream: select a block, copy it, rerun it, branch at it, pin it, undo the last turn or every turn from it, and list what a turn recalled. |
| `ctrl+e · F5 F6` | Show or hide the side panes. Collapse or expand the left or the right one. |
| `F7` | Dictation: press to record, press again to transcribe. `esc` cancels. |
| `f2 · f3 · f4 · f8 · ctrl+o` | The main, thinking, tools and flow views. `ctrl+o` cycles them. |
| `ctrl/alt+← →` | Jump a word. `ctrl+w` deletes one. |
| `ctrl+v` | Attach the image on the clipboard. |
| `ctrl+t` | Expand or collapse the thinking. |
| `ctrl+x ctrl+e` | Edit the prompt in `$VISUAL` or `$EDITOR`, like `/prompt`. |
| `pgup pgdn end` | Scroll the stream. `end` jumps to the tail and follows it. |
| `wheel · drag` | Scroll the pane under the pointer. Select text; it is copied when you let go. |
| `click` | Tabs, panes, the mode chip, key hints and tool rows act like their keys. |
| `↑↓ · 1–6 ← →` | Scroll a pane. Pick a rail tab. On the Inbox, press a card's number, then `y`, `A` or `n`. |
| `enter · s · i` | In the rail: open the item, stage a file (Changes), or hide the compaction offer (Ctx). |

### Session

| Key | What it does |
| --- | --- |
| `shift+tab` | Cycle the mode: plan → auto → ask. Bypass is outside the cycle; see [Modes and safety](modes-and-safety.md). |
| `c · then c p f` | From 75 % context, in the stream or the Ctx tab: preview compaction. Then compact, pin first, or fork. |
| `ctrl+c` | Stop the turn. When idle, quit. |
| `ctrl+d` | On an empty prompt, quit and print the session's summary. Otherwise, delete a character. |
| `a x c · n p · ] [` | After `enter` on an Edit row: accept, revert or comment a hunk, move by hunk, move by file. |
| `` /layout · ` · t `` | Pick a layout. In Focus, `` ` `` hides the drawer. In Split, `t` shows the tool calls. |
| `alt+1–5 (focus)` | The Focus drawer's tabs: workers, review, inbox, changes, ctx. |
| `ctrl+k` or `/` | Browse every command, grouped, with descriptions. |

## The prompt

| Key | What it does |
| --- | --- |
| `Enter` | Send. On an empty prompt, open the last tool row. While a card waits, a draft is never sent. |
| `Shift+Enter` · `Alt+Enter` · `Ctrl+J` | A new line. On a terminal that can't tell `Shift+Enter` apart, end the line with `\` and press `Enter`. |
| `Esc` | Stop a running turn. Clear the draft. On an empty, idle prompt, give the keys to the stream (or to an open review). In bash mode, leave it. |
| `Ctrl+C` | Stop a running turn. Clear the draft; press it again to quit. Quit when idle and empty. Over the key list, a picker or the compaction preview, close it. |
| `Ctrl+D` | Delete the character under the cursor. On an empty prompt, end the session and print its summary. |
| `Shift+Tab` | Cycle the mode: plan → auto → ask. See [Modes and safety](modes-and-safety.md). |
| `↑` `↓` | Your prompt history. On the welcome screen, pick a session to resume; `Enter` resumes it. |
| `Ctrl+R` | Search your prompt history. Type to filter, `Ctrl+R` again for an older match, `Enter` to recall it without sending, `Esc` to restore your draft. |
| `/` · `Ctrl+K` | The command palette. With a suggestion open, `Tab` accepts it. |
| `@` | On an empty prompt, the file picker: type to filter, `Enter` attaches the path. |
| `!` | On an empty prompt, bash mode: `Enter` runs the line as a shell command and pins its output. |
| `?` · `F1` | The key list (`?` on an empty prompt). |
| `Ctrl+V` | Attach the image on the clipboard. `Alt+V` works too. |
| `Ctrl+X` `Ctrl+E` | Write the prompt in `$VISUAL` or `$EDITOR`, starting from what you typed. Same as `/prompt`. |
| `Ctrl+W` · `Ctrl`/`Alt`+`Backspace` | Delete the word before the cursor. |
| `Ctrl`/`Alt`+`←` `→` · `Alt+B` `Alt+F` | Jump a word. |
| `Ctrl+A` · `Home` | Go to the start of the line. |
| `F7` | Dictation: press to record, press again to transcribe into the prompt at the cursor. It is never sent on its own. `Esc` cancels, and it stops after 120 seconds. Release builds have no microphone support and say so. |

Pasting is always text. A pasted newline never sends anything.

## The stream and the panes

| Key | What it does |
| --- | --- |
| `F2` · `F3` · `F4` · `F8` · `Ctrl+O` | The main, thinking, tools and flow views. `Ctrl+O` cycles them. |
| `Ctrl+T` | Expand or collapse the thinking. |
| `Ctrl+E` | Show or hide the side panes. |
| `F5` · `F6` | Collapse or expand the left or the right sidebar. The `«` `»` buttons and `/layout left`, `right`, `both` or `reset` do the same. |
| `PgUp` · `PgDn` · `Ctrl+U` · wheel | Scroll the stream. |
| `End` · `Ctrl+L` | Jump to the tail and follow it. |
| `Tab` | With an empty prompt, move the focus: the stream first, then the panes on screen. |
| `Alt+1` to `Alt+6` | Pick a rail tab from anywhere. In the narrow layout, its tabs; in Focus, the drawer's. |
| click | Tabs, panes, the mode chip and the key hints act like their keys. A tool row opens or closes. |
| drag | Select text. It is copied when you let go. |

## Stream focus

`Esc` on an empty, idle prompt, or `Tab`, gives the stream the keys.

| Key | What it does |
| --- | --- |
| `j` `k` · `↓` `↑` | Select a block of the conversation. |
| `y` | Copy the selected block. |
| `r` | Rerun the selected prompt, like `/rerun`. |
| `b` | Branch at the end of the selected block's turn, like `/branch`. |
| `Enter` | Open the selected block. |
| `p` | Pin the selected prompt or answer, word for word, across compaction. |
| `u` | Undo the last turn: its files go back, the conversation stays. `u` again takes the undo back. See [Undo and review](undo-and-review.md). |
| `U` | Undo every turn from the selected block's on. |
| `m` | List what a turn recalled: facts, pins, memories. |
| `c` | From 75 % context, preview what `/compact` would summarize and keep. |
| `1` to `6` | Show that rail tab and give it the keys. |
| `?` | The key list. |
| `Esc` | Give the keys back to the prompt. Any key that would type does the same, and is typed. |

## The rail

`Tab`, a digit from the stream, a click, or `Alt+1` while a card waits gives the rail the keys.

| Key | What it does |
| --- | --- |
| `1` to `6` · `←` `→` | Inbox, Changes, Ctx, Jobs, Model, MCP. The tab you pick is kept. |
| `j` `k` · `↓` `↑` · `PgUp` `PgDn` | Move between entries, or scroll. |
| `Enter` | Inbox: open the item. Changes: review the file. Jobs: acknowledge a failed cron run, or show a kanban card. |
| `s` | Changes: stage the selected file. |
| `c` · `i` | Ctx, from 75 % context: preview compaction, or hide the offer until the gauge drops. |
| `Esc` | Let go of the picked card, then give the keys back to the prompt. |

### The compaction preview

`c` in the stream or the Ctx tab opens it, between turns only. It shows what `/compact` would summarize and what it would keep word for word.

| Key | What it does |
| --- | --- |
| `c` | Compact now. |
| `p` | Pick a prompt or an answer to pin first. |
| `f` | Fork into a compacted copy of the session instead. |
| `Esc` | Close the preview. |

## The workers pane

| Key | What it does |
| --- | --- |
| `↑` `↓` | Pick a worker. |
| `Enter` | Open the worker's session in the inspector. |

In the inspector, `j` `k` and the arrows scroll, `PgUp` `PgDn` page, `g` and `G` jump to the top and the bottom, `r` refreshes, and `Esc` or `q` closes it.

## The review pane

`Enter` on an Edit row, or on a file in Changes, opens it.

| Key | What it does |
| --- | --- |
| `n` `p` · `j` `k` · `↓` `↑` | Next or previous hunk. |
| `]` `[` | Next or previous file. |
| `a` | Accept the hunk. |
| `x` | Revert the hunk on disk. It refuses while a turn runs, or when the file changed since the review read it. |
| `c` | Comment: the prompt fills with `@file:line` (`to <worker>: @file:line` for a worker's edit). It goes to the lead agent like any prompt. |
| `Esc` | Close the review. |

## Layouts

`/layout` alone lists them. These keys act only with the stream or a pane focused, never while you type.

| Key | What it does |
| --- | --- |
| `` ` `` | Focus: hide or show the drawer. |
| `1` to `5` · `←` `→` | Focus: the drawer's tab (workers, review, inbox, changes, ctx), or walk the tabs. |
| `t` | Split: show or fold the tool calls. |
| `1` to `5` | Narrow (under 100 columns): that tab. `5` again moves `more` on through ctx, jobs, model and MCP. |

## The flow view

| Key | What it does |
| --- | --- |
| `←` `→` | Step the replay 5 seconds. |
| `Shift+←` `→` | Jump to the previous or next event. |
| `Space` | Play or pause, with the stream focused. |
| `End` | Back to live. |

With the prompt empty, the arrows and `End` work from the prompt too.

## Approval and question cards

A card stays on screen until you answer it. In the wide layout it waits in the rail's Inbox, and Focus's drawer and Cockpit's right column carry it the same way. Where there is no rail (the 100 to 139 column dock, the narrow layout, the split layout), it shows over the stream.

| Key | What it does |
| --- | --- |
| `y` | Allow once. |
| `Shift+A` | Always allow. Only when the card offers it; a bare `a` does nothing. |
| `n` | Deny. |
| `Esc` | Clear a draft first, then deny. On a question, clear its answer box, then dismiss it. The next `Esc` stops a running turn. |
| `↑` `↓` `PgUp` `PgDn` | Scroll the card. On a question, move the highlight. |
| a number · `Enter` | On a question: pick that option, or confirm the highlighted one. |
| `Ctrl+C` | Stop the running turn. |

Cards guard against stray keys:

- A card answers only after it has been on screen for 400 ms **and** your keys have paused for 400 ms. Until then, what you type or paste goes into the prompt, the editing keys edit it, the arrows scroll the card, and other keys and clicks do nothing.
- Only the keys above, pressed alone, answer. No digit picks an approval, and nothing held with `Ctrl`, `Alt` or `Cmd` does.
- Typing in the prompt never answers a card. A draft is kept while you answer, and `Enter` never sends it while a card waits.
- On a question, typing starts its answer box when the prompt is empty. With a draft, `↓` or `Tab` moves to the box and the draft stays. `Enter` sends the answer.
- In the Inbox, give the rail the keys first (`Tab`, `Alt+1`, or a click; `Alt+3` in Focus's drawer), press the card's number, then `y`, `A` or `n`.
- When the key list or a picker covers a card, the card shows on top and takes every key, paste and click until you answer it.

**Next:** [Commands](commands.md)
