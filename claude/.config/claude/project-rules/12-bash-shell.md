---
trigger: glob
glob: "**/*.{sh,bash}"
description: "Bash/shell scripting best practices for sysadmin automation"
---

# Bash / Shell Scripting Rules

---

## Required Script Header

Every script must start with this safety header:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

What each option does:
- `set -e` — exit immediately if any command returns a non-zero exit code
- `set -u` — treat unset variables as errors (prevents silent use of empty `$VAR`)
- `set -o pipefail` — a pipe fails if any command in it fails (not just the last one)
- `IFS=$'\n\t'` — safer word splitting (prevents glob expansion on spaces in filenames)

---

## Script Structure

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ─── Constants ────────────────────────────────────────────────────────────────
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.sh}.log"

# ─── Functions ────────────────────────────────────────────────────────────────
log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $*" | tee -a "$LOG_FILE"; }
warn()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]  $*" | tee -a "$LOG_FILE" >&2; }
error()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" | tee -a "$LOG_FILE" >&2; }
die()     { error "$*"; exit 1; }

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] <target>

Description of what this script does.

Options:
  -h, --help      Show this help message
  -v, --verbose   Enable verbose output
  -n, --dry-run   Show what would be done without doing it

Examples:
  $SCRIPT_NAME --verbose server01
EOF
}

# ─── Argument Parsing ─────────────────────────────────────────────────────────
VERBOSE=false
DRY_RUN=false
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--verbose) VERBOSE=true ;;
        -n|--dry-run) DRY_RUN=true ;;
        -*)           die "Unknown option: $1" ;;
        *)            TARGET="$1" ;;
    esac
    shift
done

[[ -z "$TARGET" ]] && { usage; die "TARGET is required."; }

# ─── Dependency Check ─────────────────────────────────────────────────────────
require_cmd() {
    command -v "$1" &>/dev/null || die "Required command not found: $1"
}
require_cmd curl
require_cmd jq

# ─── Cleanup on Exit ──────────────────────────────────────────────────────────
TMPDIR_LOCAL="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_LOCAL"' EXIT

# ─── Main Logic ───────────────────────────────────────────────────────────────
main() {
    log "Starting $SCRIPT_NAME for target: $TARGET"
    # ... logic here ...
}

main "$@"
```

---

## Variable Handling

Always quote variables to prevent word splitting and glob expansion:

```bash
# Good — quoted
echo "Processing: $filename"
if [[ -f "$config_file" ]]; then ...

# Bad — unquoted (breaks on filenames with spaces)
echo "Processing: " $filename
if [ -f $config_file ]; then ...
```

Use `${variable}` form when adjacent to other characters:

```bash
echo "${prefix}_backup_${date}.tar.gz"
```

Use `readonly` for constants:

```bash
readonly MAX_RETRIES=3
readonly BASE_URL="https://api.example.com"
```

Use `local` for all function-local variables:

```bash
process_server() {
    local server="$1"
    local port="${2:-22}"
    ...
}
```

---

## Conditionals

Use `[[ ]]` (bash built-in) over `[ ]` (POSIX sh) for bash scripts:

```bash
# Preferred — [[ ]] handles edge cases better
if [[ "$status" == "active" ]]; then ...
if [[ -z "$var" ]]; then ...          # is empty
if [[ -n "$var" ]]; then ...          # is not empty
if [[ "$count" -gt 10 ]]; then ...    # numeric comparison
if [[ "$file" =~ \.log$ ]]; then ...  # regex match

# Avoid in bash — use [[ ]] instead
if [ "$status" = "active" ]; then ...
```

---

## Error Handling

```bash
# Check return code explicitly when needed
if ! ssh -q "$server" "uptime"; then
    error "SSH to $server failed"
    return 1
fi

# One-liner for "die on failure"
mkdir -p "$backup_dir" || die "Failed to create backup directory: $backup_dir"

# Trap for unexpected exits
cleanup() {
    local exit_code=$?
    [[ $exit_code -ne 0 ]] && error "Script exited unexpectedly (code: $exit_code)"
    # cleanup temp files etc.
}
trap cleanup EXIT
```

---

## Dry Run Pattern

For scripts that modify system state, always add a dry-run mode:

```bash
DRY_RUN=false

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Would run: $*"
    else
        "$@"
    fi
}

# Usage
run_cmd systemctl restart nginx
run_cmd rm -f "$old_config"
```

---

## String Operations

```bash
# Substring extraction
filename="backup_2024-01-15.tar.gz"
basename="${filename%.tar.gz}"       # removes suffix: backup_2024-01-15
extension="${filename##*.}"          # gets last extension: gz
prefix="${filename%%_*}"             # removes longest suffix from _: backup

# Replace
new="${old_string/find/replace}"     # replace first
new="${old_string//find/replace}"    # replace all

# String length
len="${#myvar}"

# Default value if unset
port="${PORT:-8080}"                 # use 8080 if PORT is unset or empty
```

---

## Loops

```bash
# Iterate over a list of servers
servers=("web01" "web02" "db01")
for server in "${servers[@]}"; do
    log "Checking $server..."
    ssh "$server" "uptime"
done

# Process file line by line
while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue   # skip comments
    [[ -z "$line" ]] && continue      # skip empty lines
    process_line "$line"
done < "$input_file"

# Never parse ls output — use globs or find
for logfile in /var/log/app/*.log; do
    [[ -f "$logfile" ]] || continue   # guard against empty glob
    gzip "$logfile"
done
```

---

## Here Documents

```bash
# Multi-line string
cat <<'EOF'
This is literal text with $no variable expansion
EOF

# With variable expansion (no quotes on EOF)
cat <<EOF
Server: $hostname
Date: $(date)
EOF

# Indented (use <<- with tabs, not spaces)
if true; then
    cat <<-EOF
	This line is indented with a tab character
	EOF
fi
```

---

## ShellCheck

Run **ShellCheck** on all scripts before committing:

```bash
shellcheck script.sh          # check single file
shellcheck -x script.sh       # follow sourced files
shellcheck --format=gcc *.sh  # GCC-style output for CI
```

Install: `apt install shellcheck` / `brew install shellcheck` / `winget install koalaman.shellcheck`

Configure a `.shellcheckrc` to suppress false positives project-wide rather than
adding `# shellcheck disable=...` inline.

---

## Common Pitfalls to Flag

- Unquoted variables `$var` → should be `"$var"` in most contexts
- Using `[ ]` → suggest `[[ ]]` in bash scripts
- `ls | grep` or parsing `ls` output → use globs or `find` instead
- No `set -euo pipefail` header → always add it
- Temp files not cleaned up → use `mktemp` + `trap ... EXIT`
- Backtick command substitution → use `$(command)` instead
- `cd /some/path && rm ...` without error check → use `cd /some/path || exit 1` first
- Hardcoded absolute paths like `/home/username/` → use `$HOME` or relative paths
- No dependency check for external commands → add `command -v tool || die "..."` checks
- `echo` used for debug output that stays in production → use a logging function
