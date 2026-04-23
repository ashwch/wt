# Delete Model

`Ctrl-X` is intentionally conservative first, then pragmatic if Git leaves a
half-deleted tree behind.

Think about worktree deletion as two separate jobs:

1. Git metadata cleanup
2. Filesystem cleanup

Most of the time, `git worktree remove` can do both in one step.
The difficult cases are when files appear mid-delete, permissions are odd,
metadata is stale, or the worktree becomes dirty after an earlier confirmation.

## Core Behavior

- Clean worktree:
  `Ctrl-X` asks for `y`, then tries `git worktree remove`.
- Dirty worktree:
  `Ctrl-X` shows the first few changes and requires typing `delete`.
- Directory already gone:
  `wt` offers to prune the stale worktree entry from Git metadata.
- Directory still exists but Git marks the entry `prunable`:
  `wt` treats it as a stale leftover directory, offers to prune the metadata,
  and then removes the leftover files if needed.

## Why the extra confirmations exist

A worktree can be clean when the summary is shown and dirty by the time its
delete actually happens.

That can happen because:

- a tool generates files
- a user edits another selected worktree mid-batch
- `git worktree remove` fails and force cleanup becomes necessary

So `wt` does **not** treat "was clean earlier" as a permanent guarantee.
If a worktree becomes risky before its turn, `wt` re-prompts before doing the
kind of force removal that could destroy local changes.

## Stale leftover directories

You can have a path that:

- still exists on disk
- is no longer a valid Git worktree
- is already marked `prunable` by `git worktree list --porcelain`

That usually means the worktree's `.git` file or admin metadata is broken or
missing. In that state, normal `git -C /path status` checks fail even though
the directory is still there.

`wt` treats Git's `prunable` state as authoritative. If Git says the entry is
stale, `Ctrl-X` behaves like:

```text
prune stale metadata
then remove leftover files if they still exist
```

## Delete Refusals That Are Intentional

- The main worktree cannot be removed.
- The worktree you are currently standing in cannot be removed.
- Locked worktrees cannot be removed until you unlock them.

## Useful Debug Commands

```bash
# See whether Git already considers the worktree stale
git -C /path/to/repo worktree list --porcelain

# Check whether the leftover directory still has a valid .git link
ls -la /path/to/worktree/.git
cat /path/to/worktree/.git

# Show mode bits, ACLs, and macOS flags
ls -ldOe /path/to/worktree /path/to/worktree/*

# Find entries not owned by your user
find /path/to/worktree ! -user "$USER" -print

# Show a quick sample of the remaining tree
find /path/to/worktree -mindepth 1 -maxdepth 2 -print | head

# Remove stale Git metadata from any surviving checkout of the same repo
git -C /path/to/another/checkout worktree prune --expire now
```
