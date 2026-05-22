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
