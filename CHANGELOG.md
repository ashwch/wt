# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
