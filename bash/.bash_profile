# ~/.bash_profile — login shells only.
# Minimal bootstrap: set BASH_CONFIG_HOME, run login-specific setup, then hand
# off to .bashrc for interactive config (which bash skips for login shells).

export BASH_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/bash"

[[ -f "$BASH_CONFIG_HOME/bash_profile.bash" ]] && . "$BASH_CONFIG_HOME/bash_profile.bash"
[[ -f "$HOME/.bashrc" ]] && . "$HOME/.bashrc"
