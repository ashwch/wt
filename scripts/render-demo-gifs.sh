#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR

source "$ROOT_DIR/scripts/record-demo-cast.sh"

VENV_DIR="/tmp/wt-demo-render-venv"
readonly VENV_DIR

render_frame() {
    local session="$1" frame_path="$2"
    local txt_path="${frame_path%.png}.txt"

    tmux capture-pane -pt "$session" > "$txt_path"
    "$VENV_DIR/bin/python" "$ROOT_DIR/scripts/render-demo-frame.py" "$txt_path" "$frame_path"
}

append_held_frame() {
    local session="$1" frame_dir="$2" index="$3" hold_count="$4"
    local base_frame=""
    base_frame="$frame_dir/frame-$(printf '%03d' "$index").png"

    render_frame "$session" "$base_frame"

    local copy=1
    while (( copy < hold_count )); do
        cp "$base_frame" "$frame_dir/frame-$(printf '%03d' "$(( index + copy ))").png"
        copy=$(( copy + 1 ))
    done
}

render_gif_from_frames() {
    local frame_dir="$1" gif_path="$2"
    local palette="$frame_dir/palette.png"

    ffmpeg -y -loglevel error -framerate 2 -i "$frame_dir/frame-%03d.png" \
        -vf "palettegen=stats_mode=diff" \
        "$palette"

    ffmpeg -y -loglevel error -framerate 2 -i "$frame_dir/frame-%03d.png" -i "$palette" \
        -lavfi "paletteuse=dither=sierra2_4a" \
        "$gif_path"
}

ensure_render_deps() {
    require_command ffmpeg
    require_command tmux
    require_command python3

    if [[ ! -x "$VENV_DIR/bin/python" ]]; then
        python3 -m venv "$VENV_DIR"
        "$VENV_DIR/bin/python" -m pip install Pillow >/dev/null
    fi
}

start_demo_session() {
    local session="$1"
    tmux kill-session -t "$session" >/dev/null 2>&1 || true
    tmux new-session -d -s "$session" "cd '$ROOT_DIR' && env PS1='' /bin/bash --noprofile --norc"
    tmux set-option -t "$session" status off
    tmux resize-window -t "$session" -x 150 -y 36
    sleep 0.4
    tmux send-keys -t "$session" "./wt '$CURRENT_REPO'" Enter
    sleep 3.6
}

finish_demo_session() {
    local session="$1"
    tmux send-keys -t "$session" C-c
    sleep 0.3
    tmux kill-session -t "$session" >/dev/null 2>&1 || true
}

render_overview_gif() {
    local session="wt-gif-overview"
    local frame_dir="$CURRENT_ROOT/frames-overview"
    mkdir -p "$frame_dir"

    start_demo_session "$session"
    append_held_frame "$session" "$frame_dir" 0 4
    tmux send-keys -t "$session" Down
    sleep 1.0
    append_held_frame "$session" "$frame_dir" 4 3
    tmux send-keys -t "$session" Down
    sleep 1.0
    append_held_frame "$session" "$frame_dir" 7 3
    tmux send-keys -t "$session" Down
    sleep 1.0
    append_held_frame "$session" "$frame_dir" 10 3

    finish_demo_session "$session"
    render_gif_from_frames "$frame_dir" "$CAST_DIR/wt-demo-overview.gif"
}

render_selection_gif() {
    local session="wt-gif-selection"
    local frame_dir="$CURRENT_ROOT/frames-selection"
    mkdir -p "$frame_dir"

    start_demo_session "$session"
    tmux send-keys -t "$session" Tab
    sleep 0.8
    append_held_frame "$session" "$frame_dir" 0 4
    tmux send-keys -t "$session" Down
    sleep 0.6
    tmux send-keys -t "$session" Tab
    sleep 0.8
    append_held_frame "$session" "$frame_dir" 4 4
    tmux send-keys -t "$session" Down
    sleep 0.6
    tmux send-keys -t "$session" Down
    sleep 0.8
    append_held_frame "$session" "$frame_dir" 8 5

    finish_demo_session "$session"
    render_gif_from_frames "$frame_dir" "$CAST_DIR/wt-demo-selection.gif"
}

render_bulk_pull_gif() {
    local session="wt-gif-pull"
    local frame_dir="$CURRENT_ROOT/frames-pull"
    mkdir -p "$frame_dir"

    start_demo_session "$session"
    tmux send-keys -t "$session" Tab
    sleep 0.6
    tmux send-keys -t "$session" Down
    sleep 0.6
    tmux send-keys -t "$session" Tab
    sleep 0.8
    append_held_frame "$session" "$frame_dir" 0 4
    tmux send-keys -t "$session" C-p
    sleep 2.4
    append_held_frame "$session" "$frame_dir" 4 5

    finish_demo_session "$session"
    render_gif_from_frames "$frame_dir" "$CAST_DIR/wt-demo-bulk-pull.gif"
}

render_bulk_delete_gif() {
    local session="wt-gif-delete"
    local frame_dir="$CURRENT_ROOT/frames-delete"
    mkdir -p "$frame_dir"

    start_demo_session "$session"
    tmux send-keys -t "$session" Tab
    sleep 0.6
    tmux send-keys -t "$session" Down
    sleep 0.6
    tmux send-keys -t "$session" Tab
    sleep 0.8
    append_held_frame "$session" "$frame_dir" 0 4
    tmux send-keys -t "$session" C-x
    sleep 1.8
    append_held_frame "$session" "$frame_dir" 4 4
    tmux send-keys -t "$session" delete Enter
    sleep 2.2
    append_held_frame "$session" "$frame_dir" 8 5

    finish_demo_session "$session"
    render_gif_from_frames "$frame_dir" "$CAST_DIR/wt-demo-bulk-delete.gif"
}

usage() {
    cat <<'EOF'
Usage: ./scripts/render-demo-gifs.sh [overview|selection|bulk-pull|bulk-delete|all]

Default: all
EOF
}

main() {
    local mode="${1:-all}"

    ensure_render_deps
    trap cleanup EXIT

    case "$mode" in
        overview)
            setup_showcase_repo "gif-overview"
            render_overview_gif
            ;;
        selection)
            setup_showcase_repo "gif-selection"
            render_selection_gif
            ;;
        bulk-pull)
            setup_pull_repo "gif-bulk-pull"
            render_bulk_pull_gif
            ;;
        bulk-delete)
            setup_delete_repo "gif-bulk-delete"
            render_bulk_delete_gif
            ;;
        all)
            setup_showcase_repo "gif-overview"
            render_overview_gif

            setup_showcase_repo "gif-selection"
            render_selection_gif

            setup_pull_repo "gif-bulk-pull"
            render_bulk_pull_gif

            setup_delete_repo "gif-bulk-delete"
            render_bulk_delete_gif
            ;;
        -h|--help)
            usage
            return 0
            ;;
        *)
            printf 'unknown mode: %s\n' "$mode" >&2
            usage >&2
            return 1
            ;;
    esac

    printf 'Wrote demo GIFs to %s\n' "$CAST_DIR"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
