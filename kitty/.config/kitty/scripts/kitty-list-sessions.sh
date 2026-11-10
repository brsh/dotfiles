#!/usr/bin/env bash

# Filename: ~/github/dotfiles-latest/kitty/scripts/kitty-list-sessions.sh
# Shows open kitty sessions in fzf and switches using goto_session
# Adds a vim-like "mode":
# - Normal mode (default): j/k move, d closes, enter opens, i enters insert mode, esc quits
# - Insert mode: type to filter, enter opens, esc returns to normal mode

set -euo pipefail

default_mode="insert"

set_cursor_block() {
  # DECSCUSR: steady block
  printf '\e[2 q' >/dev/tty
}

set_cursor_bar() {
  # DECSCUSR: steady bar
  printf '\e[6 q' >/dev/tty
}

# Always restore to bar on exit
trap 'set_cursor_bar' EXIT

kitty_bin="/Applications/kitty.app/Contents/MacOS/kitty"
#scripts_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
scripts_dir="$HOME/.config/kitty/scripts"
# Source the Campbell palette for consistent theming
# Requires DOTFILES env var pointing to your dotfiles repo root
campbell_file="${DOTFILES:-}/theme_definition/campbell.sh"
if [[ -n "${DOTFILES:-}" && -f "$campbell_file" ]]; then
  # shellcheck disable=SC1090
  source "$campbell_file"
fi

hex_base="${CAMPBELL_CYAN_BRIGHT:-#61d6d6}"
hex_base="${hex_base#\#}"
base_r=$((16#${hex_base:0:2}))
base_g=$((16#${hex_base:2:2}))
base_b=$((16#${hex_base:4:2}))
base_color="\033[38;2;${base_r};${base_g};${base_b}m"

hex_current="${CAMPBELL_GREEN_BRIGHT:-#16c60c}"
hex_current="${hex_current#\#}"
current_r=$((16#${hex_current:0:2}))
current_g=$((16#${hex_current:2:2}))
current_b=$((16#${hex_current:4:2}))
current_color="\033[38;2;${current_r};${current_g};${current_b}m"

reset_color="\033[0m"

fzf_colors="bg:${CAMPBELL_BLACK:-#0c0c0c},fg:${CAMPBELL_WHITE:-#cccccc}"
fzf_colors+=",hl:${CAMPBELL_CYAN_BRIGHT:-#61d6d6},hl+:${CAMPBELL_CYAN_BRIGHT:-#61d6d6}"
fzf_colors+=",info:${CAMPBELL_GRAY_LT:-#a0a0a0},header:${CAMPBELL_GRAY_LT:-#a0a0a0}"
fzf_colors+=",prompt:${CAMPBELL_BLUE_BRIGHT:-#3b78ff}"
fzf_colors+=",pointer:${CAMPBELL_YELLOW:-#f19c00}"
fzf_colors+=",marker:${CAMPBELL_GREEN_BRIGHT:-#16c60c}"
fzf_colors+=",spinner:${CAMPBELL_GRAY_MID:-#4d4d4d}"
fzf_colors+=",fg+:${CAMPBELL_WHITE_BRIGHT:-#f2f2f2}"
fzf_colors+=",bg+:${CAMPBELL_GRAY_MID:-#4d4d4d}"
fzf_colors+=",gutter:${CAMPBELL_BLACK:-#0c0c0c}"

# Requirements
if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf is not installed or not in PATH."
  echo "Install (brew): brew install fzf"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not installed or not in PATH."
  echo "Install (brew): brew install jq"
  exit 1
fi

if [[ ! -x "$kitty_bin" ]]; then
  echo "kitty binary not found at: $kitty_bin"
  exit 1
fi

sock="$("${scripts_dir}/549-kittyMainSocket.sh" || true)"
if [[ -z "${sock:-}" ]]; then
  echo "No kitty sockets found in /tmp (kitty not running, or remote control not available)."
  exit 1
fi

build_menu_lines() {
  local sessions_tsv=""
  sessions_tsv="$(
    "$kitty_bin" @ --to "unix:${sock}" ls 2>/dev/null | jq -r '
      [
        .[] as $os
        | $os.tabs[] as $tab
        | $tab.windows[]?
        | {
            label: (
              if ((.session_name // "") != "") then .session_name
              elif (.title != null and .title != "" and .title != "~") then .title
              else ((.foreground_processes // [])
                | if length > 0 then (last.cmdline[0] // "?" | split("/") | last | ltrimstr("-"))
                  else "?"
                  end)
              end
            ),
            session_name: (.session_name // ""),
            window_id: .id,
            pwd: (.env.PWD // .cwd),
            os_focused: ($os.is_focused // false),
            tab_focused: ($tab.is_focused // false),
            last_focused_at: (.last_focused_at // 0)
          }
      ]
      # Group by session_name if set, otherwise treat each window individually
      | group_by(if .session_name != "" then .session_name else (.window_id | tostring) end)
      | map({
          session_last_focused_at: (map(.last_focused_at) | max),
          pick: (
            if (map(.os_focused and .tab_focused) | any) then
              (map(select(.os_focused and .tab_focused)) | .[0])
            else
              .[0]
            end
          )
        })
      | map(.pick + {session_last_focused_at: .session_last_focused_at})
      | sort_by(-.session_last_focused_at, .label)
      | .[]
      | select((.os_focused and .tab_focused) | not)
      | [(.label|tostring), (.session_name|tostring), (.window_id|tostring), (.os_focused|tostring), (.tab_focused|tostring), (.pwd|tostring)]
      | @tsv
    '
  )"

  if [[ -z "${sessions_tsv:-}" ]]; then
    return 1
  fi

  # idx<TAB>session_name<TAB>window_id<TAB>pretty_display
  printf "%s\n" "$sessions_tsv" | awk -F'\t' -v home="${HOME}" -v base_color="${base_color}" -v current_color="${current_color}" -v reset_color="${reset_color}" '{
    label=$1
    session_name=$2
    window_id=$3
    os_focused=$4
    tab_focused=$5
    path=$6
    if (home != "" && index(path, home) == 1) {
      path = "~" substr(path, length(home) + 1)
    }
    idx=NR
    if (os_focused == "true" && tab_focused == "true") {
      name_color=current_color
    } else {
      name_color=base_color
    }
    printf "%d\t%s\t%s\t%s%s%s  %s\n", idx, session_name, window_id, name_color, label, reset_color, path
  }'
}

# Set the startup mode
mode="$default_mode"
fzf_start_pos=""

while true; do
  menu_lines="$(build_menu_lines || true)"
  if [[ -z "${menu_lines:-}" ]]; then
    echo "No sessions found."
    exit 1
  fi

  fzf_out=""
  fzf_rc=0

  if [[ "$mode" == "normal" ]]; then
    # Normal mode:
    # - Search disabled (typing doesn't filter)
    # - j/k move
    # - d closes session
    # - enter opens session
    # - i enters insert mode
    # - esc quits
    # - --no-clear avoids a visible screen "flash"
    #   - We exit one fzf instance and immediately start another when switching modes
    #   - Prevents fzf from clearing/restoring the screen on exit
    set_cursor_block
    set +e
    fzf_start_pos_opt=()
    if [[ -n "${fzf_start_pos:-}" && "$fzf_start_pos" -gt 1 ]]; then
      fzf_start_action="down"
      for ((i = 3; i <= fzf_start_pos; i++)); do
        fzf_start_action+="+down"
      done
      # Workaround for older fzf where start:* actions are ignored.
      # Based on https://github.com/junegunn/fzf/issues/4559
      fzf_start_pos_opt=(--bind "result:${fzf_start_action}")
    fi
    fzf_out="$(
      printf "%s\n" "$menu_lines" |
        fzf --ansi --height=100% --reverse \
          --delimiter=$'\t' \
          --header="Normal: j/k move, d close, enter open, i insert, esc quit" \
          --prompt="List Open Kitty Sessions > " \
          --no-multi --disabled \
          --with-nth=4.. \
          --expect=enter,d,i,esc \
          --bind 'j:down,k:up' \
          --bind 'enter:accept,d:accept,i:accept' \
          --bind 'esc:abort' \
          --no-clear \
          --color="$fzf_colors" \
          ${fzf_start_pos_opt[@]+"${fzf_start_pos_opt[@]}"}

    )"
    fzf_rc=$?
    fzf_start_pos=""
    set -e
  else
    # Insert mode:
    # - Search enabled (type to filter)
    # - enter opens session
    # - esc returns to normal mode
    # - --no-clear avoids a visible screen "flash"
    #   - We exit one fzf instance and immediately start another when switching modes
    #   - Prevents fzf from clearing/restoring the screen on exit

    set_cursor_bar
    set +e
    fzf_out="$(
      printf "%s\n" "$menu_lines" |
        fzf --ansi --height=100% --reverse \
          --delimiter=$'\t' \
          --header="Insert: type to filter, enter open, esc normal" \
          --prompt="List Open Kitty Sessions > " \
          --no-multi \
          --with-nth=4.. \
          --expect=enter,esc \
          --bind 'enter:accept' \
          --bind 'esc:abort' \
          --no-clear \
          --color="$fzf_colors"
    )"
    fzf_rc=$?
    set -e
  fi

  # If fzf aborted and gave no output, treat it like "esc"
  if [[ $fzf_rc -ne 0 && -z "${fzf_out:-}" ]]; then
    key="esc"
    sel=""
  else
    key="$(printf "%s\n" "$fzf_out" | head -n1)"
    sel="$(printf "%s\n" "$fzf_out" | sed -n '2p' || true)"
  fi

  # Selection line is: idx<TAB>session_name<TAB>window_id<TAB>pretty_display
  selected_session=""
  selected_window_id=""
  selected_index=""
  if [[ -n "${sel:-}" ]]; then
    selected_index="$(printf "%s" "$sel" | awk -F'\t' '{print $1}')"
    selected_session="$(printf "%s" "$sel" | awk -F'\t' '{print $2}')"
    selected_window_id="$(printf "%s" "$sel" | awk -F'\t' '{print $3}')"
  fi

  if [[ "$mode" == "insert" && "$key" == "esc" ]]; then
    mode="normal"
    continue
  fi

  if [[ "$mode" == "normal" && "$key" == "esc" ]]; then
    exit 0
  fi

  if [[ "$mode" == "normal" && "$key" == "i" ]]; then
    mode="insert"
    continue
  fi

  if [[ -z "${selected_session:-}" && -z "${selected_window_id:-}" ]]; then
    # Nothing selected (likely esc)
    if [[ "$mode" == "normal" ]]; then
      exit 0
    fi
    mode="normal"
    continue
  fi

  if [[ "$mode" == "normal" && "$key" == "d" ]]; then
    if [[ "${selected_index:-}" =~ ^[0-9]+$ ]]; then
      total_lines="$(printf "%s\n" "$menu_lines" | awk 'END{print NR}')"
      if [[ -n "${total_lines:-}" && "$selected_index" -ge "$total_lines" ]]; then
        fzf_start_pos=$((selected_index - 1))
      else
        fzf_start_pos=$selected_index
      fi
      if [[ "$fzf_start_pos" -lt 1 ]]; then
        fzf_start_pos=1
      fi
    fi
    if [[ -n "${selected_session:-}" ]]; then
      "$kitty_bin" @ --to "unix:${sock}" action close_session "$selected_session" >/dev/null 2>&1 || true
    else
      "$kitty_bin" @ --to "unix:${sock}" close-window --match "id:${selected_window_id}" >/dev/null 2>&1 || true
    fi
    continue
  fi

  if [[ "$key" == "enter" ]]; then
    if [[ -n "${selected_session:-}" ]]; then
      "$kitty_bin" @ --to "unix:${sock}" action goto_session "$selected_session"
    else
      "$kitty_bin" @ --to "unix:${sock}" focus-window --match "id:${selected_window_id}"
    fi
    exit 0
  fi

  # Fallback behavior:
  # - In insert mode, abort returns here -> go back to normal
  # - In normal mode, unknown key -> exit
  if [[ "$mode" == "insert" ]]; then
    mode="normal"
    continue
  fi

  exit 0
done