# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level folder is a **stow package** that mirrors the directory structure relative to `$HOME`. Running `stow <package>` creates symlinks from `~/` into the dotfiles repo, keeping configs version-controlled and portable across machines.

## Prerequisites

- **Git** (to clone the repo)
- **GNU Stow** (`brew install stow` / `apt install stow` / `pacman -S stow`)

## Quick Start

```bash
# Clone the repo
git clone https://github.com/brsh/dotfiles.git ~/Scripts/1_repos/dotfiles
cd ~/Scripts/1_repos/dotfiles

# Stow whichever packages you need
stow zsh
stow kitty
stow ohmyposh
```

That's it. Stow reads `.stowrc` (included in the repo) which sets `--target=~/`, so you don't need to pass `-t ~` manually.

## How Stow Works

Stow creates symlinks that mirror a package's folder structure into the target directory (`~/`). For example:

```text
dotfiles/
└── kitty/
    └── .config/
        └── kitty/
            └── kitty.conf

  stow kitty  →  ~/.config/kitty/kitty.conf  →  symlink to dotfiles/kitty/.config/kitty/kitty.conf
```

**Key behaviors:**

- **Tree folding:** If the target directory doesn't exist, stow creates a single directory-level symlink instead of individual file symlinks. This is efficient, but can be surprising for shared directories like `~/.local/bin/` (see the warning below).
- **Conflict detection:** Stow will refuse to overwrite existing files that aren't stow-managed. It reports conflicts and exits cleanly.
- **Unstow:** `stow -D <package>` removes the symlinks created by that package.
- **Restow:** `stow -R <package>` removes and re-creates symlinks (useful after adding files to a package).

### The `~/.local/bin/` Warning

Many tools install executables to `~/.local/bin/` (pip, cargo, go, npm, etc.). If that directory doesn't exist yet when you stow a package that targets it, stow will "tree-fold" and create `~/.local/bin` as a directory symlink pointing into the dotfiles repo. This means other tools would then write their binaries into your dotfiles repo, which is messy.

**To prevent this**, ensure shared directories exist as real directories before stowing:

```bash
mkdir -p ~/.local/bin
```

With that directory already in place, stow creates only file-level symlinks inside it.

## Stow Packages

### Shell and Terminal

| Package | Installs to | Description |
|---|---|---|
| `bash` | `~/.config/bash/` | Bash shell configuration |
| `zsh` | `~/.config/zsh/` | Zsh shell configuration |
| `fish` | `~/.config/fish/` | Fish shell configuration |
| `kitty` | `~/.config/kitty/` | Kitty terminal emulator |
| `tmux` | `~/.config/tmux/` (or `~/.tmux.conf`) | Tmux multiplexer |
| `ohmyposh` | `~/.config/ohmyposh/` | Oh My Posh prompt theme |
| `carapace` | `~/.config/carapace/` | Carapace shell completions |

### CLI Tools

| Package | Installs to | Description |
|---|---|---|
| `bat` | `~/.config/bat/` | bat (cat replacement) config |
| `eza` | `~/.config/eza/` | eza (ls replacement) config |
| `lazygit` | `~/.config/lazygit/` | Lazygit TUI config |
| `yazi` | `~/.config/yazi/` | Yazi file manager config |
| `btop` | `~/.config/btop/` | btop system monitor config |
| `nano` | `~/.config/nano/` (or `~/.nanorc`) | Nano editor config |
| `tealdeer` | `~/.config/tealdeer/` | tldr client config |

### Languages and Editors

| Package | Installs to | Description |
|---|---|---|
| `powershell` | `~/.config/powershell/` | PowerShell profile and config |

### macOS

| Package | Installs to | Description |
|---|---|---|
| `karabiner` | `~/.config/karabiner/` | Karabiner-Elements key remapping |

### AI Coding Tools

| Package | Installs to | Description |
|---|---|---|
| `ai-rules` | `~/.config/ai-rules/` | Shared AI rule files (languages, tools, OS) |
| `ai-rules-work` | `~/.config/ai-rules/` | Work environment context |
| `ai-rules-personal` | `~/.config/ai-rules/` | Personal/home lab environment context |
| `claude` | `~/.claude/` | Claude Code global instructions (CLAUDE.md) |

### Scripts

| Package | Installs to | Description |
|---|---|---|
| `01-Scripts` | `~/.local/bin/` | Utility scripts |

### Not Stow Packages

| Folder | Purpose |
|---|---|
| `00-Notes/` | Reference notes (not stowed) |
| `theme_definition/` | Extended Campbell color palette definitions (not stowed) |

## AI Rules Setup

The AI rule files live in `ai-rules/.config/ai-rules/` and follow a numbered naming convention:

- `00-09` load on every session (communication style, safety guardrails)
- `10-19` are language-specific (PowerShell, Python, Bash, C#)
- `20-29` are OS/environment-specific (Windows, Linux)
- `30-49` are tools and infrastructure (Ansible, Terraform, Docker, Git, WSL2, K8s, AWS, etc.)
- `50-59` are modes (security review, planning, voice)

### Work vs. Personal

Only one environment package should be stowed on a given machine:

```bash
# On a work machine
stow ai-rules ai-rules-work

# On a personal machine
stow ai-rules ai-rules-personal
```

Both packages stow into `~/.config/ai-rules/`, so the environment file (`25-work-environment.md` or `25-personal-environment.md`) lands alongside the shared rule files.

### Claude Code

Claude Code reads rules from `~/.config/ai-rules/` directly, as instructed by `CLAUDE.md`. No additional setup is needed beyond stowing:

```bash
stow claude ai-rules
```

### Devin and Windsurf

Devin and Windsurf expect their rule files at `~/.devin/rules/` and `~/.windsurf/rules/` respectively. The `ai-rules-sync-to-devin.sh` script creates directory symlinks from those locations to `~/.config/ai-rules/`, so all tools share the same canonical rule files.

**Setup:**

```bash
# Ensure ~/.local/bin exists as a real directory (prevents stow tree-folding)
mkdir -p ~/.local/bin

# Stow the scripts package
stow 01-Scripts

# Dry-run first to see what would happen
ai-rules-sync-to-devin.sh -n

# Create the symlinks
ai-rules-sync-to-devin.sh
```

**What the script does:**

1. Checks that `~/.config/ai-rules/` exists (if not, reminds you to `stow ai-rules` first)
2. For each tool (Devin, Windsurf), creates the parent directory (`~/.devin/`, `~/.windsurf/`) if needed
3. Creates a directory symlink: `~/.devin/rules` -> `~/.config/ai-rules/`
4. Handles edge cases: skips if already linked correctly, replaces stale symlinks, refuses to overwrite non-empty directories

**Flags:**

- `-n, --dry-run` shows what would be done without making changes
- `-h, --help` prints usage and the list of targets

## Full Setup Example

```bash
cd ~/Scripts/1_repos/dotfiles

# Prevent stow tree-folding on shared directories
mkdir -p ~/.local/bin
mkdir -p ~/.config

# Stow desired packages
stow zsh bash kitty ohmyposh bat eza lazygit yazi btop tmux nano

# AI rules (pick work or personal, not both)
stow claude ai-rules ai-rules-work
stow 01-Scripts
ai-rules-sync-to-devin.sh

# macOS only
stow karabiner
```

## Local Overrides

Some packages support machine-local override files that are gitignored:

- `bash/.config/bash/bash.bashrc.local` for per-machine bash config
- `zsh/.config/zsh/.zshrc.local` for per-machine zsh config
- `kitty/.config/kitty/hosts/<hostname>.conf` for per-host kitty settings
- `ohmyposh/.config/ohmyposh/*.local.yaml` for per-machine prompt overrides

These files are listed in `.gitignore` and will not be committed.
