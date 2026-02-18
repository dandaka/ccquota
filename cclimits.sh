#!/bin/bash

set -euo pipefail

JSON=false
for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON=true
done

# --- Dependency checks ---

TMUX=$(command -v tmux 2>/dev/null) || {
  echo "Error: tmux not found. Install it with: brew install tmux" >&2
  exit 1
}

CLAUDE=$(command -v claude 2>/dev/null) || {
  echo "Error: claude not found. Install Claude Code from https://claude.ai/code" >&2
  exit 1
}

# --- Setup ---

SESSION="cclimits-$$"
CAPTURE=$(mktemp /tmp/cclimits-XXXXXX.txt)
TIMEOUT=30

cleanup() {
  $TMUX kill-session -t "$SESSION" 2>/dev/null || true
  rm -f "$CAPTURE"
}
trap cleanup EXIT

wait_for() {
  local pattern="$1"
  local elapsed=0
  while ! $TMUX capture-pane -t "$SESSION" -p 2>/dev/null | grep -q "$pattern"; do
    sleep 0.3
    elapsed=$((elapsed + 1))
    if [[ $elapsed -gt $((TIMEOUT * 3)) ]]; then
      echo "Error: timed out waiting for Claude Code to show \"$pattern\"" >&2
      exit 1
    fi
  done
}

# --- Launch Claude ---

$TMUX new-session -d -s "$SESSION" -x 220 -y 50 "$CLAUDE" 2>/dev/null || {
  echo "Error: failed to start tmux session" >&2
  exit 1
}

wait_for "Claude Code"

# Send /usage — Escape dismisses autocomplete, Enter executes
$TMUX send-keys -t "$SESSION" "/usage" ""
sleep 0.5
$TMUX send-keys -t "$SESSION" Escape
sleep 0.3
$TMUX send-keys -t "$SESSION" Enter

wait_for "Current session"

$TMUX capture-pane -t "$SESSION" -p > "$CAPTURE"

# --- Parse output ---

LINES=$(sed 's/\r//g' "$CAPTURE" \
  | grep -A 30 "Current session" \
  | grep -v "Esc to cancel" \
  | sed 's/[█▌▙▛▜▝▘─]//g' \
  | sed 's/^[[:space:]]*//' \
  | sed 's/[[:space:]]\{2,\}\([0-9]\)/\1/g' \
  | grep -v '^\s*$')

if [[ -z "$LINES" ]]; then
  echo "Error: failed to parse usage output" >&2
  exit 1
fi

if $JSON; then
  echo "$LINES" | awk '
    BEGIN { printf "{"; first=1 }
    NR%3==1 {
      label=$0
      gsub(/ /, "_", label)
      gsub(/[^a-zA-Z0-9_]/, "", label)
      key=tolower(label)
    }
    NR%3==2 { pct=$0; gsub(/% used/, "", pct); gsub(/ /, "", pct) }
    NR%3==0 {
      reset=$0
      gsub(/"/, "\\\"", reset)
      if (!first) printf ","
      printf "\"%s\":{\"percent\":%s,\"reset\":\"%s\"}", key, pct, reset
      first=0
    }
    END { printf "}\n" }
  '
else
  echo "$LINES" | awk 'NR%3==0{print; print ""} NR%3!=0{print}'
fi
