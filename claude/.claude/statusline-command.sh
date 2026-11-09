#!/usr/bin/env bash
# Claude Code statusLine command
# Reads JSON from stdin, outputs a single-line status bar

input=$(cat)

# ── Extract fields ────────────────────────────────────────────────────────────
repo_name=$(echo "$input"    | jq -r '.workspace.repo.name // empty')
model=$(echo "$input"        | jq -r '.model.display_name // empty')
effort=$(echo "$input"       | jq -r '.effort.level // empty')
thinking=$(echo "$input"     | jq -r '.thinking.enabled // empty')
used_pct=$(echo "$input"     | jq -r '.context_window.used_percentage // empty')
input_tok=$(echo "$input"    | jq -r '.context_window.total_input_tokens // empty')
output_tok=$(echo "$input"   | jq -r '.context_window.total_output_tokens // empty')
ctx_size=$(echo "$input"     | jq -r '.context_window.context_window_size // empty')
cost_usd=$(echo "$input"     | jq -r '.cost.total_cost_usd // empty')
api_ms=$(echo "$input"       | jq -r '.cost.total_api_duration_ms // empty')
rl_5h=$(echo "$input"        | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(echo "$input"        | jq -r '.rate_limits.seven_day.used_percentage // empty')
cwd=$(echo "$input"          | jq -r '.workspace.current_dir // empty')

# ── Git context (branch + worktree) ──────────────────────────────────────────
branch=""
worktree=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  # Linked worktrees have their git-dir under .git/worktrees/<name>
  git_dir=$(git -C "$cwd" --no-optional-locks rev-parse --git-dir 2>/dev/null)
  if [[ "$git_dir" == */.git/worktrees/* ]]; then
    worktree=$(basename "$git_dir")
  fi
fi

# ── ANSI helpers ──────────────────────────────────────────────────────────────
rgb()       { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
bold()      { printf '\033[1m'; }
reset()     { printf '\033[0m'; }
dim()       { printf '\033[2m'; }

# ── Campbell palette (pre-computed ANSI sequences) ───────────────────────────
C_GREEN_BRIGHT=$(rgb 22 198 12)        # #16c60c — success, insertions
C_YELLOW=$(rgb 241 156 0)             # #f19c00 — repo name, bar midpoint
C_RED_BRIGHT=$(rgb 231 72 86)         # #e74856 — errors, deletions, bar end
C_ORANGE=$(rgb 232 121 12)            # #e8790c — context warning
C_CYAN_BRIGHT=$(rgb 97 214 214)       # #61d6d6 — branch
C_MAGENTA_TINT=$(rgb 208 78 204)      # #d04ecc — model name
C_GRAY_LT=$(rgb 160 160 160)          # #a0a0a0 — rate limit labels
C_SLATE=$(rgb 105 135 201)            # #6987c9 — API duration
C_BLUE_TINT=$(rgb 125 166 255)        # #7da6ff — token counts
C_AMBER=$(rgb 230 161 23)            # #e6a117 — session cost
C_BLACK_BRIGHT=$(rgb 118 118 118)     # #767676 — dim separators
C_GRAY_MID=$(rgb 77 77 77)            # #4d4d4d — empty bar blocks

GRAY_PIPE="$(dim)${C_BLACK_BRIGHT}|$(reset)"

# ── Repo name (bold yellow) ───────────────────────────────────────────────────
repo_part=""
if [ -n "$repo_name" ]; then
  repo_part="$(bold)${C_YELLOW}${repo_name}$(reset)"
fi

# ── Worktree (tree + cyan — shown only in linked worktrees) ──────────────────
worktree_part=""
if [ -n "$worktree" ]; then
  worktree_part="🌳$(bold)${C_CYAN_BRIGHT}(${worktree})$(reset)"
fi

# ── Branch (leaf + cyan — hidden when redundant with worktree name) ──────────
branch_part=""
if [ -n "$branch" ]; then
  if [ -z "$worktree" ] || [ "$branch" != "$worktree" ]; then
    branch_part="🌿$(bold)${C_CYAN_BRIGHT}(${branch})$(reset)"
  fi
fi

# ── Context bar ───────────────────────────────────────────────────────────────
context_bar_part=""
if [ -n "$used_pct" ]; then
  # Integer percentage
  pct_int=$(printf '%.0f' "$used_pct")
  filled=$(( pct_int * 20 / 100 ))
  [ "$filled" -gt 20 ] && filled=20
  empty=$(( 20 - filled ))

  # Build gradient bar — each filled block gets its own RGB color
  bar=""
  for ((i=1; i<=filled; i++)); do
    pos=$i
    if [ "$pos" -le 10 ]; then
      # green-bright(22,198,12) → yellow(241,156,0)  over positions 1-10
      r=$(( 22  + (241 - 22)  * (pos - 1) / 9 ))
      g=$(( 198 + (156 - 198) * (pos - 1) / 9 ))
      b=$(( 12  + (0   - 12)  * (pos - 1) / 9 ))
    else
      # yellow(241,156,0) → red-bright(231,72,86)  over positions 11-20
      r=$(( 241 + (231 - 241) * (pos - 11) / 9 ))
      g=$(( 156 + (72  - 156) * (pos - 11) / 9 ))
      b=$(( 0   + (86  - 0)   * (pos - 11) / 9 ))
    fi
    bar="${bar}$(rgb $r $g $b)█$(reset)"
  done
  # Empty blocks — CAMPBELL_GRAY_MID
  for ((i=1; i<=empty; i++)); do
    bar="${bar}${C_GRAY_MID}█$(reset)"
  done

  # Dynamic emoji + percentage color
  if [ "$pct_int" -lt 20 ]; then
    emoji="🟢"
    pct_color="${C_GREEN_BRIGHT}"
  elif [ "$pct_int" -lt 70 ]; then
    emoji="⚡"
    pct_color="${C_YELLOW}"
  elif [ "$pct_int" -lt 90 ]; then
    emoji="🔥"
    pct_color="${C_ORANGE}"
  else
    emoji="🚨"
    pct_color="${C_RED_BRIGHT}"
  fi

  context_bar_part="${bar}${emoji}${pct_color}${pct_int}%$(reset)"
fi

# ── Code velocity (git diff --shortstat) ─────────────────────────────────────
velocity_part=""
if [ -n "$cwd" ]; then
  diffstat=$(git -C "$cwd" --no-optional-locks diff --shortstat HEAD 2>/dev/null)
  if [ -n "$diffstat" ]; then
    ins=$(echo "$diffstat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
    del=$(echo "$diffstat" | grep -oE '[0-9]+ deletion'  | grep -oE '[0-9]+')
    ins=${ins:-0}
    del=${del:-0}
    velocity_part="${C_GREEN_BRIGHT}+${ins}$(reset) ${C_RED_BRIGHT}-${del}$(reset)"
  fi
fi

# ── Token count (used / window size) ──────────────────────────────────────────
fmt_tokens() {
  local t=$1
  if [ "$t" -ge 1000000 ]; then
    local whole=$(( t / 1000000 ))
    local frac=$(( (t % 1000000) / 100000 ))
    if [ "$frac" -gt 0 ]; then
      printf '%s.%sm' "$whole" "$frac"
    else
      printf '%sm' "$whole"
    fi
  elif [ "$t" -ge 1000 ]; then
    printf '%sk' "$(( t / 1000 ))"
  else
    printf '%s' "$t"
  fi
}

token_part=""
if [ -n "$input_tok" ] && [ -n "$ctx_size" ]; then
  used_tok=$(( input_tok + ${output_tok:-0} ))
  token_part="📊${C_BLUE_TINT}$(fmt_tokens "$used_tok")$(dim)/$(reset)${C_BLUE_TINT}$(fmt_tokens "$ctx_size")$(reset)"
fi

# ── Session cost (USD) ───────────────────────────────────────────────────────
cost_part=""
if [ -n "$cost_usd" ]; then
  cost_fmt=$(printf '$%.2f' "$cost_usd")
  cost_part="💰${C_AMBER}${cost_fmt}$(reset)"
fi

# ── API duration ──────────────────────────────────────────────────────────────
duration_part=""
if [ -n "$api_ms" ]; then
  total_s=$(( api_ms / 1000 ))
  if [ "$total_s" -ge 3600 ]; then
    dur_fmt="$(( total_s / 3600 ))h$(( (total_s % 3600) / 60 ))m"
  elif [ "$total_s" -ge 60 ]; then
    dur_fmt="$(( total_s / 60 ))m$(( total_s % 60 ))s"
  else
    dur_fmt="${total_s}s"
  fi
  duration_part="⏱${C_SLATE}${dur_fmt}$(reset)"
fi

# ── Rate limits (Pro/Max — color-coded by usage) ─────────────────────────────
rl_color() {
  local pct=$1
  if [ "$pct" -lt 50 ]; then
    printf '%s' "${C_GREEN_BRIGHT}"
  elif [ "$pct" -lt 75 ]; then
    printf '%s' "${C_YELLOW}"
  elif [ "$pct" -lt 90 ]; then
    printf '%s' "${C_ORANGE}"
  else
    printf '%s' "${C_RED_BRIGHT}"
  fi
}

rate_limit_part=""
if [ -n "$rl_5h" ] || [ -n "$rl_7d" ]; then
  rl_segs=""
  if [ -n "$rl_5h" ]; then
    rl_5h_int=$(printf '%.0f' "$rl_5h")
    rl_segs="${C_GRAY_LT}5h$(reset)$(rl_color "$rl_5h_int")${rl_5h_int}%$(reset)"
  fi
  if [ -n "$rl_7d" ]; then
    rl_7d_int=$(printf '%.0f' "$rl_7d")
    if [ -n "$rl_segs" ]; then
      rl_segs="${rl_segs} ${C_GRAY_LT}7d$(reset)$(rl_color "$rl_7d_int")${rl_7d_int}%$(reset)"
    else
      rl_segs="${C_GRAY_LT}7d$(reset)$(rl_color "$rl_7d_int")${rl_7d_int}%$(reset)"
    fi
  fi
  rate_limit_part="🚦${rl_segs}"
fi

# ── Model + effort + thinking (robot + magenta) ──────────────────────────────
model_part=""
if [ -n "$model" ]; then
  model_detail="${model}"
  # Append effort level if present
  if [ -n "$effort" ]; then
    model_detail="${model_detail} (${effort})"
  fi
  # Append thinking indicator
  if [ "$thinking" = "true" ]; then
    model_detail="${model_detail} 🧠"
  fi
  model_part="🤖${C_MAGENTA_TINT}${model_detail}$(reset)"
fi

# ── Assemble line ─────────────────────────────────────────────────────────────
line=""
add_seg() {
  local seg="$1"
  if [ -n "$seg" ]; then
    if [ -n "$line" ]; then
      line="${line} ${GRAY_PIPE} ${seg}"
    else
      line="${seg}"
    fi
  fi
}

add_seg "$repo_part"
add_seg "$worktree_part"
add_seg "$branch_part"
add_seg "$context_bar_part"
add_seg "$token_part"
add_seg "$cost_part"
add_seg "$duration_part"
add_seg "$velocity_part"
add_seg "$rate_limit_part"
add_seg "$model_part"

printf '%s\n' "$line"
