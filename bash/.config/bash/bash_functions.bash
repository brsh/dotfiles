# bash_functions.bash — utility functions for interactive bash sessions.

# ─── Color tables ─────────────────────────────────────────────────────────────

function list_colors {
    local T=' gYw '
    local SPACER=""
    local HEADER="40m  100m 41m  101m 42m  102m 43m  103m 44m  104m 45m  105m 46m  106m 47m  107m"
    printf "\n           %s\n" "${HEADER}"
    for effect in 0 1 2 4 5 7; do
        for FGs in 'm' '1m' '30m' '90m' '31m' '91m' '32m' '92m' '33m' '93m' \
                       '34m' '94m' '35m' '95m' '36m' '96m' '37m' '97m'; do
            local FG="${effect};${FGs}"
            SPACER="${FG}"
            [[ ${#SPACER} -lt 4 ]] && SPACER="${FG}  "
            [[ ${#SPACER} -lt 5 ]] && SPACER="${FG} "
            printf "%s\e[%s%s" "${SPACER}" "${FG}" "${T}"
            for BG in 40m 100m 41m 101m 42m 102m 43m 103m 44m 104m 45m 105m 46m 106m 47m 107m; do
                printf "\e[%s\e[%s%s\e[0m" "${FG}" "${BG}" "${T}"
            done
            printf "\n"
        done
    done
    printf "           %s\n" "${HEADER}"
}

function list_colors_256 {
    for fgbg in 38 48; do
        for color in {0..256}; do
            printf "\e[%s;5;%sm %s\t\e[0m" "${fgbg}" "${color}" "${color}"
            (( (color + 1) % 10 == 0 )) && printf "\n"
        done
        printf "\n"
    done
}

# ─── Visual helpers ───────────────────────────────────────────────────────────

# flag [message] — prints a wide highlighted banner; uses current date if no arg.
function flag {
    local message
    if [[ -z "$*" ]]; then
        message="[======  $(date +'%A -- %B %e, %Y -- %I:%M%P')  ======]"
    else
        message="[======  $*  ======]"
    fi
    local -i width_head=$(( (COLUMNS - ${#message}) / 2 ))
    local -i width_tail=${width_head}
    (( (width_tail + width_head + ${#message}) > (COLUMNS - 1) )) && (( width_tail-- ))
    printf "%b\n" "\n\n ${InvWhite}$(seq -s ' ' $((COLUMNS - 1)) | sed 's/[0-9]//g')${Color_Off}"
    printf "%b"   " ${InvYellow}$(seq -s ' ' ${width_head} | sed 's/[0-9]//g')"
    printf "%b"   "${InvWhite}${message}"
    printf "%b\n" "${InvYellow}$(seq -s ' ' ${width_tail} | sed 's/[0-9]//g')${Color_Off}"
    printf "%b\n" " ${InvWhite}$(seq -s ' ' $((COLUMNS - 1)) | sed 's/[0-9]//g')${Color_Off}"
}

# center_line text — prints text centered in the terminal
function center_line {
    printf "%s" "$(printf "%s" "$*" | awk -v M="$COLUMNS" \
        '{ printf "%*s%*s", (M+length)/2, $0, (M-length+1)/2+1, "" }')"
}

# boxit text [char] — wraps text in a box made of char (default ▓)
function boxit {
    local t="$1xxxx"
    local c="${2:-▓}"
    printf "%s\n%s %s %s\n%s\n" "${t//?/$c}" "$c" "$1" "$c" "${t//?/$c}"
}

# ─── String utilities ─────────────────────────────────────────────────────────
function rtrim   { local var="$*"; echo -n "${var%"${var##*[![:space:]]}"}"; }
function ltrim   { local var="$*"; echo -n "${var#"${var%%[![:space:]]*}"}"; }
function trim    { local var; var=$(ltrim "$*"); echo -n "$(rtrim "$var")"; }
function toupper { echo "${@}" | tr '[:lower:]' '[:upper:]'; }
function tolower { echo "${@}" | tr '[:upper:]' '[:lower:]'; }

# replace string substring replacement
function replace    { [[ $# -eq 3 ]] && echo "${1/$2/$3}"   || echo "Usage: replace string sub repl"; }
# replaceAll string substring replacement
function replaceAll { [[ $# -eq 3 ]] && echo "${1//$2/$3}"  || echo "Usage: replaceAll string sub repl"; }
# instr string substring — print index of first occurrence
function instr      { [[ $# -eq 2 ]] && expr index "$1" "$2" || echo "Usage: instr string substring"; }

# ─── Navigation ───────────────────────────────────────────────────────────────
function mkcd {
    [[ $# -ne 1 ]] && { echo "Usage: mkcd <dir>"; return 1; }
    mkdir -p "$1" && cd "$1" || return 1
}

function cdls { cd "$@" && ls -ltr; }

# ─── Directory listings ───────────────────────────────────────────────────────
# Note: --group-directories-first and Linux stat syntax are Linux-specific.
function ls_dirs   { \ls "$1" -l 2>/dev/null | grep '^d'                   | awk '{print $9}'; }
function ls_reg    { \ls "$1" -l 2>/dev/null | grep -v '^[ld]\|^total'     | awk '{print $9}'; }
function ls_hid    { \ls "$1" -ld .[^.]* 2>/dev/null | grep -v '^[ld]\|^total' | awk '{print $9}'; }

function ls_groups {
    ls -l --group-directories-first "$@" | grep -v '^total' | awk '{print $9, "Group ->", $4}' | column -t
}
function ls_users {
    ls -l --group-directories-first "$@" | grep -v '^total' | awk '{print $9, "User ->", $3}' | column -t
}
function ls_perms {
    [[ -z "$*" ]] && return
    for file in "$@"; do
        stat -c "%A %a %n" "$file" | awk '{print $3, "->", $1, "("$2")"}'
    done | column -t
}

# ─── Shell reload ─────────────────────────────────────────────────────────────
function reload_bash {
    builtin unalias -a
    builtin unset -f $(builtin declare -F | sed 's/^.*declare[[:blank:]]\+-f[[:blank:]]\+//')
    . "${BASH_CONFIG_HOME}/bash.bashrc"
}

# ─── Prompt helpers ───────────────────────────────────────────────────────────
# error_result — prints last non-zero exit code; used in PS1 / PROMPT_COMMAND
function error_result {
    local last_rc=$?
    [[ $last_rc -ne 0 ]] && printf "%b" "${IWhite}[e${Red}${last_rc}${IWhite}] "
    printf "%b" "${Color_Off}"
}

# ─── Misc utilities ───────────────────────────────────────────────────────────

# tip — show a random man page blurb
function tip {
    local ret=1
    while (( ret != 0 )); do
        whatis "$(ls /bin/ -p1 2>/dev/null | grep -v '^l' | grep -v '/' | shuf -n 1)" 2>/dev/null
        ret=$?
    done
}

# errno [number] — look up errno names; lists all if no arg given
function errno {
    [[ $# -eq 1 ]] && local re="$1([^0-9]|$)"
    echo "#include <errno.h>" |
        cpp -dD -CC |
        grep -E "^#define E[^ ]+ ${re}" |
        sed ':s;s#/\*\([^ ]*\) #/*\1_#;t s;' | column -t | tr _ ' ' |
        cut -c1-$(tput cols)
}

# to_roman number — convert integer to Roman numerals
function to_roman {
    echo "$1" | sed -e 's/1...$/M&/;s/2...$/MM&/;s/3...$/MMM&/;s/4...$/MMMM&/
        s/6..$/DC&/;s/7..$/DCC&/;s/8..$/DCCC&/;s/9..$/CM&/
        s/1..$/C&/;s/2..$/CC&/;s/3..$/CCC&/;s/4..$/CD&/;s/5..$/D&/
        s/6.$/LX&/;s/7.$/LXX&/;s/8.$/LXXX&/;s/9.$/XC&/
        s/1.$/X&/;s/2.$/XX&/;s/3.$/XXX&/;s/4.$/XL&/;s/5.$/L&/
        s/1$/I/;s/2$/II/;s/3$/III/;s/4$/IV/;s/5$/V/
        s/6$/VI/;s/7$/VII/;s/8$/VIII/;s/9$/IX/
        s/[0-9]//g'
}

# confirm command [args] — prompt before running a destructive command
function confirm {
    local response
    echo "About to $*..."
    read -r -p "Are you sure? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) "$@" ;;
        *) echo "Cancelled." ;;
    esac
}
