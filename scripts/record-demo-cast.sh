#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${ROOT_DIR:-}" ]]; then
    ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    readonly ROOT_DIR
fi

if [[ -z "${CAST_DIR:-}" ]]; then
    CAST_DIR="$ROOT_DIR/docs/assets"
    readonly CAST_DIR
fi

if [[ -z "${DEMO_BASE:-}" ]]; then
    DEMO_BASE="/tmp/wt-demo"
    readonly DEMO_BASE
fi

CURRENT_ROOT=""
CURRENT_REPO=""

cleanup() {
    rm -rf "${DEMO_BASE}"*
}

require_command() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || {
        printf 'missing required command: %s\n' "$cmd" >&2
        exit 1
    }
}

reset_demo_root() {
    local mode="$1"
    CURRENT_ROOT="${DEMO_BASE}-${mode}"
    CURRENT_REPO="$CURRENT_ROOT/repo"

    rm -rf "$CURRENT_ROOT"
    mkdir -p "$CURRENT_ROOT" "$CAST_DIR"
}

commit_with_offset() {
    local path="$1"
    local message="$2"
    local offset_spec="$3"
    local file="$4"
    local line="$5"
    local ts

    ts="$(python3 - "$offset_spec" <<'PY'
from datetime import datetime, timedelta, timezone
import sys

raw = sys.argv[1]
value = int(raw[:-1])
unit = raw[-1]
delta = {
    "m": timedelta(minutes=value),
    "h": timedelta(hours=value),
    "d": timedelta(days=value),
}[unit]

print((datetime.now(timezone.utc) - delta).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
)"

    printf '%s\n' "$line" >> "$path/$file"
    GIT_AUTHOR_DATE="$ts" GIT_COMMITTER_DATE="$ts" git -C "$path" add "$file"
    GIT_AUTHOR_DATE="$ts" GIT_COMMITTER_DATE="$ts" git -C "$path" commit -m "$message" >/dev/null 2>&1
}

setup_showcase_repo() {
    local mode="$1"
    local repo review api ui docs release detached locked

    reset_demo_root "$mode"

    repo="$CURRENT_REPO"
    review="$CURRENT_ROOT/reviewer"
    api="$CURRENT_ROOT/api"
    ui="$CURRENT_ROOT/ui"
    docs="$CURRENT_ROOT/docs"
    release="$CURRENT_ROOT/release"
    detached="$CURRENT_ROOT/detached"
    locked="$CURRENT_ROOT/locked"

    git init "$repo" >/dev/null 2>&1
    git -C "$repo" config user.name "WT Demo"
    git -C "$repo" config user.email "wt-demo@example.com"

    printf 'init\n' > "$repo/README.md"
    git -C "$repo" add README.md

    local init_date
    init_date="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(days=6)).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
)"
    GIT_AUTHOR_DATE="$init_date" GIT_COMMITTER_DATE="$init_date" git -C "$repo" commit -m "init" >/dev/null 2>&1
    git -C "$repo" branch -M main >/dev/null 2>&1 || true

    git -C "$repo" worktree add "$review" -b reviewer main >/dev/null 2>&1
    git -C "$repo" worktree add "$api" -b api main >/dev/null 2>&1
    git -C "$repo" worktree add "$ui" -b ui main >/dev/null 2>&1
    git -C "$repo" worktree add "$docs" -b docs main >/dev/null 2>&1
    git -C "$repo" worktree add "$release" -b release main >/dev/null 2>&1
    git -C "$repo" worktree add --detach "$detached" HEAD >/dev/null 2>&1
    git -C "$repo" worktree add "$locked" -b locked main >/dev/null 2>&1

    commit_with_offset "$review" "review: align demo selection preview" "4h" "README.md" "review branch"
    commit_with_offset "$review" "review: tighten preview copy" "2h" "README.md" "review copy"
    commit_with_offset "$review" "review: polish overview section" "45m" "README.md" "review polish"

    commit_with_offset "$api" "api: add pulse opener source state" "3h" "api.txt" "api branch"
    commit_with_offset "$ui" "ui: improve survey heatmap layout" "8h" "ui.txt" "ui branch"
    commit_with_offset "$ui" "ui: clarify empty state copy" "5h" "ui.txt" "ui copy"
    printf 'local uncommitted change\n' >> "$ui/ui.txt"

    commit_with_offset "$docs" "docs: expand worktree usage notes" "1d" "docs.md" "docs branch"
    commit_with_offset "$release" "release: prepare notes for rollout" "2d" "release.md" "release branch"
    commit_with_offset "$detached" "detached: inspect historical rollout state" "3d" "detached.txt" "detached branch"
    commit_with_offset "$locked" "locked: preserve debugging state" "5d" "locked.txt" "locked branch"
    git -C "$repo" worktree lock "$locked" >/dev/null 2>&1
}

setup_pull_repo() {
    local mode="$1"
    local remote frontend backend docs updater

    reset_demo_root "$mode"

    remote="$CURRENT_ROOT/remote.git"
    backend="$CURRENT_ROOT/backend"
    frontend="$CURRENT_ROOT/frontend"
    docs="$CURRENT_ROOT/docs"
    updater="$CURRENT_ROOT/updater"

    git init --bare "$remote" >/dev/null 2>&1
    git clone "$remote" "$CURRENT_REPO" >/dev/null 2>&1
    git -C "$CURRENT_REPO" config user.name "WT Demo"
    git -C "$CURRENT_REPO" config user.email "wt-demo@example.com"

    printf 'init\n' > "$CURRENT_REPO/README.md"
    git -C "$CURRENT_REPO" add README.md
    git -C "$CURRENT_REPO" commit -m "init" >/dev/null 2>&1
    git -C "$CURRENT_REPO" branch -M main >/dev/null 2>&1 || true
    git -C "$CURRENT_REPO" push -u origin main >/dev/null 2>&1

    git -C "$CURRENT_REPO" worktree add "$backend" -b backend main >/dev/null 2>&1
    git -C "$CURRENT_REPO" worktree add "$frontend" -b frontend main >/dev/null 2>&1
    git -C "$CURRENT_REPO" worktree add "$docs" -b docs main >/dev/null 2>&1

    for path in "$backend" "$frontend" "$docs"; do
        git -C "$path" config user.name "WT Demo"
        git -C "$path" config user.email "wt-demo@example.com"
    done

    commit_with_offset "$backend" "backend: prep pull demo branch" "3h" "backend.txt" "backend branch"
    commit_with_offset "$frontend" "frontend: prep pull demo branch" "4h" "frontend.txt" "frontend branch"
    commit_with_offset "$docs" "docs: prep pull demo branch" "1d" "docs.txt" "docs branch"

    git -C "$backend" push -u origin backend >/dev/null 2>&1
    git -C "$frontend" push -u origin frontend >/dev/null 2>&1
    git -C "$docs" push -u origin docs >/dev/null 2>&1

    git clone "$remote" "$updater" >/dev/null 2>&1
    git -C "$updater" config user.name "WT Demo"
    git -C "$updater" config user.email "wt-demo@example.com"
    git -C "$updater" checkout backend >/dev/null 2>&1
    printf 'remote backend update\n' >> "$updater/backend.txt"
    git -C "$updater" commit -am "backend: fast-forward demo branch" >/dev/null 2>&1
    git -C "$updater" push >/dev/null 2>&1
}

setup_delete_repo() {
    local mode="$1"
    local clean dirty review

    reset_demo_root "$mode"

    clean="$CURRENT_ROOT/clean"
    dirty="$CURRENT_ROOT/dirty"
    review="$CURRENT_ROOT/review"

    git init "$CURRENT_REPO" >/dev/null 2>&1
    git -C "$CURRENT_REPO" config user.name "WT Demo"
    git -C "$CURRENT_REPO" config user.email "wt-demo@example.com"

    printf 'init\n' > "$CURRENT_REPO/README.md"
    git -C "$CURRENT_REPO" add README.md
    git -C "$CURRENT_REPO" commit -m "init" >/dev/null 2>&1
    git -C "$CURRENT_REPO" branch -M main >/dev/null 2>&1 || true

    git -C "$CURRENT_REPO" worktree add "$clean" -b clean main >/dev/null 2>&1
    git -C "$CURRENT_REPO" worktree add "$dirty" -b dirty main >/dev/null 2>&1
    git -C "$CURRENT_REPO" worktree add "$review" -b review main >/dev/null 2>&1

    commit_with_offset "$clean" "clean: disposable branch" "2h" "clean.txt" "clean branch"
    commit_with_offset "$dirty" "dirty: disposable branch" "3h" "dirty.txt" "dirty branch"
    commit_with_offset "$review" "review: disposable branch" "1d" "review.txt" "review branch"

    printf 'local dirty change\n' >> "$dirty/dirty.txt"
}

record_mode() {
    local mode="$1"
    local session="wt-demo-${mode}"
    local cast_file="$CAST_DIR/wt-demo-${mode}.cast"

    tmux kill-session -t "$session" >/dev/null 2>&1 || true
    tmux new-session -d -s "$session" "cd '$ROOT_DIR' && env PS1='' /bin/bash --noprofile --norc"
    tmux set-option -t "$session" status off
    tmux resize-window -t "$session" -x 150 -y 36

    (
        sleep 0.4
        tmux send-keys -t "$session" "./wt '$CURRENT_REPO'" Enter
        case "$mode" in
            overview) drive_overview "$session" ;;
            selection) drive_selection "$session" ;;
            bulk-pull) drive_bulk_pull "$session" ;;
            bulk-delete) drive_bulk_delete "$session" ;;
            *) printf 'unknown demo mode: %s\n' "$mode" >&2; tmux kill-session -t "$session" >/dev/null 2>&1 || true ;;
        esac
    ) &

    asciinema rec \
        --overwrite \
        --quiet \
        --idle-time-limit 1.2 \
        --window-size 150x36 \
        "$cast_file" \
        -c "tmux attach-session -t $session"

    # Keep the legacy single-demo path as an alias to the overview cast.
    if [[ "$mode" == "overview" ]]; then
        cp "$cast_file" "$CAST_DIR/wt-demo.cast"
    fi
}

drive_overview() {
    local session="$1"
    sleep 3.6
    sleep 2.2
    tmux send-keys -t "$session" Down
    sleep 2.0
    tmux send-keys -t "$session" Down
    sleep 2.0
    tmux send-keys -t "$session" Down
    sleep 2.2
    tmux send-keys -t "$session" Down
    sleep 2.0
    tmux send-keys -t "$session" Down
    sleep 3.0
    tmux send-keys -t "$session" C-c
    sleep 0.5
    tmux kill-session -t "$session" >/dev/null 2>&1 || true
}

drive_selection() {
    local session="$1"
    sleep 3.2

    # Hide the preview first so the selected rows stay visible while we build
    # the set. The cast can then re-open the preview to show the bulk-target
    # summary and off-target behavior afterward.
    tmux send-keys -t "$session" C-/
    sleep 1.0

    # Move to the middle of the list so selected rows remain on-screen.
    tmux send-keys -t "$session" Down
    sleep 0.8

    # Start selecting almost immediately so this cast shows the core feature
    # early instead of spending most of its time as a plain browser walkthrough.
    tmux send-keys -t "$session" Tab
    sleep 1.4
    tmux send-keys -t "$session" Down
    sleep 0.9
    tmux send-keys -t "$session" Tab
    sleep 1.4
    tmux send-keys -t "$session" Down
    sleep 0.9
    tmux send-keys -t "$session" Tab
    sleep 1.8

    # Hold on the selected rows with preview hidden so the black squares are
    # impossible to miss.
    sleep 2.6

    # Re-open the preview and move away so the selection-aware summary is also
    # shown in the same cast.
    tmux send-keys -t "$session" C-/
    sleep 1.2

    tmux send-keys -t "$session" Down
    sleep 1.1
    tmux send-keys -t "$session" Down
    sleep 4.4
    tmux send-keys -t "$session" C-c
    sleep 0.5
    tmux kill-session -t "$session" >/dev/null 2>&1 || true
}

drive_bulk_pull() {
    local session="$1"
    sleep 3.6
    sleep 1.6
    tmux send-keys -t "$session" Tab
    sleep 1.2
    tmux send-keys -t "$session" Down
    sleep 1.0
    tmux send-keys -t "$session" Tab
    sleep 1.8
    tmux send-keys -t "$session" C-p
    sleep 3.6
    tmux send-keys -t "$session" C-c
    sleep 0.5
    tmux kill-session -t "$session" >/dev/null 2>&1 || true
}

drive_bulk_delete() {
    local session="$1"
    sleep 3.2
    sleep 1.6
    tmux send-keys -t "$session" Tab
    sleep 1.0
    tmux send-keys -t "$session" Down
    sleep 0.8
    tmux send-keys -t "$session" Tab
    sleep 2.0
    tmux send-keys -t "$session" C-x
    sleep 2.2
    tmux send-keys -t "$session" delete Enter
    sleep 3.4
    tmux send-keys -t "$session" C-c
    sleep 0.5
    tmux kill-session -t "$session" >/dev/null 2>&1 || true
}

record_overview() {
    setup_showcase_repo "overview"
    record_mode "overview"
}

record_selection() {
    setup_showcase_repo "selection"
    record_mode "selection"
}

record_bulk_pull() {
    setup_pull_repo "bulk-pull"
    record_mode "bulk-pull"
}

record_bulk_delete() {
    setup_delete_repo "bulk-delete"
    record_mode "bulk-delete"
}

usage() {
    cat <<'EOF'
Usage: ./scripts/record-demo-cast.sh [overview|selection|bulk-pull|bulk-delete|all]

Default: all
EOF
}

main() {
    local mode="${1:-all}"

    require_command git
    require_command asciinema
    require_command tmux

    trap cleanup EXIT

    case "$mode" in
        overview)
            record_overview
            ;;
        selection)
            record_selection
            ;;
        bulk-pull)
            record_bulk_pull
            ;;
        bulk-delete)
            record_bulk_delete
            ;;
        all)
            record_overview
            record_selection
            record_bulk_pull
            record_bulk_delete
            ;;
        -h|--help)
            usage
            ;;
        *)
            printf 'unknown mode: %s\n' "$mode" >&2
            usage >&2
            exit 1
            ;;
    esac

    printf 'Wrote demo casts to %s\n' "$CAST_DIR"
}

main "$@"
