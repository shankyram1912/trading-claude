---
name: portfolio-symbols
description: Exchange-prefixed symbols for all holdings in Shanky's portfolio snapshot
metadata:
  type: reference
---

Source of truth: `/data/tools/trading-claude/sandbox/portfolio_snapshot.yaml`

| Symbol | Exchange Prefix | Notes |
|---|---|---|
| GAIL | BSE:GAIL | Zerodha + other brokers; absolute qty 63,290 |
| NTPC | NSE:NTPC | Zerodha + other brokers; absolute qty 22,625 |
| GOLDBEES | NSE:GOLDBEES | Zerodha only; qty 15,500; avg ₹127.68 |
| SILVERBEES | NSE:SILVERBEES | Zerodha only; qty 6,275; avg ₹238.76 |

Do not double-count quantities — snapshot already reflects totals across all brokers.

Related: [[user-profile]]
