# AGENTS.md

> Context for AI coding assistants (Claude Code, Cursor, Copilot, etc.)

## Overview

`wt` is an interactive git worktree dashboard built with bash and fzf.
It provides a TUI for browsing, managing, and navigating git worktrees
with rich preview panels showing branch info, commits, submodule status,
and working tree changes.

## Architecture

```
wt (bash script)
├── fzf TUI (split panel: list + preview)
├── git worktree list --porcelain (data source)
├── Self-invocation for fzf callbacks:
│   ├── wt --list [path]          (list rows for reload)
│   ├── wt --preview <path>       (preview for highlighted item)
│   ├── wt --action-new <path>    (create worktree)
│   └── wt --action-delete <path> (remove worktree)
└── Shell wrapper (share/wt/wt.zsh)
    └── Captures stdout path → cd
```

## File Structure

```
wt/
├── wt                    # Main script (bash)
├── share/wt/wt.zsh       # Zsh shell integration (cd wrapper)
├── README.md             # Usage docs
├── LICENSE               # MIT
└── AGENTS.md             # This file
```

## Key Design Decisions

1. **Tab-delimited fzf fields** — Full path as hidden field 1, display as field 2.
   fzf uses `--with-nth=2` to hide path, `{1}` in binds to reference it.

2. **Self-invocation** — Script calls itself for `--preview`, `--list`, and actions.
   `$SELF` is resolved at startup to an absolute path for fzf callbacks.

3. **Porcelain parsing** — Uses `git worktree list --porcelain` (not human-readable).
   Handles four states: branch, detached, prunable, and current.

4. **Single submodule call** — One `git submodule status` per preview, not per-submodule.

5. **Shell wrapper pattern** — Same as auto-uv-env: `command wt` returns a path to
   stdout, the zsh wrapper captures it and `cd`s if it's a valid directory.

## Development

```bash
# Test the script
./wt                          # From any git repo
./wt /path/to/repo            # Explicit path
./wt --preview /path/to/wt    # Preview for this worktree
./wt --list                   # Raw list output

# Style follows dotfiles/bin/tmux-session patterns:
# - set -euo pipefail
# - readonly constants
# - die/warn helpers
# - section comment headers (# ===...===)
# - main() entry point at bottom
```

## Distribution

- Standalone bash script — no compiled dependencies
- Shell integration via `share/wt/wt.zsh` (sourced in .zshrc)
- Installable via Homebrew tap (formula to be added)
