# ~/.config/zsh/.zshrc
# Sourced for interactive shells only.
# Environment variables live in .zshenv; login-shell PATH setup lives in .zprofile.

# ─── XDG Directory Guards ─────────────────────────────────────────────────────
# Ensure required subdirs exist on any fresh install (mkdir -p is a no-op if present)
mkdir -p "${XDG_STATE_HOME}/zsh" "${XDG_CACHE_HOME}/zsh"

# ─── Zinit Plugin Manager ─────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# ─── Plugins (eager — fpath modifier must run before compinit) ────────────────
zinit light zsh-users/zsh-completions

# ─── Completions ──────────────────────────────────────────────────────────────
# fpath additions must come before compinit

if command -v docker &>/dev/null && [[ -d "${HOME}/.docker/completions" ]]; then
  fpath=("${HOME}/.docker/completions" $fpath)
fi

# Homebrew-installed tools put their completion scripts here
if [[ "$OSTYPE" == "darwin"* ]] && [[ -n "$HOMEBREW_PREFIX" ]]; then
  fpath=("${HOMEBREW_PREFIX}/share/zsh/site-functions" $fpath)
fi

setopt EXTENDED_GLOB  # required for (#q) glob qualifier in the compinit check
autoload -Uz compinit
if [[ -n ${XDG_CACHE_HOME}/zsh/zcompdump(#qNmh+24) ]]; then
  compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump"     # dump >24 h old: full rebuild
else
  compinit -C -d "${XDG_CACHE_HOME}/zsh/zcompdump"  # fresh dump: skip security scan
fi

zinit cdreplay -q

# kubecolor is a kubectl drop-in; tell compinit to reuse kubectl's completion
if command -v kubecolor &>/dev/null; then
  compdef kubecolor=kubectl
fi

# carapace uses compdef, so must come after compinit
if command -v carapace &>/dev/null; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  source <(carapace _carapace zsh)
fi

# ─── Turbo Plugins & Snippets (deferred — load after first prompt) ────────────
zinit wait lucid light-mode for \
  Aloxaf/fzf-tab \
  zsh-users/zsh-syntax-highlighting \
  atload'_zsh_autosuggest_start' zsh-users/zsh-autosuggestions

zinit wait lucid for \
  OMZP::sudo \
  OMZP::command-not-found \
  OMZP::extract

if [[ -f /etc/arch-release ]];      then zinit ice wait lucid; zinit snippet OMZP::archlinux; fi
if command -v aws     &>/dev/null;  then zinit ice wait lucid; zinit snippet OMZP::aws;       fi
if command -v kubectl &>/dev/null;  then zinit ice wait lucid; zinit snippet OMZP::kubectl;   fi

# ─── History ──────────────────────────────────────────────────────────────────
HISTSIZE=5000
HISTFILE="${XDG_STATE_HOME}/zsh/history"
SAVEHIST=$HISTSIZE

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS

# ─── Shell Options ─────────────────────────────────────────────────────────────
setopt AUTO_CD              # type a directory path to cd into it
setopt AUTO_PUSHD           # make cd push the old directory to the stack
setopt PUSHD_IGNORE_DUPS    # no duplicate entries in the directory stack
setopt INTERACTIVE_COMMENTS # allow # comments in interactive shell
setopt EXTENDED_GLOB        # enable extended glob patterns (^, #, ~)

WORDCHARS='*?_[]~=&;!#$%^(){}'  # exclude - . / so Ctrl+W stops at path separators

autoload -Uz zmv  # mass rename utility: zmv '(*).txt' '$1.md'

# ─── Keybindings ──────────────────────────────────────────────────────────────
bindkey '^f' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
# Expands history expressions like !! or !$ when you press space
bindkey ' ' magic-space

# ─── Completion Styling ────────────────────────────────────────────────────────
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'

if command -v eza &>/dev/null; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
fi

# ─── Aliases ──────────────────────────────────────────────────────────────────
alias weather="curl 'wttr.in/?0'"
alias cls='clear'

if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ -x "/opt/homebrew/bin/nano" ]]; then
    alias nano="/opt/homebrew/bin/nano"
  fi
  alias perm='stat -f "%7Op %Sp%t%Su %SHp%t%Sg %SMp%tother %SLp%t%SN%ST"'
  alias flushDNS='dnscacheutil -flushcache'
else
  alias perm='stat --printf "%a %A %G %U %n\n"'
fi

if command -v yazi &>/dev/null; then
  alias y="yazi"
fi

if command -v tldr &>/dev/null; then
  export TEALDEER_CONFIG_DIR="${XDG_CONFIG_HOME}/tealdeer"
fi

if command -v bat &>/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
  alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
  alias -s md=bat
  alias -s txt=bat
  alias -s log=bat
  alias cat="bat"
fi

if command -v eza &>/dev/null; then
  export EZA_CONFIG_DIR="${XDG_CONFIG_HOME}/eza"
  alias ls='eza --grid -F --color=auto --icons=auto --group-directories-first --sort=name'
  alias ldot='ls -ld .*'
  alias lA='ls -lAhog'
else
  alias ls='ls --color'
fi

if [[ "$TERM" == "xterm-kitty" ]]; then
  alias ssh="kitty +kitten ssh"
fi

# ─── Cross-Platform Clipboard & Open ──────────────────────────────────────────

if [[ "$OSTYPE" == "darwin"* ]]; then
  alias copy="pbcopy"
  alias paste="pbpaste"
elif [[ -n "$WSL_DISTRO_NAME" ]]; then
  alias copy="clip.exe"
  alias paste="powershell.exe -command 'Get-Clipboard'"
  alias open="wslview"         # requires: sudo apt install wslu
elif command -v xclip &>/dev/null; then
  alias copy="xclip -selection clipboard"
  alias paste="xclip -selection clipboard -o"
  alias open="xdg-open"
elif command -v xsel &>/dev/null; then
  alias copy="xsel --clipboard --input"
  alias paste="xsel --clipboard --output"
  alias open="xdg-open"
fi

# ─── colorized output ─────────────────────────────────────────────────────────

if command -v grc &>/dev/null; then
  alias ping='grc --color=auto ping -c 4'
  alias ping8='grc --color=auto ping'
  alias netstat='grc --color=auto netstat'
  alias traceroute='grc --color=auto traceroute'
  alias mount='grc --color=auto mount'
  alias ps='grc --color=auto ps'
  alias lsof='grc --color=auto lsof'
  #alias curl='grc --color=auto curl'
  alias df='grc --colour=auto df -h'
  alias dig='grc --colour=auto dig'
  alias ifconfig='grc --colour=auto ifconfig'
  alias iostat='grc --colour=auto iostat'
  alias netstat='grc --colour=auto netstat'
  alias stat='grc --colour=auto stat'
  alias sysctl='grc --colour=auto sysctl'
  alias tcpdump='grc --colour=auto tcpdump'
  alias uptime='grc --colour=auto uptime'
  alias whois='grc --colour=auto whois'
else
  alias ping='ping -c 4'
  alias ping8='ping'
fi

if command -v kubecolor &>/dev/null; then
  alias kubectl='kubecolor'
fi

# ─── Package Managers ─────────────────────────────────────────────────────────

# Arch / CachyOS — prefer paru, fall back to yay
if [[ -f /etc/arch-release ]]; then
  if command -v paru &>/dev/null; then
    alias aur="paru"
  elif command -v yay &>/dev/null; then
    alias aur="yay"
  fi
fi

# Fedora
if [[ -f /etc/fedora-release ]]; then
  alias dnfi="sudo dnf install"
  alias dnfr="sudo dnf remove"
  alias dnfu="sudo dnf upgrade --refresh"
fi

# Debian / Ubuntu / Mint
if [[ -f /etc/debian_version ]]; then
  alias apti="sudo apt install"
  alias aptr="sudo apt remove"
  alias aptu="sudo apt update && sudo apt upgrade"
fi

# ─── Shell Integrations ────────────────────────────────────────────────────────

if command -v fzf &>/dev/null; then
  eval "$(fzf --zsh)"
fi

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# ─── SSH Agent ────────────────────────────────────────────────────────────────

if [[ "$OSTYPE" == "darwin"* ]]; then
  # launchd manages the agent process — just load all Keychain keys into it
  ssh-add --apple-load-keychain 2>/dev/null

elif [[ -n "$WSL_DISTRO_NAME" ]]; then
  # WSL: start a local agent if none is attached
  # To bridge to the Windows OpenSSH agent instead, see: github.com/rupor-github/wsl-ssh-agent
  if [[ -z "$SSH_AUTH_SOCK" ]] || ! ssh-add -l &>/dev/null; then
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add 2>/dev/null
  fi

else
  # Linux: persist the agent socket across terminals via a saved env file
  _ssh_env="${HOME}/.ssh/agent-env"
  [[ -f "$_ssh_env" ]] && source "$_ssh_env" >/dev/null
  ssh-add -l &>/dev/null; _agent_rc=$?
  if [[ $_agent_rc -eq 2 ]]; then
    # No agent running or socket is dead — start a fresh one
    ssh-agent > "$_ssh_env" && chmod 600 "$_ssh_env"
    source "$_ssh_env" >/dev/null
    ssh-add 2>/dev/null
  elif [[ $_agent_rc -eq 1 ]]; then
    # Agent running but empty — add default keys
    ssh-add 2>/dev/null
  fi
  unset _ssh_env _agent_rc
fi

# ─── Prompt ───────────────────────────────────────────────────────────────────

if command -v oh-my-posh &>/dev/null && [[ "$TERM_PROGRAM" != "Apple_Terminal" ]]; then
  eval "$(oh-my-posh init zsh --config "${XDG_CONFIG_HOME}/ohmyposh/my_brshprompt.omp.yaml")"
fi

# ─── Path ─────────────────────────────────────────────────────────────────────

export PATH="$HOME/.local/bin:$PATH"

# ─── Local Overrides ──────────────────────────────────────────────────────────
# Machine-specific settings (gitignored). Create: ~/.config/zsh/.zshrc.local
if [[ -f "${ZDOTDIR}/.zshrc.local" ]]; then
  source "${ZDOTDIR}/.zshrc.local"
fi
