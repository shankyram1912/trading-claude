#!/bin/bash
export PATH="$HOME/.bun/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export CLAUDE_CONFIG_DIR=/data/tools/trading-claude/.claude
cd /data/tools/trading-claude

INTERACTIVE=false
SHUTDOWN=false
STATUS=false
ATTACH=false
for arg in "$@"; do
  [ "$arg" = "--interactive" ] && INTERACTIVE=true
  [ "$arg" = "--shutdown" ] && SHUTDOWN=true
  [ "$arg" = "--status" ] && STATUS=true
  [ "$arg" = "--attach" ] && ATTACH=true
done

if $SHUTDOWN; then
  if tmux has-session -t claude-daemon 2>/dev/null; then
    tmux kill-session -t claude-daemon
    echo "Claude daemon stopped."
  else
    echo "Claude daemon is not running."
  fi
  exit 0

elif $STATUS; then
  if tmux has-session -t claude-daemon 2>/dev/null; then
    echo "Claude daemon is running — attach with: bash $0 --attach"
  else
    echo "Claude daemon is not running — start with: bash $0"
  fi
  exit 0

elif $ATTACH; then
  if tmux has-session -t claude-daemon 2>/dev/null; then
    tmux attach-session -t claude-daemon
  else
    echo "Claude daemon is not running — start with: bash $0"
  fi
  exit 0

elif $INTERACTIVE; then
  exec claude --channels plugin:discord@claude-plugins-official

else
  # Only start if not already running
  if tmux has-session -t claude-daemon 2>/dev/null; then
    echo "Claude daemon already running."
    echo "  Status : bash $0 --status"
    echo "  Attach : bash $0 --attach"
    echo "  Stop   : bash $0 --shutdown"
    exit 0
  fi

  tmux new-session -d -s claude-daemon "bash $0 --interactive"
  echo "Claude daemon started in tmux session 'claude-daemon'"
  echo "  Attach : bash $0 --attach"
  echo "  Status : bash $0 --status"
  echo "  Stop   : bash $0 --shutdown"
fi