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

- Linux machine with systemd
- Claude Code installed (see below)
- Discord bot created in [Discord Developer Portal](https://discord.com/developers/applications)
- MCP servers configured in `.claude/mcp.json`

---

## Fresh machine setup

```bash
# 1. Clone the repo
git clone git@github.com:shankyram1912/trading-claude.git /data/tools/trading-claude
cd /data/tools/trading-claude

# 2. Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# 3. Create logs dir
mkdir -p /data/tools/trading-claude/logs

# 4. Install Discord plugin (see Discord section below)
# 5. Configure Discord bot token (see Discord section below)
# 6. Install systemd daemon (see Daemon section below)
# 7. Install cron (see Cron section below)
```

---

## Install Discord plugin

Plugins are user-scoped — installed once per machine to `~/.claude/`, not per project.

```bash
# Register the official marketplace (skips if already registered)
claude plugin marketplace add anthropics/claude-plugins-official

# Install Discord plugin (skips if already installed)
claude plugin install discord@claude-plugins-official

# Verify
claude plugin list
```

Do this before starting the daemon, otherwise the `--channels` flag will fail.

---

## Configure Discord bot

The Discord plugin manages the bot token internally — no manual `.env` creation needed.

### Step 1 — start Claude with Discord channel

```bash
cd /data/tools/trading-claude
claude --channels plugin:discord@claude-plugins-official
```

### Step 2 — configure bot token

Inside Claude:

```
/discord:configure <your-bot-token>
```

Get your token from the [Discord Developer Portal](https://discord.com/developers/applications) → your app → Bot → Reset Token.

### Step 3 — pair your account

DM your bot on Discord. The bot replies with a pairing code.

> **Note:** If your bot doesn't respond, make sure Claude Code is running with `--channels` from Step 1. The bot can only reply while the channel is active.

Back in Claude Code, run:

```
/discord:access pair <code>
```

### Step 4 — lock down access

Lock access so only your account can send messages:

```
/discord:access policy allowlist
```

### Step 5 — verify

```
/mcp
```

Should show `Reconnected to plugin:discord:discord`. Bot should appear green in Discord.

### Reconfigure token (if token changes)

```
/discord:configure <new-token>
/reload-plugins
```

---

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
sudo journalctl -u claude-daemon -f --output=cat -n 20
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
| `~/.claude/channels/discord/.env` | Bot token — managed by `/discord:configure` |
| `~/.claude/plugins/` | Plugin binaries — reinstall via `claude plugin install` |
| `.claude/settings.local.json` | Personal overrides |
| `.claude/projects/` | Session transcripts |
| `.claude/cache/` | Runtime cache |
| `sandbox/.venv/` | Python venv |
| `logs/` | Runtime logs |
