#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ─── Constants ────────────────────────────────────────────────────────────────
readonly SCRIPT_NAME="$(basename "$0")"
readonly SOURCE_DIR="$HOME/.config/ai-rules"

# Tool targets — directory symlink from target → SOURCE_DIR
# Claude Code reads from SOURCE_DIR directly (via CLAUDE.md folder instruction)
# and does not require a symlink.
TOOL_NAMES=("devin" "windsurf")
TOOL_PATHS=("$HOME/.devin/rules" "$HOME/.windsurf/rules")
# Uncomment to include Cursor:
# TOOL_NAMES+=("cursor")
# TOOL_PATHS+=("$HOME/.cursor/rules")

# ─── Functions ────────────────────────────────────────────────────────────────
log()   { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*" >&2; }
error() { echo "[ERROR] $*" >&2; }
die()   { error "$*"; exit 1; }

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Link AI rule files from $SOURCE_DIR into each tool's config directory.
Creates directory symlinks so all tools share the same canonical rule files.

Claude Code reads from $SOURCE_DIR directly (via CLAUDE.md folder instruction)
and does not require a symlink.

Options:
  -h, --help      Show this help message
  -n, --dry-run   Show what would be done without doing it

Targets:
EOF
    local i
    for i in "${!TOOL_NAMES[@]}"; do
        echo "  ${TOOL_NAMES[$i]} → ${TOOL_PATHS[$i]}"
    done
}

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Would run: $*"
    else
        "$@"
    fi
}

link_rules() {
    local tool="$1"
    local target="$2"
    local parent_dir
    parent_dir="$(dirname "$target")"

    if [[ ! -d "$parent_dir" ]]; then
        run_cmd mkdir -p "$parent_dir"
        log "$tool: created $parent_dir"
    fi

    if [[ -L "$target" ]]; then
        local current_target
        current_target="$(readlink "$target")"
        if [[ "$current_target" == "$SOURCE_DIR" ]]; then
            log "$tool: already linked correctly"
            return 0
        fi
        warn "$tool: existing symlink points to $current_target, replacing"
        run_cmd rm "$target"
    elif [[ -d "$target" ]]; then
        if [[ -n "$(ls -A "$target" 2>/dev/null)" ]]; then
            warn "$tool: $target is a non-empty directory, skipping (back up and remove manually)"
            return 1
        fi
        run_cmd rmdir "$target"
    fi

    run_cmd ln -sfn "$SOURCE_DIR" "$target"
    log "$tool: linked $target → $SOURCE_DIR"
}

# ─── Argument Parsing ─────────────────────────────────────────────────────────
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -n|--dry-run) DRY_RUN=true ;;
        -*)           die "Unknown option: $1" ;;
        *)            die "Unexpected argument: $1" ;;
    esac
    shift
done

# ─── Main Logic ───────────────────────────────────────────────────────────────
main() {
    [[ -d "$SOURCE_DIR" ]] || die "Source directory not found: $SOURCE_DIR (run 'stow ai-rules' first)"

    local file_count
    file_count="$(find "$SOURCE_DIR" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
    log "Found $file_count rule file(s) in $SOURCE_DIR"

    local failures=0
    local i
    for i in "${!TOOL_NAMES[@]}"; do
        if ! link_rules "${TOOL_NAMES[$i]}" "${TOOL_PATHS[$i]}"; then
            ((failures++)) || true
        fi
    done

    if [[ "$failures" -gt 0 ]]; then
        warn "$failures target(s) skipped — see warnings above"
        exit 1
    fi

    log "All targets linked successfully"
}

main "$@"
