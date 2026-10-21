#!/bin/sh
# Powerline-style Claude Code status line, Dracula via the terminal's palette.
#
# Claude Code downsamples truecolor to the 256-color cube, which washes the
# colors out, so segments use palette indices: the Ghostty Dracula theme maps
# them to the same colors the tmux bar uses. Orange has no palette slot and the
# tmux pink (#d75faf) sits exactly on the cube, so both use 256-color indices.
#
# Left: model, effort, context, cache countdown. Right: lines changed,
# worktree and git state, 5h limit. The right group is padded out to the
# terminal width (COLUMNS is set by Claude Code) and wraps to a second line
# when there is no room.

input=$(cat)

# One jq call; @sh quoting makes the output safe to eval.
eval "$(printf '%s' "$input" | jq -r '
  "vim_mode=\(.vim.mode // "" | @sh)",
  "model=\(.model.display_name // "Unknown" | @sh)",
  "effort=\(.effort.level // "" | @sh)",
  "used=\(.context_window.used_percentage // "" | @sh)",
  "rl_pct=\(.rate_limits.five_hour.used_percentage // "" | @sh)",
  "rl_reset=\(.rate_limits.five_hour.resets_at // "" | @sh)",
  "cache_present=\(if .prompt_cache then 1 else 0 end)",
  "cache_exp=\(.prompt_cache.expires_at // "" | @sh)",
  "lines_add=\(.cost.total_lines_added // "" | @sh)",
  "lines_del=\(.cost.total_lines_removed // "" | @sh)",
  "worktree=\(.workspace.git_worktree // "" | @sh)",
  "cwd=\(.workspace.current_dir // .cwd // "" | @sh)"
')"

now=$(date +%s)

ESC=$(printf '\033')
ARROW=$(printf '\356\202\260')   # U+E0B0
RARROW=$(printf '\356\202\262')  # U+E0B2

# Background SGR codes (palette indices); text is palette 0 on all of them.
PURPLE=44; GREEN=42; CYAN=46; YELLOW=43; RED=41
PINK="48;5;169"; ORANGE="48;5;215"
TEXT=30

# tofg <bg code> prints the matching foreground code, for arrows.
tofg() {
  case "$1" in
    48\;5\;*) echo "38;5;${1#48;5;}" ;;
    *) echo $(( $1 - 10 )) ;;
  esac
}

line=""; plain=""; prev=""
# seg <bg> <text> [style]: left-pointing group, arrow after the previous one
seg() {
  [ -n "$prev" ] && { line="${line}${ESC}[$(tofg "$prev");${1}m${ARROW}"; plain="${plain}>"; }
  line="${line}${ESC}[${TEXT};${1}m${3} ${2} ${ESC}[22m"
  plain="${plain} ${2} "
  prev="$1"
}
# rseg <bg> <text>: mirrored for the right-hand group
rseg() {
  line="${line}${ESC}[$(tofg "$1")${prev:+;$prev}m${RARROW}"
  line="${line}${ESC}[${TEXT};${1}m ${2} "
  plain="${plain}< ${2} "
  prev="$1"
}
# a left group gets a closing arrow
finish_left() {
  line="${line}${ESC}[0m${ESC}[$(tofg "$prev")m${ARROW}${ESC}[0m"
  plain="${plain}>"
}
finish_right() { line="${line}${ESC}[0m"; }
# visible width: count characters, not bytes
width() { printf '%s' "$plain" | LC_ALL=C.UTF-8 wc -m | tr -d ' '; }

# 10-cell bar: heavy line for used, a half-cell at the edge, thin for the rest
make_bar() {
  filled=$(( $1 * 10 / 100 )); [ "$filled" -gt 10 ] && filled=10
  bar=""; i=0
  while [ $i -lt $filled ]; do bar="${bar}━"; i=$(( i + 1 )); done
  if [ $filled -lt 10 ]; then bar="${bar}╸"; i=$(( i + 1 )); fi
  while [ $i -lt 10 ]; do bar="${bar}┄"; i=$(( i + 1 )); done
  printf '%s' "$bar"
}

# ---- left group ----
# vim mode replaces the built-in "-- INSERT --" row (hideVimModeIndicator)
case "$vim_mode" in
  INSERT) seg "$GREEN" "$vim_mode" "${ESC}[1m" ;;
  NORMAL) seg "$CYAN" "$vim_mode" "${ESC}[1m" ;;
  VISUAL*) seg "$ORANGE" "$vim_mode" "${ESC}[1m" ;;
esac
seg "$PURPLE" "✱ $model" "${ESC}[1m"
[ -n "$effort" ] && seg "$PINK" "✦ $effort"
if [ -n "$used" ]; then
  seg "$GREEN" "◔ $(printf '%.0f' "$used")%"
fi
if [ "$cache_present" = 1 ]; then
  rem=$(( ${cache_exp:-0} - now ))
  if [ "$rem" -gt 0 ]; then
    if [ "$rem" -ge 3600 ]; then
      cache_text="◴ $(( rem / 3600 ))h $(( rem % 3600 / 60 ))m"
    else
      cache_text=$(printf '◴ %d:%02d' $(( rem / 60 )) $(( rem % 60 )))
    fi
  else
    cache_text="◴ cold"
  fi
  seg "$YELLOW" "$cache_text"
fi
finish_left
left="$line"; leftw=$(width)

# ---- right group ----
line=""; plain=""; prev=""
[ -n "$lines_add$lines_del" ] && rseg "$PURPLE" "+${lines_add:-0} -${lines_del:-0}"

# git state: ahead/behind, change counts and a dirty/clean marker, no branch
git_text=""
if [ -n "$cwd" ] && gitout=$(cd "$cwd" 2>/dev/null && git status --porcelain=v2 -b 2>/dev/null) && [ -n "$gitout" ]; then
  set -- $(printf '%s\n' "$gitout" | awk '
    /^# branch.ab/ { a = substr($3, 2); b = substr($4, 2) }
    /^[12] /       { if (substr($2,1,1) != ".") s++; if (substr($2,2,1) != ".") m++ }
    /^\? /         { u++ }
    /^u /          { c++ }
    END { print a+0, b+0, s+0, m+0, u+0, c+0 }')
  ahead=$1; behind=$2; staged=$3; modified=$4; untracked=$5; conflicts=$6
  [ -n "$worktree" ] && git_text="⧉ $worktree"
  sync=""
  [ "$ahead" -gt 0 ] && sync="↑${ahead}"
  [ "$behind" -gt 0 ] && sync="${sync}↓${behind}"
  [ -n "$sync" ] && git_text="${git_text:+$git_text }${sync}"
  counts=""
  [ "$staged" -gt 0 ] && counts="+${staged}"
  [ "$modified" -gt 0 ] && counts="${counts:+$counts }~${modified}"
  [ "$untracked" -gt 0 ] && counts="${counts:+$counts }?${untracked}"
  [ "$conflicts" -gt 0 ] && counts="${counts:+$counts }!${conflicts}"
  if [ -n "$counts" ]; then
    git_text="${git_text:+$git_text }(${counts}) ●"
  else
    git_text="${git_text:+$git_text }✓"
  fi
fi
[ -n "$git_text" ] && rseg "$ORANGE" "$git_text"

# 5h limit on the far right: cyan, yellow from 70%, red from 90%
if [ -n "$rl_pct" ]; then
  rl_pct=$(printf '%.0f' "$rl_pct")
  color="$CYAN"
  [ "$rl_pct" -ge 70 ] && color="$YELLOW"
  [ "$rl_pct" -ge 90 ] && color="$RED"
  rl_text="◱ $(make_bar "$rl_pct") ${rl_pct}%"
  if [ -n "$rl_reset" ]; then
    secs=$(( rl_reset - now ))
    if [ "$secs" -gt 0 ]; then
      h=$(( secs / 3600 )); m=$(( secs % 3600 / 60 ))
      if [ "$h" -gt 0 ]; then rl_text="$rl_text (${h}h ${m}m)"; else rl_text="$rl_text (${m}m)"; fi
    fi
  fi
  rseg "$color" "$rl_text"
fi
finish_right
right="$line"; rightw=$(width)

# ---- output ----
total=$(( ${COLUMNS:-100} - 4 ))
gap=$(( total - leftw - rightw ))
if [ -z "$prev" ]; then
  printf '%s' "$left"
elif [ "$gap" -lt 1 ]; then
  printf '%s\n%s' "$left" "$right"
else
  printf '%s%*s%s' "$left" "$gap" "" "$right"
fi
