# ~/.bashrc — interactive shells only.
# Minimal bootstrap: set BASH_CONFIG_HOME and delegate to XDG config dir.

[[ $- != *i* ]] && return

export BASH_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/bash"

[[ -f "$BASH_CONFIG_HOME/bash.bashrc" ]] && . "$BASH_CONFIG_HOME/bash.bashrc"
