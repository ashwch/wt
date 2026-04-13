# shellcheck shell=bash
# wt.bash — Shell integration for wt (git worktree dashboard)
#
# Source this file in your .bashrc to enable cd support:
#   source /path/to/share/wt/wt.bash
#
# When you press Enter on a worktree in wt, the shell will
# cd into that directory instead of just printing the path.

_wt_wrapper_dir() {
    local source="${BASH_SOURCE[0]}"
    while [[ -L "$source" ]]; do
        local dir
        dir=$(cd -P "$(dirname "$source")" && pwd) || return 1
        source=$(readlink "$source") || return 1
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd
}

_wt_find_executable() {
    local wrapper_dir candidate path_cmd
    wrapper_dir=$(_wt_wrapper_dir) || return 1

    # Prefer the executable that lives with the sourced wrapper. That keeps the
    # integration working for both "source a local clone" and Homebrew installs
    # even when the caller has not already put `wt` on PATH.
    for candidate in "$wrapper_dir/../../wt" "$wrapper_dir/../../bin/wt"; do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    path_cmd=$(command -v wt 2>/dev/null) || return 1
    [[ -n "$path_cmd" ]] || return 1
    printf '%s\n' "$path_cmd"
}

if _WT_WRAPPER_EXECUTABLE="$(_wt_find_executable)"; then
    wt() {
        local result exit_code
        result=$("$_WT_WRAPPER_EXECUTABLE" "$@")
        exit_code=$?
        # Preserve the real exit status. The wrapper only adds "cd into the
        # chosen directory" behavior; it should never make failures ambiguous.
        if (( exit_code != 0 )); then
            [[ -n "$result" ]] && echo "$result"
            return "$exit_code"
        fi
        if [[ -d "$result" ]]; then
            cd "$result" || return
        elif [[ -n "$result" ]]; then
            echo "$result"
        fi
    }
fi
