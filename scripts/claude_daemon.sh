#!/bin/bash
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

cd /data/tools/trading-claude

echo "HOME=$HOME"
echo "TOKEN=$(cat ~/.claude/channels/discord/.env)"


INTERACTIVE=false
for arg in "$@"; do
  [ "$arg" = "--interactive" ] && INTERACTIVE=true
done

if $INTERACTIVE; then
  exec claude --channels plugin:discord@claude-plugins-official
else
  expect -c "spawn claude --channels plugin:discord@claude-plugins-official; interact"
fi