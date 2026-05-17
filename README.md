# trading-claude

Claude Code setup for automated trading — Discord integration, market tracker cron, and persistent daemon.

---

## Project structure

```
trading-claude/
├── CLAUDE.md                        # Claude project context (auto-loaded)
├── .claude/
│   ├── settings.json                # permissions, MCP config
│   ├── mcp.json                     # MCP server definitions
│   ├── plugins/
│   │   └── installed_plugins.json   # Discord plugin manifest
│   ├── channels/
│   │   └── discord/
│   │       ├── access.json          # allowlist policy (committed)
│   │       └── .env                 # bot token (gitignored — create locally)
│   ├── rules/                       # trading-specific rules (future)
│   ├── skills/                      # reusable workflows (future)
│   └── agents/                      # subagent personas (future)
├── scripts/
│   ├── claude_daemon.sh             # daemon launcher
│   └── daily_market_tracker.sh     # cron market report
├── systemd/
│   └── claude-daemon.service        # systemd unit file
├── cron/
│   └── cron.config                  # cron job definitions
├── sandbox/
│   └── portfolio_snapshot.yaml      # portfolio config
├── logs/                            # runtime logs (gitignored)
├── .gitignore
└── README.md
```

---

## Prerequisites

- Claude Code installed (`which claude` returns a path)
- Discord bot token (see below)
- MCP servers configured in `.claude/mcp.json`

---

## Fresh machine setup

```bash
# 1. Clone the repo
git clone git@github.com:shankyram1912/trading-claude.git /data/tools/trading-claude
cd /data/tools/trading-claude

# 2. Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# 3. Create Discord .env with bot token (gitignored — see Discord section below)
cat > .claude/channels/discord/.env << 'EOF'
DISCORD_BOT_TOKEN=your_bot_token_here
EOF

# 4. Create logs dir
mkdir -p /data/tools/trading-claude/logs

# 5. Install systemd daemon (see Daemon section below)
# 6. Install cron (see Cron section below)
```

---

## Discord bot token

The Discord plugin requires a bot token stored in `.claude/channels/discord/.env`.
This file is gitignored — you must create it manually on each machine.

```bash
cat > /data/tools/trading-claude/.claude/channels/discord/.env << 'EOF'
DISCORD_BOT_TOKEN=your_bot_token_here
EOF
```

Get your bot token from the [Discord Developer Portal](https://discord.com/developers/applications).

---


## Install Discord plugin

The Discord plugin must be installed on each machine — the cache is not committed to git.

```bash
cd /data/tools/trading-claude
claude plugin install discord
```

Verify it's installed:

```bash
claude plugin list
```

Do this before starting the daemon, otherwise the `--channels` flag will fail.


## Daemon — Claude with Discord

The daemon runs Claude Code persistently with the Discord plugin, restarting automatically on failure.

### Install

```bash
# Copy unit file to systemd
sudo cp /data/tools/trading-claude/systemd/claude-daemon.service /etc/systemd/system/

# Reload systemd and enable on startup
sudo systemctl daemon-reload
sudo systemctl enable claude-daemon

# Start now
sudo systemctl start claude-daemon
```

### Check status

```bash
sudo systemctl status claude-daemon
```

### View logs

```bash
sudo journalctl -u claude-daemon -f
```

### Restart

```bash
sudo systemctl restart claude-daemon
```

### Stop

```bash
sudo systemctl stop claude-daemon
```

### Disable from startup

```bash
sudo systemctl disable claude-daemon
```

---

## Cron — daily market tracker

Runs `daily_market_tracker.sh` at 10:30 AM IST on weekdays (Mon–Fri).

```
30 10 * * 1-5 /data/tools/trading-claude/scripts/daily_market_tracker.sh >> /data/tools/trading-claude/logs/market_tracker.log 2>&1
```

### Install cron

```bash
# Create logs dir if not exists
mkdir -p /data/tools/trading-claude/logs

# Load cron from config
crontab /data/tools/trading-claude/cron/cron.config

# Verify
crontab -l
```

> **Note:** `crontab <file>` replaces your entire crontab.
> If you have existing cron jobs, merge first:
> ```bash
> crontab -l > /tmp/existing-cron
> cat /data/tools/trading-claude/cron/cron.config >> /tmp/existing-cron
> crontab /tmp/existing-cron
> ```

### Check cron logs

```bash
tail -f /data/tools/trading-claude/logs/market_tracker.log
```

### Run manually

```bash
bash /data/tools/trading-claude/scripts/daily_market_tracker.sh
```

---

## Run Claude interactively

```bash
cd /data/tools/trading-claude
claude --channels plugin:discord@claude-plugins-official
```

---

## Backup

All config is in git. To back up current state:

```bash
cd /data/tools/trading-claude
git add .
git commit -m "backup: $(date '+%Y-%m-%d %H:%M')"
git push
```

---

## What is NOT in git

| File | Reason |
|---|---|
| `.claude/channels/discord/.env` | `DISCORD_BOT_TOKEN` — secret |
| `.claude/settings.local.json` | Personal overrides |
| `.claude/projects/` | Session transcripts |
| `.claude/cache/` | Runtime cache |
| `.claude/plugins/cache/` | Plugin binaries |
| `.claude/plugins/plugin-catalog-cache.json` | Plugin catalog cache |
| `sandbox/.venv/` | Python venv |
| `logs/` | Runtime logs |
