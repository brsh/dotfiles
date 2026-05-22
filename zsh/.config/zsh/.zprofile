# ~/.config/zsh/.zprofile
# Sourced once for login shells, before .zshrc.
# Good for: one-time PATH setup and login-time initializations.

# ─── macOS ────────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_ENV_HINTS=1
  fi
  # systemd/PAM sets XDG_RUNTIME_DIR on Linux; provide a fallback on macOS
  export XDG_RUNTIME_DIR="${TMPDIR%/}"
fi

# ─── WSL ──────────────────────────────────────────────────────────────────────
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  # Derive Windows home dynamically — cmd.exe runs once at login
  _winuser=$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')
  [[ -n "$_winuser" ]] && export WINHOME="/mnt/c/Users/${_winuser}"
  unset _winuser
fi
