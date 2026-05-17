#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Daily Market Tracker
# Claude reads the portfolio snapshot → determines all symbols to track →
# fetches prices + indicators via TradingView MCP (RSI, MACD,
# Stochastic, Bollinger Bands, Ichimoku, TPO, Technical Ratings, Fib) →
# posts mobile-optimised Discord report.
#
# No hardcoded symbols. Everything driven by the portfolio snapshot.
# Cron: 30 10 * * 1-5  (weekdays 4:00 PM IST / 6:30 PM KL / 10:30 AM UTC)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1505214149498507331/Dcc5LpSyn9pkbyRXTEGsQ3SOyxph0Ac9GaA9LabTGFR8FEB9n78BSYt8Xs6L0Kpv8OQ4"
SNAPSHOT="/data/tools/trading-claude/sandbox/portfolio_snapshot.yaml"

PROMPT="You are generating a daily post-market Discord report for Shanky. Today: $(date '+%d %b %Y').

## Step 1 — Load portfolio
Read $SNAPSHOT. Every symbol in the positions list is to be tracked.
Use total_qty and avg from the snapshot — these are TOTAL cross-broker quantities.
Never use Zerodha-only data. The snapshot is the source of truth.

## Step 2 — Fetch current prices
Use TradingView quote_get for every symbol in the snapshot.
Use the exchange prefix from the snapshot for each symbol (e.g., BSE:GAIL, NSE:NTPC, NSE:GOLDBEES).
quote_get returns last price, prev_close, open, high, low, volume — use these for all price calculations.

## Step 3 — TradingView analysis (for every symbol)
For each symbol in the snapshot:
a. chart_set_symbol using the exchange prefix from the snapshot (BSE:GAIL, NSE:NTPC, NSE:GOLDBEES, NSE:SILVERBEES, BSE:BANKINDIA, BSE:ITC)
b. data_get_study_values → RSI, MACD histogram, Stochastic %K/%D, Bollinger Bands, A/D, volume
c. data_get_pine_tables → Technical Ratings (1D / 1W / 1M)
d. data_get_pine_labels → Auto Fib levels (0%, 0.5, 0.618, 0.786, 1.0)
e. data_get_pine_lines → Ichimoku lines (cloud top/bottom, conversion, base lines)
f. data_get_pine_tables → TPO VAH / POC / VAL (primary). If TPO table is unavailable, fall back to capture_screenshot and read values from the right-side profile.
g. Determine from all indicators whether price is in accumulation or distribution

## Step 4 — Per-symbol calculations
- Live P&L = (live_price - avg) × total_qty
- Express P&L in ₹L (lakhs). 1L = ₹1,00,000
- Daily % change = (live_price - prev_close) / prev_close × 100
- Identify nearest resistance and support using this priority order:
  1. TPO VAH/VAL/POC (highest priority — volume-confirmed levels)
  2. Ichimoku cloud top/bottom (trend structure)
  3. Fib retracement levels (0.5, 0.618, 0.786) as secondary confluence
- Flag any level within 1.5% of current price

## Step 5 — News
Use WebSearch to search '[SYMBOL] India NSE news today' for each symbol. One line summary each.

## Step 6 — Combined P&L and snapshot update
Sum all live P&L values. Express in ₹L or ₹Cr (crores, 1Cr = 100L) as appropriate.
Update $SNAPSHOT with today's last_price, value, pnl, pnl_pct for every symbol and set snapshot_date to today.

## OUTPUT — Discord message ONLY, no preamble, no explanation
Apply the SAME block format to every symbol — no special cases, no hardcoded logic.
Mobile-first: short lines, emojis, ↑↓, 🟢🔴🟡, Discord markdown (**bold** \`code\`).

━━━━━━━━━━━━━━━━━━━━━━
🗓 **[DD Mon YYYY]** | NSE Close
━━━━━━━━━━━━━━━━━━━━━━

[Repeat for EVERY symbol — full block for equities, compact for ETFs:]

**FULL BLOCK** (equities):
[🟢/🔴] **SYMBOL** \`₹price\` [↑/↓ X.XX%]
💸 P&L [🟢+/🔴-₹XL] ([+/-X.X%] on cost)
☁️ Ichimoku · [Above/Below/In] cloud ₹[top]–₹[btm] · [🟢Bullish/🔴Bearish/🟡Neutral]
🕐 TPO · VAH ₹[x] · POC ₹[x] · VAL ₹[x] · [🟢Above/🔴Below POC]
📍 Fib · [nearest level ₹x, X% away] · Next [R/S] ₹[x] ([+/-X.X%])
📊 [1D:signal] [1W:signal] [1M:signal] · RSI [val] · MACD [+/-hist] · Stoch [K/D]
📈 [🟢Accumulating/🔴Distributing/🟡Neutral] · Vol [🟢above/🔴below avg]
📰 [1-line news or Nothing material]

**COMPACT BLOCK** (ETFs):
[🟢/🔴] **SYMBOL** \`₹price\` [↑/↓ X.XX%] · P&L [🟢/🔴₹XL] ([+/-X.X%]) · [TV signal] · [Ichimoku signal]

━━━━━━━━━━━━━━━━━━━━━━
💼 **Combined P&L · [🟢/🔴₹XL/Cr] · ([+/-X.X%])**
⚡ **Action · [No action needed OR: SYMBOL · action · ₹price]**
Action criteria — recommend only if ANY of these are true:
  - Price within 1.5% of a key S/R level AND 1D Technical Rating is Strong Buy or Strong Sell
  - RSI < 35 (oversold) or RSI > 65 (overbought) AND MACD histogram confirms direction
  - Price crossing Ichimoku cloud boundary on the day
  - TPO POC reclaim or breakdown intraday
  Otherwise: No action needed"

# ─── RUN ─────────────────────────────────────────────────────────────────────
echo "[$(date '+%H:%M:%S')] Generating daily market report..."
REPORT=$(CLAUDE_CONFIG_DIR=/data/tools/trading-claude/.claude claude -p "$PROMPT" --mcp-config /data/tools/trading-claude/.claude/mcp.json 2>/dev/null)

if [[ -z "$REPORT" ]]; then
    echo "ERROR: claude returned empty output" >&2
    exit 1
fi

echo "$REPORT"

# ─── POST TO DISCORD ─────────────────────────────────────────────────────────
# Commented out for manual review — uncomment once output is verified
# python3 - << PYEOF
# import json, urllib.request
#
# report = """$REPORT"""
# webhook = "$DISCORD_WEBHOOK"
#
# for chunk in [report[i:i+1999] for i in range(0, len(report), 1999)]:
#     req = urllib.request.Request(
#         webhook,
#         data=json.dumps({"content": chunk}).encode(),
#         headers={"Content-Type": "application/json"},
#         method="POST",
#     )
#     urllib.request.urlopen(req, timeout=10)
#
# print("[$(date '+%H:%M:%S')] ✅ Posted to Discord")
# PYEOF
