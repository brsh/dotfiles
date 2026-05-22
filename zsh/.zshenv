# ~/.zshenv — bootstrap only.
# Sets ZDOTDIR and sources the real .zshenv from it.
# Note: zsh only auto-reads ONE .zshenv at startup (this file, from $HOME).
# $ZDOTDIR/.zshenv is NOT automatically sourced, so we do it explicitly here.
export ZDOTDIR="${HOME}/.config/zsh"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"
