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
