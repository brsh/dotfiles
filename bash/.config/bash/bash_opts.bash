# bash_opts.bash — shell options and completion hooks for interactive sessions.

# ─── Shell Options ─────────────────────────────────────────────────────────────
shopt -s checkwinsize           # update LINES/COLUMNS after each command
shopt -s histappend             # append to history file, never overwrite
shopt -s cdspell                # auto-correct minor typos in cd arguments
shopt -s nocaseglob             # case-insensitive filename expansion
shopt -s no_empty_cmd_completion  # don't search PATH on an empty TAB
shopt -s cmdhist                # collapse multi-line commands to one history entry
shopt -s histverify             # let user edit recalled history before executing

# dirspell and autocd require bash 4+; macOS ships bash 3 but Homebrew provides 5.
if (( BASH_VERSINFO[0] >= 4 )); then
    shopt -s dirspell   # auto-correct dir names in tab-completion
    shopt -s autocd     # type a path to cd into it
fi

# ─── Debian chroot label ──────────────────────────────────────────────────────
# Populates debian_chroot so PS1 / mobprompt can display the chroot name.
if [[ -z "${debian_chroot:-}" ]] && [[ -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# ─── command_not_found handler (Ubuntu / Debian) ──────────────────────────────
if [[ -f /etc/lsb_release ]] && [[ -x /usr/lib/command-not-found ]]; then
    function command_not_found_handle {
        /usr/lib/command-not-found -- "$1"
        return $?
    }
fi
