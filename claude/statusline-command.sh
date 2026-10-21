#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
worktree=$(echo "$input" | jq -r '.worktree.name // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
current_dir=$(echo "$input" | jq -r '.worktree.original_cwd // .workspace.project_dir // .workspace.current_dir // .cwd // empty')
rl_5h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | awk '{printf "%.0f", $1}')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -n "$used" ]; then
  used_display=$(printf "%.0f" "$used")
  usage_str="${used_display}%"
else
  usage_str="0%"
fi

if [ -n "$worktree" ]; then
  worktree_str="${worktree}"
else
  worktree_str="no worktree"
fi

# Dracula via the terminal's 16-color palette. Claude Code downsamples
# truecolor to the 256-color cube, which washes the colors out; palette
# indices pass through untouched and the Ghostty Dracula theme supplies them.
# Values are SGR color numbers 0-7 (add 30 for fg, 40 for bg) or 8-15 bright.
BG=0; FG_LIGHT=7; COMMENT=8
PURPLE=4; PINK=5; CYAN=6; GREEN=2; YELLOW=3; RED=1
ORANGE=3   # no orange in the 16-color palette, yellow is closest

# fgc / bgc <index> print the SGR parameter for that palette index
fgc() { [ "$1" -lt 8 ] && echo $(( 30 + $1 )) || echo $(( 90 + $1 - 8 )); }
bgc() { [ "$1" -lt 8 ] && echo $(( 40 + $1 )) || echo $(( 100 + $1 - 8 )); }

ESC=$(printf '\033')
ARROW=$(printf '\356\202\260')   # U+E0B0 powerline
BRANCH=$(printf '\356\202\240')  # U+E0A0 powerline branch

# Claude Code sets COLUMNS to the current terminal width before each run, and
# re-runs the script on refreshInterval, so right alignment follows resizes.
# STATUSLINE_WIDTH is the fallback if COLUMNS is missing.
WIDTH=$(( ${COLUMNS:-${STATUSLINE_WIDTH:-100}} - 6 ))
RARROW=$(printf '\356\202\262')  # U+E0B2 powerline (right-pointing side)

line=""
prev=""
linew=0
# seg <bg> <fg> <text> [visible-width-of-text]
seg() {
  if [ -n "$prev" ]; then
    line="${line}${ESC}[$(fgc "$prev");$(bgc "$1")m${ARROW}"
    linew=$(( linew + 1 ))
  fi
  line="${line}${ESC}[$(fgc "$2");$(bgc "$1")m $3 "
  linew=$(( linew + ${4:-${#3}} + 2 ))
  prev="$1"
}
# rseg is seg mirrored for the right side: the arrow comes first
rseg() {
  line="${line}${ESC}[$(fgc "$1")${prev:+;$(bgc "$prev")}m${RARROW}"
  line="${line}${ESC}[$(fgc "$2");$(bgc "$1")m $3 "
  linew=$(( linew + ${4:-${#3}} + 3 ))
  prev="$1"
}
# end the current left line with a closing arrow; the width includes it
endline() {
  line="${line}${ESC}[0m${ESC}[$(fgc "$prev")m${ARROW}${ESC}[0m"
  linew=$(( linew + 1 ))
}

git_str=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')

  git_str="${BRANCH} ${branch}"
  [ "$staged" -gt 0 ] && git_str="${git_str} +${staged}"
  [ "$modified" -gt 0 ] && git_str="${git_str} ~${modified}"
else
  git_str="no branch"
fi

if [ -n "$total_cost" ]; then
  cost_display=$(awk "BEGIN { printf \"%.2f\", $total_cost }")
  block_str="\$${cost_display}"
else
  block_str="\$0.00"
fi

make_bar() {
  pct="$1"
  width=10
  filled=$(( pct * width / 100 ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do bar="${bar}━"; i=$(( i + 1 )); done
  while [ $i -lt $width ];  do bar="${bar}─"; i=$(( i + 1 )); done
  printf "%s" "$bar"
}

rl_str=""
rl_color="$GREEN"
if [ -n "$rl_5h_pct" ]; then
  if [ "$rl_5h_pct" -ge 90 ]; then rl_color="$RED"
  elif [ "$rl_5h_pct" -ge 70 ]; then rl_color="$YELLOW"
  fi
  reset_time=$(date -r "$rl_5h_reset" "+%-I:%M%p" 2>/dev/null || date -d "@$rl_5h_reset" "+%-I:%M%p" 2>/dev/null)
  rl_str="5h $(make_bar "$rl_5h_pct") ${rl_5h_pct}% resets ${reset_time}"
  # visible width: the 10-character bar plus the ASCII around it
  rl_text="5h  ${rl_5h_pct}% resets ${reset_time}"
  rl_w=$(( ${#rl_text} + 10 ))
fi

repo_root=$(cd "$current_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || echo "$current_dir")
dir_display=$(basename "$repo_root")

# line 1: model and effort on the left; context, cost and rate limit on the right
seg "$PURPLE" "$BG" "$model"
[ -n "$effort" ] && seg "$PINK" "$BG" "effort $effort"
endline
left="$line"; leftw=$linew

line=""; prev=""; linew=0
rseg "$CYAN" "$BG" "ctx $usage_str"
rseg "$GREEN" "$BG" "$block_str"
# the bar is 10 multibyte characters, so give its visible width explicitly
[ -n "$rl_str" ] && rseg "$rl_color" "$BG" "$rl_str" "$rl_w"
line="${line}${ESC}[0m"
right="$line"; rightw=$linew

gap=$(( WIDTH - leftw - rightw ))
[ "$gap" -lt 1 ] && gap=1
printf "%s%*s%s\n" "$left" "$gap" "" "$right"

# line 2: directory, worktree, git
line=""; prev=""; linew=0
seg "$PURPLE" "$BG" "$dir_display"
seg "$COMMENT" "$FG_LIGHT" "$worktree_str"
seg "$ORANGE" "$BG" "$git_str"
endline
printf "%s" "$line"
