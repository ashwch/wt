# wt.zsh — Shell integration for wt (git worktree dashboard)
#
# Source this file in your .zshrc to enable cd support:
#   source /path/to/share/wt/wt.zsh
#
# When you press Enter on a worktree in wt, the shell will
# cd into that directory instead of just printing the path.

if command -v wt >/dev/null 2>&1; then
    _wt_wrapper() {
        local result
        result=$(command wt "$@")
        if [[ -d "$result" ]]; then
            cd "$result" || return
        elif [[ -n "$result" ]]; then
            echo "$result"
        fi
    }
    alias wt='_wt_wrapper'
fi
