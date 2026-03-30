# wt — Interactive Git Worktree Dashboard

Browse, manage, and navigate git worktrees with an fzf-powered TUI.

## Features

- **Interactive dashboard** — Browse all worktrees with fzf split panel
- **Rich preview** — Branch info, recent commits, submodule status, working tree changes
- **Keyboard-driven** — Create, delete, pull, and open worktrees without leaving the TUI
- **Submodule-aware** — Shows sync status for repos with submodules
- **Shell integration** — Press Enter to cd directly into a worktree
- **Minimal dependencies** — bash, git, fzf, and standard POSIX utilities

## Install

### Manual

```bash
# Clone
git clone https://github.com/ashwch/wt.git
cd wt

# Add to PATH
ln -s "$PWD/wt" /usr/local/bin/wt

# Add shell integration to .zshrc
echo 'source /path/to/wt/share/wt/wt.zsh' >> ~/.zshrc
```

### Homebrew

```bash
brew install ashwch/tap/wt
```

## Usage

```bash
wt                  # Auto-detect repo from $PWD
wt /path/to/repo    # Explicit repo path
wt -h               # Show help
wt --version        # Show version
```

## Keybindings

| Key | Action |
|-----|--------|
| `Enter` | cd into selected worktree |
| `Ctrl-O` | Open in `$EDITOR` |
| `Ctrl-P` | Pull latest (`--ff-only`) |
| `Ctrl-N` | Create new worktree |
| `Ctrl-X` | Delete worktree |
| `Ctrl-R` | Refresh list |
| `Ctrl-/` | Toggle preview panel |

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
  `wt` retries removal, repairs directory permissions, clears ACLs, clears
  macOS immutable flags when available, and tries again.
- If the directory is already gone:
  `wt` offers to prune the stale worktree entry from Git metadata.

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
| `●` | Current worktree (green) |
| `○` | Has branch (blue) |
| `◌` | Detached HEAD (yellow) |
| `✗` | Prunable / stale (red) |
| `🔒` | Locked (dim) |

## Shell Integration

Source `share/wt/wt.zsh` in your `.zshrc` for cd support. When you press Enter on a worktree, the shell will `cd` into that directory instead of just printing the path.

```zsh
# If installed via Homebrew
source /opt/homebrew/share/wt/wt.zsh

# If cloned manually
source ~/path/to/wt/share/wt/wt.zsh
```

## Requirements

- **git** — any modern version
- **fzf** — 0.38+ (uses `become()`)
- **bash** — 3.2+ (ships with macOS)
- **coreutils** — awk, sed, sort, cut, head, date (standard on macOS/Linux)

## License

MIT
