# bash_aliases.bash — aliases for interactive bash sessions.
# Relies on $BaseOS and $Distro exported by bash.bashrc.

# ─── Core ─────────────────────────────────────────────────────────────────────
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias dir='ls -la'
alias df='df -h'
alias cls=clear
alias functions='declare -F | cut -d " " -f3 | grep -v ^_ | sort | less'
alias ducks='find . -maxdepth 1 -mindepth 1 -print0 | xargs -0 -n1 du -ks 2>/dev/null | sort -rn | head -$((LINES - 10)) | cut -f2 | xargs du -hs 2>/dev/null'

# ─── Colorised grep / diff ────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
command -v vdir    &>/dev/null && alias vdir='vdir --color=auto'
command -v colordiff &>/dev/null && alias diff='colordiff'

# ─── Colorised tool wrappers (grc) ────────────────────────────────────────────
if command -v grc &>/dev/null; then
    alias ping='grc ping -c 4'
    alias netstat='grc netstat'
    alias traceroute='grc traceroute'
    alias mount='grc mount'
    alias ps='grc ps'
    alias lsof='grc lsof'
else
    alias ping='ping -c 4'
fi

# ─── OS-specific ──────────────────────────────────────────────────────────────
case "${BaseOS}" in
    Darwin)
        alias ls='\ls -FhGA'
        alias perm='stat -f "%7Op %Sp%t%Su %SHp%t%Sg %SMp%tother %SLp%t%SN%ST"'
        alias start='open -a Finder ./'
        alias flushDNS='dnscacheutil -flushcache'
        alias diff='diff -y'
        export CLICOLOR=1
        export LSCOLORS=GxFxCxDxBxegedabagaced
        ;;
    Linux)
        alias ls='\ls --color=auto --human-readable --group-directories-first --classify'
        alias perm='stat --printf "%a %A %G %U %n\n"'
        command -v gedit &>/dev/null && alias gedit='gedit &'
        ;;
esac

# ─── Non-root user shortcuts ──────────────────────────────────────────────────
if [[ $UID -ne 0 ]]; then
    alias reboot='sudo reboot'
    alias shutdown='confirm sudo shutdown -t 2 now -h'
    alias nanobash="${EDITOR:-nano} \"${BASH_CONFIG_HOME}/bash.bashrc\""

    # ─── Distro-specific ──────────────────────────────────────────────────────
    case "${Distro}" in
        MacOS)
            alias updatedb='sudo /usr/libexec/locate.updatedb'
            ;;
        *buntu*|*Mint*|*ingu*|*etrunne*|*lementar*|*Debia*)
            alias update='sudo apt update && sudo apt upgrade'
            alias dist-upgrade='sudo apt update && sudo apt dist-upgrade'
            alias install='sudo apt install'
            alias autoremove='sudo apt-get autoremove'
            ;;
        *edora*)
            alias update='sudo dnf update'
            alias install='sudo dnf install'
            ;;
        *Cent*|*Hat*|*oror*|*udunt*|*cientifi*)
            alias update='sudo yum upgrade'
            alias install='sudo yum install'
            ;;
        *Arch*|*anjar*|*ntergo*)
            alias shutdown='confirm sudo shutdown now -h'
            alias update='sudo pacman -S archlinux-keyring && sudo pacman -Syu'
            alias install='sudo pacman -S'
            alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
            function reflect_mirrors {
                sudo bash -c 'wget -O /etc/pacman.d/mirrorlist.backup https://www.archlinux.org/mirrorlist/all/ \
                    && cp /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist \
                    && reflector --verbose --country "United States" -l 200 -p http --sort rate \
                       --save /etc/pacman.d/mirrorlist'
            }
            [[ -r /usr/share/doc/pkgfile/command-not-found.bash ]] && \
                . /usr/share/doc/pkgfile/command-not-found.bash
            ;;
        CygWin*)
            alias sudo='echo -e "\nSudo is not available in CygWin. Use sudo-s instead."'
            alias sudo-s='/usr/bin/cygstart --action=runas /usr/bin/mintty -e /usr/bin/bash --login'
            ;;
    esac
fi
