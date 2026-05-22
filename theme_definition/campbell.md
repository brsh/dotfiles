# Extended Campbell Palette

> Derived from the **Microsoft Campbell 16** terminal color scheme — the default
> palette for Windows Terminal. This palette extends the standard 16 colors with
> interpolated midpoints, tints, and cross-hue blends, providing a harmonious
> **41-color vocabulary** for consistent theming across terminal tools.

---

## Files at a Glance

| File | Format | Purpose |
|------|--------|---------|
| `campbell.sh` | Bash / Zsh | `source` in `.zshrc` or `.bashrc` |
| `campbell.fish` | Fish | `source` in `config.fish` |
| `campbell.json` | JSON | Programmatic reference / scripting |
| `campbell.conf` | Kitty conf | `include` in `kitty.conf` |
| `campbell_palette.yaml` | YAML | Drop `palette:` block into `.omp.yaml` |

Variable naming conventions per format:

| Group | Bash/Fish | JSON | Oh My Posh |
|-------|-----------|------|------------|
| Core (normal) | `CAMPBELL_RED` | `red` | `dark-red` |
| Core (bright) | `CAMPBELL_RED_BRIGHT` | `red_bright` | `red` |
| Extended | `CAMPBELL_RED_MID` | `red_mid` | `red-mid` |
| Blends | `CAMPBELL_TEAL` | `teal` | `teal` |

---

## Color Reference

### Core 16 — Campbell Base

The original Microsoft Campbell 16, unchanged. These map directly to ANSI
terminal color slots 0–15 and are used for structural terminal elements.

| ANSI | Bash Variable | Hex | Semantic Use |
|------|---------------|-----|--------------|
| 0 | `CAMPBELL_BLACK` | `#0c0c0c` | Terminal background, deep background fills |
| 8 | `CAMPBELL_BLACK_BRIGHT` | `#767676` | Temp/bak files, robots.txt, dim gray |
| 1 | `CAMPBELL_RED` | `#c50f1f` | Hard errors, group-write perms, pom.xml |
| 9 | `CAMPBELL_RED_BRIGHT` | `#e74856` | Warnings, broken symlinks, hard links, HTML |
| 2 | `CAMPBELL_GREEN` | `#13a10e` | Group execute, bat/cmd scripts, success (dim) |
| 10 | `CAMPBELL_GREEN_BRIGHT` | `#16c60c` | Executables, git-new, size major, bash scripts |
| 3 | `CAMPBELL_YELLOW` | `#f19c00` | Pipes, group-read, Python, type-change |
| 11 | `CAMPBELL_YELLOW_BRIGHT` | `#f9f1a5` | JavaScript, user-read (bold), bright emphasis |
| 4 | `CAMPBELL_BLUE` | `#0037da` | Structural deep blue (unused in eza) |
| 12 | `CAMPBELL_BLUE_BRIGHT` | `#3b78ff` | Directories, git-modified, TypeScript, CSS |
| 5 | `CAMPBELL_MAGENTA` | `#881798` | Special perms (setuid/other), bmp/ico/tiff |
| 13 | `CAMPBELL_MAGENTA_BRIGHT` | `#b4009e` | Video files, webp |
| 6 | `CAMPBELL_CYAN` | `#3a96dd` | Docker/compose, Go, symlinks, aac/m4a |
| 14 | `CAMPBELL_CYAN_BRIGHT` | `#61d6d6` | Symlink paths, TOML, lossless audio, WAV |
| 7 | `CAMPBELL_WHITE` | `#cccccc` | Normal files, terminal foreground |
| 15 | `CAMPBELL_WHITE_BRIGHT` | `#f2f2f2` | Root user, header text, next.config |

---

### Extended — Interpolated Hue Families

Midpoints and tints interpolated between the normal and bright variants of each
core hue. Used for nuanced UI states and file-type distinctions within a family.

| Bash Variable | Hex | Semantic Use |
|---------------|-----|--------------|
| `CAMPBELL_RED_MID` | `#d63545` | Sockets, other-write perms, tar/gz archives, unset-mode |
| `CAMPBELL_RED_TINT` | `#f28b95` | Broken path overlay, 7z archives, select-mode |
| `CAMPBELL_GREEN_MID` | `#15b40f` | Other-execute perms, tmux.conf, zsh scripts |
| `CAMPBELL_GREEN_TINT` | `#5ad65a` | Size (byte), package.json, sh scripts, CSV/TSV |
| `CAMPBELL_YELLOW_MID` | `#f4b841` | Special files, git-renamed, user-read, size (mega) |
| `CAMPBELL_BLUE_MID` | `#1f5beb` | C++ (.cpp/.cc), TSX, Word docs (.doc/.docx), PowerShell |
| `CAMPBELL_BLUE_TINT` | `#7da6ff` | Mount points, C/C++ headers (.h/.hpp), .msi, Markdown |
| `CAMPBELL_MAGENTA_MID` | `#9c2bab` | Special user-file perms, C#, PHP, inode numbers, plist |
| `CAMPBELL_MAGENTA_TINT` | `#d04ecc` | Images (png, gif), mkv video, `which` desc text |
| `CAMPBELL_CYAN_MID` | `#4db5e5` | Audio (mp3), block device, Tailwind, Perl |
| `CAMPBELL_CYAN_TINT` | `#93e5e5` | YAML/YML, Nix, flake.nix, FLAC, cyan highlights |
| `CAMPBELL_GRAY_MID` | `#4d4d4d` | Punctuation, borders, git-ignored, .o/.a/.pyc, lock files |
| `CAMPBELL_GRAY_LT` | `#a0a0a0` | User/group other, flags, .editorconfig, ini/conf/cfg |

---

### Cross-Hue Blends

Colors interpolated across hue boundaries — distinct visual identities for
file types and elements that need to stand apart from any single hue family.

| Bash Variable | Hex | Semantic Use |
|---------------|-----|--------------|
| `CAMPBELL_TEAL` | `#2a9d8f` | Documents, Go, Vue, Fish, org, commitlint, build.gradle |
| `CAMPBELL_ORANGE` | `#e8790c` | Compiled (.so/.dylib), Rust, Java, XML, CMake, Svelte config |
| `CAMPBELL_ROSE` | `#d64d8a` | Ruby, GraphQL, SCSS/Sass, Gemfile/Rakefile |
| `CAMPBELL_INDIGO` | `#5856d6` | Terraform/HCL, Lua, F#, Haskell, ESLint, Prisma |
| `CAMPBELL_OLIVE` | `#8db600` | Clojure, Vim scripts, epub |
| `CAMPBELL_AMBER` | `#e6a117` | Other-read perms, DLLs/libs, Zig, .env files, user-you |
| `CAMPBELL_SLATE` | `#6987c9` | C files (.c), R language, date fields, Vagrant, RST docs |
| `CAMPBELL_PEACH` | `#e8916d` | Astro, deb/rpm packages, Brewfile, mobi/rlib |
| `CAMPBELL_VIOLET` | `#7b68ee` | WebAssembly, Kotlin, Elixir, octal permissions, AUTHORS |
| `CAMPBELL_AQUA` | `#47c8b0` | Dart, TeX/BibTeX, Go icon, downloads, db/sqlite |
| `CAMPBELL_CORAL` | `#f07e6e` | Swift, Svelte files, dmg/iso, SVG |
| `CAMPBELL_SKY` | `#5fb5e8` | SQL, JSX, ogg audio, Photoshop PSD, ada |

---

## Integration Guide

### Bash / Zsh

```zsh
# In .zshrc or .zshenv — define your dotfiles root once:
export DOTFILES="$HOME/path/to/dotfiles"

# Source the palette (e.g., in .zshrc):
source "${DOTFILES}/theme_definition/campbell.sh"

# Variables are then available in the shell and scripts:
echo "Directories are: ${CAMPBELL_BLUE_BRIGHT}"
```

For use in ANSI escape sequences (e.g., custom prompt segments):
```zsh
# Convert a CAMPBELL_* hex like #3b78ff → R=59 G=120 B=255
# then use \e[38;2;R;G;Bm for foreground, \e[48;2;R;G;Bm for background
```

---

### Fish

```fish
# In config.fish:
source $DOTFILES/theme_definition/campbell.fish

# Variables are immediately available:
set_color $CAMPBELL_BLUE_BRIGHT
echo "Directories"
set_color normal
```

To persist across sessions without sourcing, copy the `set -U` (universal)
variant or use `set -Ux` for individual entries.

---

### Kitty

```conf
# In kitty.conf — replaces or supplements any existing theme include:
include /path/to/theme_definition/campbell.conf

# Extended/blend colors not assignable to ANSI slots can be used directly
# in any kitty option that accepts a hex color, for example:
tab_bar_background    #0c0c0c
tab_active_foreground #f9f1a5
active_border_color   #3b78ff
inactive_border_color #4d4d4d
```

> **Note:** The `include` directive requires an absolute path or a path
> relative to `kitty.conf`. If your dotfiles are symlinked via stow, use the
> real path to `theme_definition/campbell.conf` (e.g. `$DOTFILES/theme_definition/campbell.conf`).

---

### Oh My Posh

Copy the `palette:` block from `campbell_palette.yaml` into any `.omp.yaml`
theme, replacing the existing `palette:` section. Then reference colors in
segment templates using `p:name`:

```yaml
# Example segment using Extended Campbell colors:
- type: path
  foreground: 'p:green'
  template: '<p:blue-tint>[</><p:white> {{ .Path }} </><p:blue-tint>]</>'

- type: git
  template: >-
    <p:white>[</>{{ .HEAD }}
    {{ if .Working.Changed }}<p:amber> {{ .Working.String }}</>{{ end }}
    {{ if .Staging.Changed }}<p:green-tint> {{ .Staging.String }}</>{{ end }}
    <p:white>]</>
```

> **Compatibility note:** Your existing `my_brshprompt.omp.yaml` uses
> `dark-yellow: '#C19C00'` — this palette corrects it to the canonical
> Campbell value `#f19c00`. Visually similar, but update any direct
> `p:dark-yellow` references if you switch.
> The existing `p:purple` / `p:dark-purple` keys are preserved (OMP uses
> "purple" for what this palette calls "magenta").

---

### Yazi

Yazi uses inline hex values in `theme.toml` and flavor TOML files — there is
no native palette variable system. Reference the hex values directly from
`campbell.json` or the comments in this document when building or updating
`~/.config/yazi/flavors/theme-dark.toml`:

```toml
# Example using Extended Campbell values:
[mgr]
cwd = { fg = "#3b78ff" }           # CAMPBELL_BLUE_BRIGHT

[filetype]
rules = [
  { mime = "image/*",            fg = "#d04ecc" },  # CAMPBELL_MAGENTA_TINT
  { mime = "{audio,video}/*",    fg = "#b4009e" },  # CAMPBELL_MAGENTA_BRIGHT
  { mime = "application/{zip,*tar*,*z*}", fg = "#d63545" },  # CAMPBELL_RED_MID
]
```

---

### btop

btop uses a `.theme` file in `~/.config/btop/themes/`. The theme format maps
named semantic slots to hex values — reference the Extended Campbell colors
when building a custom `campbell.theme`:

```ini
# ~/.config/btop/themes/campbell.theme
# Set in btop.conf: color_theme = "campbell"

theme[main_bg]="#0c0c0c"          # CAMPBELL_BLACK
theme[main_fg]="#cccccc"          # CAMPBELL_WHITE
theme[title]="#3b78ff"            # CAMPBELL_BLUE_BRIGHT
theme[hi_fg]="#16c60c"            # CAMPBELL_GREEN_BRIGHT
theme[selected_bg]="#1f5beb"      # CAMPBELL_BLUE_MID
theme[selected_fg]="#f2f2f2"      # CAMPBELL_WHITE_BRIGHT
theme[inactive_fg]="#4d4d4d"      # CAMPBELL_GRAY_MID
theme[graph_text]="#a0a0a0"       # CAMPBELL_GRAY_LT
theme[meter_bg]="#4d4d4d"         # CAMPBELL_GRAY_MID
theme[proc_misc]="#f4b841"        # CAMPBELL_YELLOW_MID
theme[cpu_box]="#3b78ff"          # CAMPBELL_BLUE_BRIGHT
theme[mem_box]="#16c60c"          # CAMPBELL_GREEN_BRIGHT
theme[net_box]="#61d6d6"          # CAMPBELL_CYAN_BRIGHT
theme[proc_box]="#9c2bab"         # CAMPBELL_MAGENTA_MID
theme[div_line]="#4d4d4d"         # CAMPBELL_GRAY_MID
theme[temp_start]="#16c60c"       # CAMPBELL_GREEN_BRIGHT
theme[temp_mid]="#f4b841"         # CAMPBELL_YELLOW_MID
theme[temp_end]="#e74856"         # CAMPBELL_RED_BRIGHT
theme[cpu_start]="#16c60c"        # CAMPBELL_GREEN_BRIGHT
theme[cpu_mid]="#f4b841"          # CAMPBELL_YELLOW_MID
theme[cpu_end]="#e74856"          # CAMPBELL_RED_BRIGHT
theme[free_start]="#5ad65a"       # CAMPBELL_GREEN_TINT
theme[free_mid]="#f4b841"         # CAMPBELL_YELLOW_MID
theme[free_end]="#d63545"         # CAMPBELL_RED_MID
theme[download_start]="#3b78ff"   # CAMPBELL_BLUE_BRIGHT
theme[download_mid]="#61d6d6"     # CAMPBELL_CYAN_BRIGHT
theme[download_end]="#93e5e5"     # CAMPBELL_CYAN_TINT
theme[upload_start]="#f19c00"     # CAMPBELL_YELLOW
theme[upload_mid]="#f4b841"       # CAMPBELL_YELLOW_MID
theme[upload_end]="#f9f1a5"       # CAMPBELL_YELLOW_BRIGHT
```

---

## Complete Hex Quick-Reference

```
─── Core 16 ────────────────────────────────────────────────────────────────────
  black          #0c0c0c    black_bright   #767676
  red            #c50f1f    red_bright     #e74856
  green          #13a10e    green_bright   #16c60c
  yellow         #f19c00    yellow_bright  #f9f1a5
  blue           #0037da    blue_bright    #3b78ff
  magenta        #881798    magenta_bright #b4009e
  cyan           #3a96dd    cyan_bright    #61d6d6
  white          #cccccc    white_bright   #f2f2f2

─── Extended ───────────────────────────────────────────────────────────────────
  red_mid        #d63545    red_tint       #f28b95
  green_mid      #15b40f    green_tint     #5ad65a
  yellow_mid     #f4b841
  blue_mid       #1f5beb    blue_tint      #7da6ff
  magenta_mid    #9c2bab    magenta_tint   #d04ecc
  cyan_mid       #4db5e5    cyan_tint      #93e5e5
  gray_mid       #4d4d4d    gray_lt        #a0a0a0

─── Cross-Hue Blends ───────────────────────────────────────────────────────────
  teal    #2a9d8f    orange  #e8790c    rose    #d64d8a
  indigo  #5856d6    olive   #8db600    amber   #e6a117
  slate   #6987c9    peach   #e8916d    violet  #7b68ee
  aqua    #47c8b0    coral   #f07e6e    sky     #5fb5e8
```
