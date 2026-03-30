# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-03-30

### Fixed
- Hardened `Ctrl-X` deletion when `git worktree remove` leaves unreadable directories behind
- Added a fail-closed confirmation path when cleanup can no longer verify git status
- Improved stale worktree pruning when paths differ between `/var` and `/private/var`
- Made direct `--action-delete` handling clearer for non-worktree and non-directory targets
- Tightened shell safety around delete retries, argument handling, and placeholder assumptions

### Documentation
- Documented the delete model and troubleshooting flow in the README
- Added inline comments explaining the delete fallback and pruning helpers in `wt`

## [0.1.0] - 2026-03-02

### Added
- Interactive fzf TUI for browsing git worktrees
- Preview panel with branch, commits, submodule status, and working tree changes
- Keybindings: Enter (cd), Ctrl-O (editor), Ctrl-P (pull), Ctrl-N (new), Ctrl-X (delete), Ctrl-R (refresh)
- Submodule-aware activity timeline (newest commit across worktree + submodules)
- Smart delete with safety checks (main worktree, current worktree, locked, dirty tree)
- Prunable worktree detection and cleanup
- Detached HEAD resolution via `git describe --all`
- Zsh shell integration for cd support (`share/wt/wt.zsh`)
- `--help` and `--version` flags
- Explicit repo path argument (`wt <path>`)
