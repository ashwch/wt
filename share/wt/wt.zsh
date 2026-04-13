# shellcheck shell=bash
# wt.zsh — Shell integration for wt (git worktree dashboard)
#
# Source this file in your .zshrc to enable cd support:
#   source /path/to/share/wt/wt.zsh
#
# When you press Enter on a worktree in wt, the shell will
# cd into that directory instead of just printing the path.

# shellcheck disable=SC2296
_WT_WRAPPER_SOURCE="${(%):-%x}"

_wt_wrapper_dir() {
    local source="$_WT_WRAPPER_SOURCE"
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
            print -r -- "$candidate"
            return 0
        fi
    done

    path_cmd=$(whence -p wt 2>/dev/null) || return 1
    [[ -n "$path_cmd" ]] || return 1
    print -r -- "$path_cmd"
}

if _WT_WRAPPER_EXECUTABLE="$(_wt_find_executable)"; then
    wt() {
        local result exit_code
        result=$("$_WT_WRAPPER_EXECUTABLE" "$@")
        exit_code=$?
        # Keep failures loud and truthful. If the underlying command failed, do
        # not hide that behind wrapper sugar like `cd`.
        if (( exit_code != 0 )); then
            [[ -n "$result" ]] && printf '%s\n' "$result"
            return "$exit_code"
        fi
        if [[ -d "$result" ]]; then
            cd "$result" || return
        elif [[ -n "$result" ]]; then
            printf '%s\n' "$result"
        fi
    }
fi
