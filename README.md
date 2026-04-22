# wt — Interactive Git Worktree Dashboard

Browse, manage, and navigate git worktrees with an fzf-powered TUI.

`wt` targets macOS, Linux, and WSL environments where Bash, Git, and fzf are
available.

## Features

- **Interactive dashboard** — Browse all worktrees with fzf split panel
- **Always-on multi-select** — `Space`, `Tab`, and `Shift-Tab` build a trusted target set without leaving the list
- **Rich preview** — Branch info, recent commits, submodule status, working tree changes
- **Keyboard-driven** — Create, delete, pull, and open worktrees without leaving the TUI
- **Submodule-aware** — Shows sync status for repos with submodules
- **Fast startup** — Opens from cheap `git worktree` metadata first, then fills in latest-activity rows in the background
- **Adaptive layout** — Keeps the worktree path visible in the list and moves the preview below on narrower terminals
- **Shell integration** — Press Enter to cd directly into a worktree
- **Minimal dependencies** — bash, git, fzf, and standard POSIX utilities

`wt` now relies on `fzf` support for `--id-nth` and `--info-command`. The
selection model in this README was verified against `fzf 0.71.0`.

## Install

### Manual

```bash
# Install dependencies first
# macOS or Linux with Homebrew
brew install git fzf

# Debian / Ubuntu / WSL
sudo apt install git fzf

# Fedora
sudo dnf install git fzf

# Arch
sudo pacman -S git fzf

# Clone
git clone https://github.com/ashwch/wt.git
cd wt

# Add to PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$PWD/wt" "$HOME/.local/bin/wt"

# Ensure ~/.local/bin is on PATH in your shell rc if needed.

# Add shell integration
echo 'source /path/to/wt/share/wt/wt.zsh' >> ~/.zshrc   # zsh
echo 'source /path/to/wt/share/wt/wt.bash' >> ~/.bashrc # bash
```

### Homebrew

```bash
brew install ashwch/tap/wt
```

The Homebrew formula already declares `git` and `fzf` as dependencies, so
Homebrew installs them automatically on macOS and Linux.

## Usage

```bash
wt                  # Auto-detect repo from $PWD
wt /path/to/repo    # Explicit repo path
wt -h               # Show help
wt --version        # Show version
```

## Dependency Model

The dependency story is intentionally simple:

- `git` is the source of truth
- `fzf` is the interactive UI shell
- everything else stays in normal Unix userland

Why keep it that way:

- `wt` is a small shell tool, not a package manager
- runtime dependencies are easier to trust when they are explicit
- Homebrew can install them for you automatically
- manual installs stay transparent on Linux and WSL

When a dependency is missing, `wt` now tries to tell you the next useful step
instead of only saying "command not found".

Examples:

```bash
# Missing fzf on a Homebrew machine
error: fzf is required for the interactive dashboard. Install it with: brew install fzf

# Missing git on a generic Unix machine
error: git is required for repository inspection. Install it with: https://git-scm.com/downloads
```

That behavior exists for one reason: a dependency error should answer "what do
I do now?" immediately.

## Platform Support

`wt` is designed around "plain Unix shell plus Git" so the intended targets are:

- macOS
- Linux
- WSL

That is why the repository now ships both shell wrappers:

```bash
# bash
source ~/path/to/wt/share/wt/wt.bash

# zsh
source ~/path/to/wt/share/wt/wt.zsh
```

Why two wrappers instead of one:

- the shell has to perform the final `cd`
- that means the wrapper has to live inside the current shell
- bash and zsh have different "normal" integration points, so both are first-class

Both wrappers follow the same rule:

- if `wt` returns a directory, `cd` there
- if `wt` fails, preserve the real exit status
- if `wt` prints a non-directory string, echo it unchanged
- before falling back to `PATH`, try the `wt` executable shipped next to the same clone or Homebrew prefix

## Responsive Layout

The dashboard layout is driven by one simple rule:

`wt` must keep the worktree identity readable before it spends width on extra
detail.

In practice that means:

- the path wins over the commit subject
- startup speed wins over eagerly loading rich metadata for every worktree
- richer activity data can arrive after the UI is already open
- readability wins over strict column alignment

### List layout: path first, detail second

The list row is intentionally ordered like this:

```text
[icon] [worktree path] [branch or state]
```

Why:

- The path answers the first question a user has: "Which worktree is this?"
- Branch/state is useful and cheap because it already comes from `git worktree
  list --porcelain`.
- Commit activity is useful too, but expensive because it requires extra `git
  log` work across worktrees and, in monorepos, often across submodules too.
- Most worktrees are siblings of the main checkout, so `wt` strips that base
  directory when it can and then middle-truncates the remainder to preserve
  both the family and the unique tail.
- If one worktree lives somewhere unusual, `wt` leaves that row as a shortened
  absolute path instead of making every other row worse too.

Example:

```text
feature-branch…e-to-test-width   main
```

That is more useful than only showing the left side and hiding the part that
usually makes one worktree different from another.

### Startup model: cheap list first, richer list later

`wt` now follows this performance rule:

- The list should be fast enough to open immediately.
- Expensive work should happen after the UI is already usable.
- The preview can still be richer because it only runs for the currently
  highlighted row.

So the expensive data is split like this:

- The initial list uses only cheap `git worktree list --porcelain` metadata.
- A background worker then builds a richer top list with latest activity and
  re-sorts the worktrees by newest update when that data is ready.
- The preview still does the heaviest per-worktree detail work:
  latest commits timeline, submodule details, and working tree summaries.

To make that behavior legible in the UI:

- the list starts with a `worktrees · branch/state` label
- while the richer list is being prepared, the label changes to
  `worktrees · loading activity...`
- once the background refresh lands, the label changes to
  `worktrees · latest activity`
- if a selection is active when the richer list finishes building, `wt`
  defers applying it until the selection clears so the target set does not
  shift under the user mid-action

This is also a compatibility story, not just a speed story:

- On newer `fzf` builds that support `--listen`, `wt` can refresh the list in
  place after startup.
- `wt` now depends on stable identity tracking support from `fzf`
  (`--id-nth`) so selection-aware reloads stay trustworthy.
- If `--listen` is unavailable, you still keep the fast branch/state list and
  the rich per-row preview, just without the automatic in-place upgrade.

If multiple refreshes are triggered quickly, `wt` only accepts the newest
background result. Older in-flight refreshes are discarded so the list does not
jump backward to stale data.

That keeps startup tied to cheap porcelain data instead of blocking on hundreds
of `git log` calls before the UI appears.

### Why there are two list commands

You will now see both of these in the code:

```bash
./wt --list /path/to/repo
./wt --list-activity /path/to/repo
```

They are intentionally different.

`--list`:

- cheap
- startup-safe
- only uses `git worktree list --porcelain`
- good for "open the dashboard now"

`--list-activity`:

- more expensive
- does extra `git log` work
- may inspect submodules too
- good for "now that the UI is open, upgrade the list"

Why split them instead of making one smarter command:

- the startup path should stay boring and fast
- expensive per-worktree history calls should be opt-in
- keeping the two paths separate makes performance decisions visible in code

### Preview layout: wide terminals split sideways, narrow terminals stack

Wide terminal:

```text
+---------------------------+---------------------------+
| worktree list             | preview                   |
| icon path branch/state    | worktree                  |
| ...                       | branch                    |
| ...                       | latest activity           |
| ...                       | submodules / working tree |
+---------------------------+---------------------------+
```

Narrow terminal:

```text
+-------------------------------------------------------+
| worktree list                                         |
| icon path branch/state                                |
| ...                                                   |
+-------------------------------------------------------+
| preview                                               |
| worktree                                              |
| branch                                                |
| latest activity                                       |
| submodules / working tree                             |
+-------------------------------------------------------+
```

Why:

- A right-side preview works well on wide terminals because both panes still
  have enough columns to stay legible.
- On narrower terminals, a side preview steals too much width from the list.
- Once that happens, both panes get worse at the same time, so `wt` moves the
  preview below the list.

The exact breakpoint numbers live in `choose_preview_window()` in [wt](./wt),
but the design rule is more important than the specific thresholds: preserve
the identifying path column first, then place the preview where it can still
read cleanly.

### Preview formatting: columns when possible, stacked blocks when necessary

The preview uses the same first-principles rule as the list:

- If the preview pane is wide enough, `wt` renders one-line activity and
  submodule rows because they are faster to scan.
- If the preview pane is narrow, `wt` switches to stacked multi-line rows so
  hashes, paths, and subjects do not collide or wrap into each other.

This is why the same worktree can look different in a wide preview versus a
narrow preview. The content is the same; only the reading shape changes.

### How to test the layout without opening the full TUI

Use these commands when changing the layout logic:

```bash
# See the raw list row formatting
./wt --list /path/to/repo

# See the richer activity-sorted list used by the async background refresh
./wt --list-activity /path/to/repo

# Render the preview as if fzf gave it a narrow pane
FZF_PREVIEW_COLUMNS=40 ./wt --preview /path/to/worktree

# Render the preview as if fzf gave it a wider pane
FZF_PREVIEW_COLUMNS=100 ./wt --preview /path/to/worktree

# Measure list startup cost directly
hyperfine --warmup 1 './wt --list /path/to/repo >/dev/null'
```

`FZF_PREVIEW_COLUMNS` is normally set by `fzf` itself. Setting it manually is a
cheap way to test preview rendering without launching the interactive UI.

## CI And Workflow Security

The GitHub Actions setup now follows the same first-principles model as the CLI:

- keep normal CI readable
- keep workflow security explicit
- keep permissions narrow

There are three workflows to know about:

### `ci.yml`

Purpose:

- shell lint and syntax checks
- smoke tests on macOS and Linux
- smoke test coverage for WSL on a Windows runner

Why the matrix now includes WSL:

- "Unix-like" support claims are easy to overstate
- WSL has enough edge cases around paths and shells to deserve its own job
- a dedicated job is cheaper than learning about WSL breakage from users later

### `release.yml`

Purpose:

- build the release tarball from the tag
- publish the GitHub release

Why it now uses `gh release create` directly:

- fewer third-party Actions in the release path
- easier for humans to understand and reproduce locally
- one less moving part for security review

Equivalent local command shape:

```bash
gh release create "vX.Y.Z" --generate-notes "wt-X.Y.Z.tar.gz"
```

### `workflow-security.yml`

Purpose:

- check that Actions stay pinned to immutable SHAs
- audit workflow files for common GitHub Actions security mistakes

Why this exists as a separate workflow:

- workflow files are executable infrastructure
- their security drift should fail CI just like code drift
- security review is easier when the gate has one focused job

The two tools it runs are:

```bash
GITHUB_TOKEN="$(gh auth token)" pinact run --check --verify --diff
zizmor --persona regular .github/workflows .github/actions
```

Why both:

- `pinact` answers "are we pinned correctly?"
- `zizmor` answers "are we using workflows safely?"

### Security rules the workflows now follow

- top-level permissions are read-only unless a job truly needs more
- Actions are pinned by commit SHA, not floating tags
- `actions/checkout` uses `persist-credentials: false` unless credentials are actually needed
- the workflow-security gate is read-only and never rewrites anything

Those rules are there to make the workflows easier to reason about, not just to
check a compliance box.

## Useful Commands

If you are changing the new code paths, these commands are the shortest way to
recreate the intended checks locally:

```bash
# Shell correctness
bash -n wt
shellcheck -S error wt share/wt/wt.bash share/wt/wt.zsh

# Fast list vs richer list
./wt --list /path/to/repo
./wt --list-activity /path/to/repo

# Preview width behavior
FZF_PREVIEW_COLUMNS=48 ./wt --preview /path/to/worktree
FZF_PREVIEW_COLUMNS=100 ./wt --preview /path/to/worktree

# Workflow security
GITHUB_TOKEN="$(gh auth token)" pinact run --check --verify --diff
zizmor --persona regular .github/workflows
```

## Keybindings

Multi-selection is always on. The dashboard starts in the familiar
zero-selection mode, but the moment anything is selected it becomes
selection-targeted:

- `Ctrl-P` and `Ctrl-X` operate on the selected set
- `Enter`, `Ctrl-O`, `Ctrl-N`, and `Ctrl-R` are disabled until selection clears
- `Space` only toggles selection when the query is empty; otherwise it types a literal space
- `Tab` and `Shift-Tab` always toggle selection and move

| Key | Action |
|-----|--------|
| `Space` | Toggle selection when the query is empty |
| `Tab` / `Shift-Tab` | Toggle selection and move |
| `Enter` | cd into the focused worktree when no selection is active |
| `Ctrl-O` | Open the focused worktree in `$EDITOR` when no selection is active |
| `Ctrl-P` | Pull the focused worktree or all selected worktrees |
| `Ctrl-N` | Create a new worktree from the focused row when no selection is active |
| `Ctrl-X` | Delete/prune the focused worktree or all selected worktrees |
| `Ctrl-R` | Refresh the list when no selection is active |
| `Ctrl-/` | Toggle preview panel |

The left state column is now rendered directly into each visible row instead
of using fzf's separate pointer and marker columns. That gives each row one
clear state glyph instead of stacked symbols:

- `□` ordinary row
- `■` selected row

Focus is shown by the normal row highlight, not by adding a second symbol into
the state cell.
The row body itself does not use a second icon language anymore. Current,
detached, prunable, and locked states are conveyed through row color plus the
dim right-hand label instead of sprinkling extra symbols into some rows.

## Selection Model

The multi-select behavior is easiest to understand if you think in terms of
target sets instead of keys.

There are only three real target modes:

```text
No selection + focused row        => target = focused row
Active selection                  => target = selected rows
No selection + no focused match   => target = nothing
```

Why model it this way:

- the old dashboard was always "focused row"
- always-on multi-select adds a real second target mode
- a zero-match query is not "focused row" or "selected rows"; it is "nothing"

That is why `wt` now has dispatch helpers in the code instead of putting all
the logic inline in the fzf bind strings. Every action answers the same
question first:

```text
What is the target set right now?
```

And every visible row answers a second question directly in the UI:

```text
What is this row's current state cell right now?
```

That row-state cell is now custom-rendered in the row text, not delegated to
fzf's native pointer/marker columns. We took that route because native fzf
always draws focus and selection in separate columns, which made the left edge
look noisy and impossible to tune into a clean "empty box / filled box"
language.

### Why hidden field 1 matters

Each list row still starts with the canonical worktree path in hidden field 1.

```text
[field 1: canonical path]  [field 2: visible row text]
```

Why keep that hidden identity field:

- the visible row can change shape when activity data arrives
- row order can change after the async activity refresh
- the worktree path is the stable identity that survives those changes

That is why `wt` now asks fzf to track identity with `--id-nth=1`.

### Why the state cell is custom-rendered

The leftmost state cell is no longer fzf's own pointer or marker.

Why:

- native fzf draws focus and selection in separate columns
- that means you get stacked symbols instead of one coherent state cell
- the UI we wanted was one state glyph per row, not "pointer plus marker plus row icon"

So `wt` now keeps:

- a base list file with stable hidden identity in field 1
- a rendered list file that prepends exactly one state glyph to field 2
- a small render signature so focus and selection changes only redraw the list
  when the visible state actually changed

### Why bulk actions use `{+f}`

Bulk actions do not receive selected rows as inline argv expansion.
They receive a temp file path from `{+f}`.

Why:

- selected sets can be long
- inline argv expansion can hit shell length limits
- one temp file keeps the downstream shell code simple and deterministic

You can inspect what fzf passes with commands like:

```bash
# Show the raw list rows, including the hidden field-1 separator (^_)
./wt --list /path/to/repo | sed -n 'l'

# Simulate a selected-row temp file and preview how wt will interpret it
tmp=$(mktemp)
./wt --list /path/to/repo | head -2 > "$tmp"
FZF_SELECT_COUNT=2 ./wt --preview-dispatch "$tmp" /path/to/focused
rm -f "$tmp"
```

### Why refresh is deferred under selection

The async activity refresh still builds in the background, but `wt` no longer
blindly applies it as soon as it is ready.

Why not:

- activity refresh can reorder the list
- reordering while the user is building a selected set undermines trust
- preserving identity is necessary, but it is not the whole UX story

So the rule is:

```text
activity data ready + no active selection  => apply refresh now
activity data ready + active selection     => mark refresh as pending
selection clears                           => apply the pending refresh
```

That design keeps startup fast without making selection feel slippery.

### Internal debug commands

These commands are useful when reading or modifying the selection code:

```bash
# Raw startup list (cheap path)
./wt --list /path/to/repo

# Activity-sorted list (expensive path)
./wt --list-activity /path/to/repo

# Rich single-row preview
./wt --preview /path/to/worktree

# Selection-aware preview dispatcher
tmp=$(mktemp)
./wt --list /path/to/repo | head -2 > "$tmp"
FZF_SELECT_COUNT=2 ./wt --preview-dispatch "$tmp" /path/to/focused
rm -f "$tmp"

# Bulk pull and bulk delete consume selected rows from a temp file
tmp=$(mktemp)
./wt --list /path/to/repo | head -2 > "$tmp"
FZF_SELECT_COUNT=2 ./wt --action-pull "$tmp" /path/to/focused
FZF_SELECT_COUNT=2 ./wt --action-delete-targets "$tmp" /path/to/focused /path/to/repo
rm -f "$tmp"
```

## Delete Behavior

`Ctrl-X` is intentionally conservative first, then pragmatic if Git leaves a
half-deleted tree behind.

Think about worktree deletion as two separate jobs:

1. Git metadata cleanup
   Git has to forget that the worktree exists.
2. Filesystem cleanup
   The actual directory on disk has to disappear.

Most of the time, Git can do both in one step with `git worktree remove`.
The tricky cases are when the worktree contains unreadable directories,
restrictive ACLs, macOS file flags, or files that appear while deletion is in
progress. In those cases Git may update some state, fail partway through, and
leave behind a stale path.

`wt` handles deletion with that model in mind:

- Clean worktree:
  `Ctrl-X` asks for `y`, then tries `git worktree remove`.
- Dirty worktree:
  `Ctrl-X` shows the first few changes and requires typing `delete`.
- If Git leaves unreadable leftovers behind:
  `wt` re-checks whether force cleanup is still safe. If status is known, it
  can continue; if status can no longer be verified, it fails closed and asks
  you to type `delete` before repairing permissions, clearing ACLs, clearing
  macOS immutable flags when available, and retrying removal.
- If the directory is already gone:
  `wt` offers to prune the stale worktree entry from Git metadata.
- If the directory still exists but Git marks the entry `prunable`:
  `wt` treats it as a stale leftover directory, offers to prune the metadata,
  and then removes the leftover files on disk.

### Stale leftover directories

This is an easy state to misunderstand, so it is worth naming clearly.

You can have a path that:

- still exists on disk
- is no longer a valid Git worktree
- is already marked `prunable` by `git worktree list --porcelain`

That usually means the worktree's `.git` file or admin metadata is broken or
missing. In that state, normal `git -C /path status` checks fail even though
the directory is still there.

`wt` now treats Git's `prunable` state as authoritative. If Git says the entry
is stale, `Ctrl-X` behaves like "prune stale metadata, then remove leftover
files if they still exist".

Example debugging commands:

```bash
# See whether Git already considers the worktree stale
git -C /path/to/repo worktree list --porcelain

# Check whether the leftover directory still has a valid .git link
ls -la /path/to/worktree/.git
cat /path/to/worktree/.git

# Prune stale metadata from a surviving checkout of the same repo
git -C /path/to/repo worktree prune --expire now
```

Some delete refusals are intentional:

- The main worktree cannot be removed.
- The worktree you are currently standing in cannot be removed.
- Locked worktrees cannot be removed until you unlock them.

### Why the extra confirmation exists

A worktree can be clean when the preview is rendered and dirty a moment later.
For example, a tool may generate files while you are looking at the list.

Because of that, `wt` does not treat a failed "clean" delete as safe to force.
If `git worktree remove` says the worktree now has changes, `wt` re-checks the
status and asks you to type `delete` before doing direct filesystem cleanup.

### Useful commands when debugging deletion

If a path still refuses to disappear, these commands explain why:

```bash
# Show mode bits, ACLs, and macOS flags
ls -ldOe /path/to/worktree /path/to/worktree/*

# Find entries not owned by your user
find /path/to/worktree ! -user "$USER" -print

# Show a quick sample of the remaining tree
find /path/to/worktree -mindepth 1 -maxdepth 2 -print | head

# Remove stale Git metadata from any surviving checkout of the same repo
git -C /path/to/another/checkout worktree prune --expire now
```

## Icons

| Icon | Meaning |
|------|---------|
| `□` | Ordinary row in the selection state column |
| `■` | Selected row in the selection state column |

Current, detached, prunable, and locked are now shown by row color plus the
dim label text, not by additional body icons.

## Shell Integration

Source the wrapper for your shell for cd support. When you press Enter on a
worktree, the shell will `cd` into that directory instead of just printing the
path. The wrappers first look for the sibling `wt` executable from the same
clone or Homebrew prefix, then fall back to `PATH`.

```zsh
# zsh via Homebrew on macOS or Linux
source "$(brew --prefix)/share/wt/wt.zsh"

# zsh via manual clone
source ~/path/to/wt/share/wt/wt.zsh
```

```bash
# bash via Homebrew on macOS or Linux
source "$(brew --prefix)/share/wt/wt.bash"

# bash via manual clone
source ~/path/to/wt/share/wt/wt.bash
```

## Requirements

- **git** — any modern version
- **fzf** — 0.38+ (uses `become()`)
- **bash** — 3.2+ (ships with macOS)
- **coreutils** — awk, sed, sort, cut, head, date (standard on macOS/Linux)

## License

MIT
