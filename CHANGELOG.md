# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Added always-on multi-selection with stable path identity and bulk-safe dispatch for pull and delete/prune
- Added a selection-aware preview mode that makes bulk targets explicit when focus and selection diverge
- Added richer documentation for the selection model, deferred refresh behavior, and row-state rendering

### Changed
- Changed the dashboard to treat `Space`, `Tab`, and `Shift-Tab` as first-class selection workflows
- Changed the left state column to a custom-rendered `□` / `■` selection cell instead of stacked native fzf pointer/marker glyphs
- Changed async activity refresh to defer list replacement while a selection exists and apply it after selection clears
- Changed the stacked preview layout to give the lower selection summary pane more room by default

### Fixed
- Fixed launch-time `fzf` option breakage caused by inline comments inside a backslash-continued command
- Fixed selected `Ctrl-P` / `Ctrl-X` execution so bulk actions reliably run from the live dashboard
- Fixed rendered selection-state handling across macOS `/bin/bash`, canonicalized `/tmp` vs `/private/tmp` paths, and focused-row redraws
- Fixed bulk delete so a worktree that becomes dirty after batch confirmation is re-prompted before force removal

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
