# ~/.config/zsh/.zshenv
# Sourced for EVERY zsh instance (interactive, non-interactive, scripts, SSH).
# Keep this minimal — only variables every process needs.
# Note: Homebrew PATH is not available here; it is set in .zprofile.

[[ ! -v HOSTNAME ]] && [[ -v HOST ]] export HOSTNAME=$HOST

# ─── Locale ───────────────────────────────────────────────────────────────────
export LANG=en_US.UTF-8

# ─── Editor ───────────────────────────────────────────────────────────────────
export EDITOR=nano
export VISUAL="$EDITOR"

# ─── XDG Base Directories ─────────────────────────────────────────────────────
# User-level dirs — safe to set explicitly here.
# XDG_DATA_DIRS, XDG_CONFIG_DIRS: system-managed, leave unset.
# XDG_RUNTIME_DIR: set by systemd/PAM on Linux; macOS fallback lives in .zprofile.
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"

# ─── Pager & Display ──────────────────────────────────────────────────────────
export LESS='-R -i -F'       # raw color, case-insensitive search, quit-if-one-screen
export REPORTTIME=10         # print timing for any command taking longer than 10s

# ─── Path Hygiene ─────────────────────────────────────────────────────────────
typeset -U PATH path         # silently deduplicate PATH entries

# ─── FZF ──────────────────────────────────────────────────────────────────────
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'

# ─── Tasks ────────────────────────────────────────────────────────────────────
export DSTASK_GIT_REPO=~/Scripts/1_Repos/dstask

# --- Claude Code ---
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME/claude"
