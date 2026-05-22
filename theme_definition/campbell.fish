# Extended Campbell Palette — Fish Shell
#
# Derived from Microsoft Campbell 16 with interpolated midpoints, tints,
# and cross-hue blends for consistent theming across terminal tools.
#
# Usage:
#   source /path/to/theme_definition/campbell.fish
#
# Variables are set as global (-g) for the current session. Use -U (universal)
# if you want them to persist across Fish sessions without sourcing.

# ─── Core 16 — Campbell Base ──────────────────────────────────────────────────

set -g CAMPBELL_BLACK          "#0c0c0c"    # ansi 0  — terminal background
set -g CAMPBELL_BLACK_BRIGHT   "#767676"    # ansi 8  — dim/temp text

set -g CAMPBELL_RED            "#c50f1f"    # ansi 1  — errors, hard failures
set -g CAMPBELL_RED_BRIGHT     "#e74856"    # ansi 9  — warnings, broken symlinks

set -g CAMPBELL_GREEN          "#13a10e"    # ansi 2  — group execute, success (dim)
set -g CAMPBELL_GREEN_BRIGHT   "#16c60c"    # ansi 10 — executables, git-new

set -g CAMPBELL_YELLOW         "#f19c00"    # ansi 3  — pipes, group-read
set -g CAMPBELL_YELLOW_BRIGHT  "#f9f1a5"    # ansi 11 — JavaScript, bright emphasis

set -g CAMPBELL_BLUE           "#0037da"    # ansi 4  — structural / deep blue
set -g CAMPBELL_BLUE_BRIGHT    "#3b78ff"    # ansi 12 — directories, TypeScript

set -g CAMPBELL_MAGENTA        "#881798"    # ansi 5  — special perms, bmp/ico
set -g CAMPBELL_MAGENTA_BRIGHT "#b4009e"    # ansi 13 — video files, webp

set -g CAMPBELL_CYAN           "#3a96dd"    # ansi 6  — Docker, Go, symlinks
set -g CAMPBELL_CYAN_BRIGHT    "#61d6d6"    # ansi 14 — symlink paths, lossless audio

set -g CAMPBELL_WHITE          "#cccccc"    # ansi 7  — normal files, foreground
set -g CAMPBELL_WHITE_BRIGHT   "#f2f2f2"    # ansi 15 — root user, header text

# ─── Extended — Interpolated Hue Families ─────────────────────────────────────

set -g CAMPBELL_RED_MID        "#d63545"    # midpoint red — sockets, other-write
set -g CAMPBELL_RED_TINT       "#f28b95"    # tint red     — broken path overlay, 7z

set -g CAMPBELL_GREEN_MID      "#15b40f"    # midpoint green — other-execute, tmux
set -g CAMPBELL_GREEN_TINT     "#5ad65a"    # tint green     — size byte, package.json

set -g CAMPBELL_YELLOW_MID     "#f4b841"    # midpoint yellow — special files, git-renamed

set -g CAMPBELL_BLUE_MID       "#1f5beb"    # midpoint blue — C++, TSX, Word docs
set -g CAMPBELL_BLUE_TINT      "#7da6ff"    # tint blue     — mount points, headers

set -g CAMPBELL_MAGENTA_MID    "#9c2bab"    # midpoint magenta — C#, PHP, inode
set -g CAMPBELL_MAGENTA_TINT   "#d04ecc"    # tint magenta     — images (png), mkv

set -g CAMPBELL_CYAN_MID       "#4db5e5"    # midpoint cyan — audio (mp3), Perl
set -g CAMPBELL_CYAN_TINT      "#93e5e5"    # tint cyan     — YAML, Nix, FLAC

set -g CAMPBELL_GRAY_MID       "#4d4d4d"    # mid gray  — punctuation, borders
set -g CAMPBELL_GRAY_LT        "#a0a0a0"    # light gray — deemphasized text, flags

# ─── Cross-Hue Blends ─────────────────────────────────────────────────────────

set -g CAMPBELL_TEAL    "#2a9d8f"   # blue-green   — documents, Go, Vue, Fish
set -g CAMPBELL_ORANGE  "#e8790c"   # red-yellow   — compiled, Rust, Java, XML
set -g CAMPBELL_ROSE    "#d64d8a"   # red-magenta  — Ruby, GraphQL, SCSS/Sass
set -g CAMPBELL_INDIGO  "#5856d6"   # blue-magenta — Terraform, Lua, ESLint
set -g CAMPBELL_OLIVE   "#8db600"   # yellow-green — Clojure, Vim scripts, epub
set -g CAMPBELL_AMBER   "#e6a117"   # warm yellow  — other-read, DLLs, Zig, .env
set -g CAMPBELL_SLATE   "#6987c9"   # blue-gray    — C files, R language, dates
set -g CAMPBELL_PEACH   "#e8916d"   # warm orange  — Astro, deb/rpm, Brewfile
set -g CAMPBELL_VIOLET  "#7b68ee"   # soft purple  — WebAssembly, Kotlin, Elixir
set -g CAMPBELL_AQUA    "#47c8b0"   # blue-green   — Dart, TeX/BibTeX, downloads
set -g CAMPBELL_CORAL   "#f07e6e"   # salmon       — Swift, Svelte, dmg/iso
set -g CAMPBELL_SKY     "#5fb5e8"   # light blue   — SQL, JSX, sky-blue accents
