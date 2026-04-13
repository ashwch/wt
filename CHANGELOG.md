# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-04-13

### Added
- Added first-class Bash shell integration via `share/wt/wt.bash`
- Added a dedicated workflow security audit using `pinact` and `zizmor`
- Added WSL smoke-test coverage in CI

### Changed
- Split dashboard loading into a fast startup list plus lazy latest-activity refresh
- Made preview placement and row formatting responsive to terminal and pane width
- Tightened release publishing to use pinned actions, narrower permissions, and `gh release create`
- Expanded the README with dependency, platform, layout, stale-worktree, and workflow-security guidance

### Fixed
- Hardened stale and prunable worktree detection across canonicalized and symlinked paths
- Prevented async refresh worker leaks and invalid fallback binds on older `fzf` builds
- Preserved exact wrapper passthrough output across Bash and zsh integrations
- Normalized shell and workflow files to LF so WSL execution stays reliable from Windows checkouts

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
