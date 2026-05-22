# bash_env.bash — environment exports for all interactive bash sessions.
# Analogous to ~/.config/zsh/.zshenv.
# Sourced near the top of bash.bashrc so all subsequent modules see these vars.

# ─── Locale ───────────────────────────────────────────────────────────────────
export LANG="${LANG:-en_US.UTF-8}"

# ─── Editor ───────────────────────────────────────────────────────────────────
export EDITOR="${EDITOR:-nano}"
export VISUAL="$EDITOR"

# ─── XDG Base Directories ─────────────────────────────────────────────────────
# Set explicitly so every child process inherits them.
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"

# ─── History ──────────────────────────────────────────────────────────────────
# Move history out of $HOME into the XDG state dir.
mkdir -p "${XDG_STATE_HOME}/bash"
export HISTFILE="${XDG_STATE_HOME}/bash/history"
export HISTSIZE=5000
export HISTFILESIZE=5000
export HISTCONTROL=erasedups:ignoreboth
export HISTIGNORE="&:bg:fg:h:pwd:passwd:history *"

# ─── Pager ────────────────────────────────────────────────────────────────────
export LESS='-R -i -F'

# Syntax-highlight man pages through less
export LESS_TERMCAP_mb=$(printf '\e[1;32m')   # begin blink
export LESS_TERMCAP_md=$(printf '\e[1;34m')   # begin bold
export LESS_TERMCAP_me=$(printf '\e[0m')      # end mode
export LESS_TERMCAP_se=$(printf '\e[0m')      # end standout-mode
export LESS_TERMCAP_so=$(printf '\e[1;44;1m') # begin standout-mode
export LESS_TERMCAP_ue=$(printf '\e[0m')      # end underline
export LESS_TERMCAP_us=$(printf '\e[1;32m')   # begin underline

# ─── MySQL Prompt ─────────────────────────────────────────────────────────────
if command -v mysql &>/dev/null; then
    export MYSQL_PS1="\nTime : \w  \r:\m\P \nHost : \h:\p\nUser : \U \nDB   : \d\n     > "
fi
