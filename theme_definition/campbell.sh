#!/usr/bin/env bash
# Extended Campbell Palette — Bash / Zsh
#
# Derived from Microsoft Campbell 16 with interpolated midpoints, tints,
# and cross-hue blends for consistent theming across terminal tools.
#
# Usage:
#   source /path/to/theme_definition/campbell.sh
#
# Variables are plain shell variables (not exported). To export for child
# processes: set -a; source campbell.sh; set +a

# ─── Core 16 — Campbell Base ──────────────────────────────────────────────────
#   The original Microsoft Campbell 16, unchanged.

CAMPBELL_BLACK="#0c0c0c"            # ansi 0  — terminal background
CAMPBELL_BLACK_BRIGHT="#767676"     # ansi 8  — dim/temp text, gray mid-dark

CAMPBELL_RED="#c50f1f"              # ansi 1  — errors, hard failures
CAMPBELL_RED_BRIGHT="#e74856"       # ansi 9  — warnings, broken symlinks

CAMPBELL_GREEN="#13a10e"            # ansi 2  — group execute, success (dim)
CAMPBELL_GREEN_BRIGHT="#16c60c"     # ansi 10 — executables, git-new, success

CAMPBELL_YELLOW="#f19c00"           # ansi 3  — pipes, group-read, config
CAMPBELL_YELLOW_BRIGHT="#f9f1a5"    # ansi 11 — JavaScript, bright emphasis

CAMPBELL_BLUE="#0037da"             # ansi 4  — structural / deep blue
CAMPBELL_BLUE_BRIGHT="#3b78ff"      # ansi 12 — directories, TypeScript, CSS

CAMPBELL_MAGENTA="#881798"          # ansi 5  — special perms (setuid), bmp/ico
CAMPBELL_MAGENTA_BRIGHT="#b4009e"   # ansi 13 — video files, webp

CAMPBELL_CYAN="#3a96dd"             # ansi 6  — Docker, Go, symlinks
CAMPBELL_CYAN_BRIGHT="#61d6d6"      # ansi 14 — symlink paths, lossless audio

CAMPBELL_WHITE="#cccccc"            # ansi 7  — normal files, foreground
CAMPBELL_WHITE_BRIGHT="#f2f2f2"     # ansi 15 — root user, header text

# ─── Extended — Interpolated Hue Families ─────────────────────────────────────
#   Midpoints and tints between the normal/bright pairs of the core palette.

CAMPBELL_RED_MID="#d63545"          # midpoint red — sockets, other-write, tar/gz
CAMPBELL_RED_TINT="#f28b95"         # tint red     — broken path overlay, 7z

CAMPBELL_GREEN_MID="#15b40f"        # midpoint green — other-execute, tmux, zsh
CAMPBELL_GREEN_TINT="#5ad65a"       # tint green     — size byte, package.json, sh

CAMPBELL_YELLOW_MID="#f4b841"       # midpoint yellow — special files, git-renamed, size mega

CAMPBELL_BLUE_MID="#1f5beb"         # midpoint blue — C++, TSX, Word docs
CAMPBELL_BLUE_TINT="#7da6ff"        # tint blue     — mount points, .h/.hpp headers

CAMPBELL_MAGENTA_MID="#9c2bab"      # midpoint magenta — C#, PHP, inode number
CAMPBELL_MAGENTA_TINT="#d04ecc"     # tint magenta     — images (png), mkv video

CAMPBELL_CYAN_MID="#4db5e5"         # midpoint cyan — audio (mp3), blocks, Perl
CAMPBELL_CYAN_TINT="#93e5e5"        # tint cyan     — YAML, Nix, flake.nix, FLAC

CAMPBELL_GRAY_MID="#4d4d4d"         # mid gray  — punctuation, borders, git-ignored
CAMPBELL_GRAY_LT="#a0a0a0"          # light gray — user/group other, flags, ini/conf

# ─── Cross-Hue Blends ─────────────────────────────────────────────────────────
#   Colors interpolated across hue boundaries — unique identities for file
#   types and UI elements that extend beyond a single hue family.

CAMPBELL_TEAL="#2a9d8f"             # blue-green   — documents, Go, Vue, Fish, org
CAMPBELL_ORANGE="#e8790c"           # red-yellow   — compiled (so/dylib), Rust, Java, XML
CAMPBELL_ROSE="#d64d8a"             # red-magenta  — Ruby, GraphQL, SCSS/Sass
CAMPBELL_INDIGO="#5856d6"           # blue-magenta — Terraform/HCL, Lua, Haskell, ESLint
CAMPBELL_OLIVE="#8db600"            # yellow-green — Clojure, Vim scripts, epub
CAMPBELL_AMBER="#e6a117"            # warm yellow  — other-read, DLLs/libs, Zig, .env
CAMPBELL_SLATE="#6987c9"            # blue-gray    — C files, R language, date fields
CAMPBELL_PEACH="#e8916d"            # warm orange  — Astro, deb/rpm, Brewfile
CAMPBELL_VIOLET="#7b68ee"           # soft purple  — WebAssembly, Kotlin, Elixir, octal
CAMPBELL_AQUA="#47c8b0"             # blue-green   — Dart, TeX/BibTeX, downloads
CAMPBELL_CORAL="#f07e6e"            # salmon       — Swift, Svelte, dmg/iso
CAMPBELL_SKY="#5fb5e8"              # light blue   — SQL, JSX, sky-blue accents
