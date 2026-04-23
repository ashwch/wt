# Development Notes

This document keeps the deeper implementation notes out of the top-level
README while preserving the reasoning future maintainers will need.

## Dependency Model

The dependency story is intentionally simple:

- `git` is the source of truth
- `fzf` is the interactive UI shell
- everything else stays in normal Unix userland

Why keep it that way:

- `wt` is a small shell tool, not a package manager
- runtime dependencies are easier to trust when they are explicit
- Homebrew can install them automatically
- manual installs stay transparent on Linux and WSL

When a dependency is missing, `wt` tries to answer the next useful question
immediately: "what should I install now?"

## Platform Support

`wt` is designed for:

- macOS
- Linux
- WSL

That is why the repo ships both shell wrappers:

```bash
source ~/path/to/wt/share/wt/wt.bash
source ~/path/to/wt/share/wt/wt.zsh
```

## Layout And Rendering

### First principles

The dashboard layout is driven by one simple rule:

```text
Keep worktree identity legible before spending width on extra detail.
```

In practice that means:

- the path wins over the commit subject
- startup speed wins over eager rich metadata
- the preview can be heavier because it is lazy
- readability wins over strict pseudo-table alignment

### Two list paths

`wt` intentionally has two list commands:

```bash
./wt --list /path/to/repo
./wt --list-activity /path/to/repo
```

`--list` is the cheap startup path.

`--list-activity` is the slower, richer path that runs after the UI is already
usable.

Why split them:

- startup should stay boring and fast
- richer history lookup is valuable, but it is not startup-critical
- keeping the paths separate makes the cost visible in code

### Preview placement

Wide terminals get a side preview.
Narrower terminals move the preview below the list.

Why:

- side-by-side only works if both panes still have room to read cleanly
- below-the-list is better than making both panes cramped at once

The exact thresholds live in `choose_preview_window()` in [wt](../wt).

## Selection Model

Multi-selection is easiest to understand in terms of target sets:

```text
No selection + focused row        => target = focused row
Active selection                  => target = selected rows
No selection + no focused match   => target = nothing
```

Why model it this way:

- the old dashboard was always "focused row"
- always-on multi-select adds a real second target mode
- a zero-match query is neither "focused row" nor "selected rows"

That is why `wt` resolves action targets in shell helpers instead of trying to
encode all branching inside raw fzf bind strings.

### Hidden field 1

Each list row still starts with the canonical worktree path in hidden field 1:

```text
[field 1: canonical path]  [field 2: visible row text]
```

Why hidden field 1 matters:

- visible rows can change shape after refresh
- row order can change after activity sorting
- the path is the stable identity across those changes

That is why `wt` uses `--id-nth=1`.

### Custom state cell

The leftmost state cell is no longer fzf's own pointer or marker.

Why:

- native fzf draws focus and selection in separate columns
- that leads to stacked symbols and noisy rows
- we wanted one simple visual language:
  - `□` ordinary row
  - `■` selected row

So `wt` now keeps:

- a base list file with stable hidden identity in field 1
- a rendered list file that prepends the visible state cell into field 2
- a small render signature so the rendered list only refreshes when the visible
  state actually changed

### Bulk actions and `{+f}`

Bulk actions do not use inline argv expansion.
They consume selected rows from `{+f}` temp files.

Why:

- selected sets can be long
- inline argv expansion can hit shell limits
- a temp file keeps downstream action logic simple and deterministic

Useful commands when debugging selection plumbing:

```bash
./wt --list /path/to/repo | sed -n 'l'

tmp=$(mktemp)
./wt --list /path/to/repo | head -2 > "$tmp"
FZF_SELECT_COUNT=2 ./wt --preview-dispatch "$tmp" /path/to/focused
FZF_SELECT_COUNT=2 ./wt --action-pull "$tmp" /path/to/focused
FZF_SELECT_COUNT=2 ./wt --action-delete-targets "$tmp" /path/to/focused /path/to/repo
rm -f "$tmp"
```

## Refresh Behavior

The async activity refresh still happens in the background, but `wt` does not
blindly apply it as soon as it is ready.

Why not:

- activity refresh can reorder the list
- reordering while the user is building a selected set undermines trust
- identity preservation alone is not enough if the list visibly jumps

So the rule is:

```text
activity data ready + no active selection  => apply refresh now
activity data ready + active selection     => mark refresh as pending
selection clears                           => apply the pending refresh
```

## CI And Workflow Security

The repo keeps CI and workflow security explicit instead of hiding it in long,
implicit GitHub Actions magic.

The main workflows are:

- `ci.yml`
  Shell lint, syntax checks, and smoke coverage.
- `release.yml`
  Builds the release tarball and publishes the GitHub release.
- `workflow-security.yml`
  Audits GitHub Actions usage and pinning.

Useful local commands:

```bash
shellcheck -S error wt share/wt/wt.bash share/wt/wt.zsh
bash -n wt

./wt --list /path/to/repo
./wt --list-activity /path/to/repo
FZF_PREVIEW_COLUMNS=48 ./wt --preview /path/to/worktree
FZF_PREVIEW_COLUMNS=100 ./wt --preview /path/to/worktree

GITHUB_TOKEN="$(gh auth token)" pinact run --check --verify --diff
zizmor --persona regular .github/workflows
```

## Demo Assets

The repo now keeps two demo layers:

- asciinema `.cast` files
  These are the source-of-truth terminal demos.
- GIF previews
  These are the GitHub-friendly derivatives embedded in the README.

Why keep both:

- `.cast` keeps the terminal-native recording and timing
- `.gif` works directly on GitHub without asking the reader to install a player
- future maintainers can regenerate the GIFs from the casts instead of
  re-recording everything from scratch

### Cast generation

Generate one cast or the full suite:

```bash
./scripts/record-demo-cast.sh all
./scripts/record-demo-cast.sh overview
./scripts/record-demo-cast.sh selection
./scripts/record-demo-cast.sh bulk-pull
./scripts/record-demo-cast.sh bulk-delete
```

What the recorder does:

- builds disposable repos under `/tmp/wt-demo-*`
- drives `wt` from a `tmux` session so the recording behaves like a real user
- writes the casts to `docs/assets/`

### GIF generation

Generate one GIF or the full suite:

```bash
./scripts/render-demo-gifs.sh all
./scripts/render-demo-gifs.sh overview
./scripts/render-demo-gifs.sh selection
./scripts/render-demo-gifs.sh bulk-pull
./scripts/render-demo-gifs.sh bulk-delete
```

What the GIF renderer does:

- reuses the same disposable `/tmp` demo setups
- captures stable `tmux` pane snapshots
- renders those snapshots into PNG frames
- stitches the frames into GIFs with `ffmpeg`

Toolchain requirements:

- casts: `git`, `tmux`, `asciinema`
- GIFs: `ffmpeg`, `python3`

The GIF renderer bootstraps a temporary Python venv with Pillow automatically.
