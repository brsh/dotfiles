# bash_profile.bash — login-shell-only setup.
# Analogous to ~/.config/zsh/.zprofile.
# Sourced by ~/.bash_profile before ~/.bashrc, so it runs once at login.

# ─── macOS ────────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        export HOMEBREW_NO_ANALYTICS=1
        export HOMEBREW_NO_ENV_HINTS=1
    fi
    # systemd/PAM sets XDG_RUNTIME_DIR on Linux; provide a fallback on macOS.
    export XDG_RUNTIME_DIR="${TMPDIR%/}"
fi

# ─── WSL ──────────────────────────────────────────────────────────────────────
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    export DISPLAY=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0
    export LIBGL_ALWAYS_INDIRECT=1
    _winuser=$(powershell.exe -noprofile -c 'Write-Host -NoNewLine $env:USERNAME' 2>/dev/null | tr -d '\r\n')
    [[ -n "$_winuser" ]] && export WINHOME="/mnt/c/Users/${_winuser}"
    unset _winuser
fi

# ─── Path ─────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

tmux_monitor() {
  tmux new-session -d -s monitor 'htop'
  tmux split-window -h -t monitor 'ncdu'
  tmux attach-session -t monitor
}


# ---------------------------------------------------------------------------
# tmux_session_picker
#
# Lists active tmux sessions and lets you attach to one, start a new one
# (default name "Myne"), or skip entirely.
#
# Usage:
#   tmux_session_picker         # manual mode: no timeout, prompts until answered
#   tmux_session_picker auto    # auto mode: 5s timeout, used for SSH login hook
#
# Exit behavior:
#   - If tmux isn't installed, returns immediately (no-op).
#   - If already inside tmux, returns immediately (no-op).
#   - Empty answer (or timeout in auto mode) skips starting tmux.
# ---------------------------------------------------------------------------
tmux_session_picker() {
  local mode="${1:-manual}"
  local timeout_secs=5

  # Bypass entirely if tmux isn't installed
  command -v tmux >/dev/null 2>&1 || return 0

  # Already inside tmux -> nothing to do
  if [[ -n "$TMUX" ]]; then
    return 0
  fi

  local sessions
  sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

  local prompt_txt
  if [[ -n "$sessions" ]]; then
    echo "Active tmux sessions:"
    echo "$sessions" | nl -w2 -s') '
    prompt_txt="Attach [number/name], 'n' for new session, or Enter to skip"
  else
    prompt_txt="No active sessions. 'n' for new session 'Myne', or Enter to skip"
  fi

  local answer rc
  if [[ "$mode" == "auto" ]]; then
    read -t "$timeout_secs" -p "$prompt_txt (auto-skip in ${timeout_secs}s): " answer
    rc=$?
    if [[ $rc -ne 0 ]]; then
      echo
      echo "No response — skipping tmux."
      return 0
    fi
  else
    read -p "$prompt_txt: " answer
  fi

  # Empty answer -> skip
  [[ -z "$answer" ]] && return 0

  # 'n'/'N' -> new default session
  if [[ "$answer" == "n" || "$answer" == "N" ]]; then
    tmux new-session -A -s Myne
    return
  fi

  # Numeric answer -> map to nth session in the list
  if [[ "$answer" =~ ^[0-9]+$ ]] && [[ -n "$sessions" ]]; then
    local name
    name=$(echo "$sessions" | sed -n "${answer}p")
    if [[ -n "$name" ]]; then
      tmux attach-session -t "$name"
      return
    fi
    echo "No session #$answer — skipping."
    return 0
  fi

  # Otherwise treat input as a session name: attach if it exists, else create it
  if echo "$sessions" | grep -qx "$answer"; then
    tmux attach-session -t "$answer"
  else
    tmux new-session -A -s "$answer"
  fi
}
