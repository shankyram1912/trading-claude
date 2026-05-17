#!/bin/bash

cd /data/tools/trading-claude

INTERACTIVE=false
for arg in "$@"; do
  [ "$arg" = "--interactive" ] && INTERACTIVE=true
done

if $INTERACTIVE; then
  exec claude --channels plugin:discord@claude-plugins-official
else
  script -q /dev/null -c "claude --channels plugin:discord@claude-plugins-official"
fi