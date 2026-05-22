# bash.bashrc — interactive bash session entry point.
# Lives at $XDG_CONFIG_HOME/bash/bash.bashrc (i.e. ~/.config/bash/bash.bashrc).
# Sourced by ~/.bashrc, which is itself the stow-deployed bootstrap.

# Interactivity guard (defensive; ~/.bashrc also guards, but cheap to repeat)
[[ $- != *i* ]] && return

# ─── OS Detection ─────────────────────────────────────────────────────────────
BaseOS=$(uname -s)

case "${BaseOS}" in
    Darwin)
        Distro="MacOS"
        ;;
    Linux)
        Distro=$(grep ^NAME= /etc/*-release 2>/dev/null | cut -d= -f2 | tr -d '"')
        [[ -e /mnt/c/Windows/System32/bash.exe ]] && BaseOS="WSL"
        ;;
    CYGWIN*)
        Distro="CygWin"
        BaseOS="Windows"
        ;;
    *)
        Distro="${BaseOS}"
        ;;
esac

export BaseOS Distro

# ─── Modular sources ──────────────────────────────────────────────────────────
# BASH_CONFIG_HOME is set by ~/.bashrc before sourcing this file; fall back
# to the XDG default so this file can also be sourced directly.
_bcd="${BASH_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/bash}"

for _f in bash_env bash_opts bash_colors bash_functions bash_aliases; do
    [[ -f "${_bcd}/${_f}.bash" ]] && . "${_bcd}/${_f}.bash"
done
unset _f

# ─── System Completions ───────────────────────────────────────────────────────
[[ -r /usr/share/bash-completion/bash_completion ]] && \
    . /usr/share/bash-completion/bash_completion

# ─── lesspipe ─────────────────────────────────────────────────────────────────
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# ─── dircolors ────────────────────────────────────────────────────────────────
if command -v dircolors &>/dev/null; then
    if   [[ -f ~/.dir_colors ]];   then eval "$(dircolors -b ~/.dir_colors)"
    elif [[ -f /etc/DIR_COLORS ]]; then eval "$(dircolors -b /etc/DIR_COLORS)"
    else                                eval "$(dircolors -b)"
    fi
fi

# ─── Fortune ──────────────────────────────────────────────────────────────────
if command -v fortune &>/dev/null; then
    printf "\n%b\n" "\e[0;33m$(fortune -sa)\e[0m"
elif [[ -x /usr/games/fortune ]]; then
    printf "\n%b\n" "\e[0;33m$(/usr/games/fortune -sa)\e[0m"
fi

# ─── Fallback Prompt ──────────────────────────────────────────────────────────
# Overridden by mobprompt below when available.
if [[ $(id -u) -eq 0 ]]; then
    PS1='${debian_chroot:+($debian_chroot)}\n\[\e[1;37m\][\[\e[0;33m\]\@\[\e[1;37m\]] [\[\e[0;31m\]\u\[\e[0;35m\]@\h\[\e[1;37m\]] [\[\e[0;94m\]\w\[\e[1;37m\]]\[\e[0m\]\n\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\n\[\e[1;37m\][\[\e[0;33m\]\@\[\e[1;37m\]] [\[\e[0;32m\]\u\[\e[0;35m\]@\h\[\e[1;37m\]] [\[\e[0;94m\]\w\[\e[1;37m\]]\[\e[0m\]\n\$ '
fi

# ─── Prompt ───────────────────────────────────────────────────────────────────
if [[ -f "${_bcd}/mobprompt.sh" ]]; then
    . "${_bcd}/mobprompt.sh"
    alias nanoprompt="${EDITOR:-nano} \"${_bcd}/mobprompt.sh\""
fi

# ─── Local Overrides ──────────────────────────────────────────────────────────
# Machine-specific settings (gitignored). Create: ~/.config/bash/bash.bashrc.local
[[ -f "${_bcd}/bash.bashrc.local" ]] && . "${_bcd}/bash.bashrc.local"
unset _bcd
