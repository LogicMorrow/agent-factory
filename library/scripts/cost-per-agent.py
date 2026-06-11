#!/usr/bin/env python3
"""
cost-per-agent.py — agregacja kosztów tokenów z activity-log.

Origin:  B2 (2026-05-13).
Adresuje: nie wiemy ile realnie kosztuje fabryka. Agreguje `actual_token_cost`
field z activity-log entries → cost per agent / per dzień / per model.

Usage:
  python3 library/scripts/cost-per-agent.py                       # last 7d
  python3 library/scripts/cost-per-agent.py --since=-30d          # last 30d
  python3 library/scripts/cost-per-agent.py --top=5               # top 5 spenders
  python3 library/scripts/cost-per-agent.py --format=json         # JSON output
  python3 library/scripts/cost-per-agent.py --include-no-cost     # also entries bez actual_token_cost

Output (default text):
  === Token costs last 7d ===
  Agent              | Runs | Input   | Output  | Total   | Model    | Est. USD
  agent-architect    |  12  | 45,200  | 18,400  | 63,600  | opus     | $2.06
  ...
  Total: 178k tokens (~$2.50)
"""
import json
import sys
from datetime import datetime, timezone, timedelta
from collections import defaultdict

LOG_FILE = "knowledge-base/activity-log.jsonl"

# Pricing per million tokens (USD, status 2026-05-13)
PRICING = {
    "opus":   {"input": 15.00, "output": 75.00},
    "claude-opus-4-7": {"input": 15.00, "output": 75.00},
    "sonnet": {"input": 3.00,  "output": 15.00},
    "claude-sonnet-4-6": {"input": 3.00, "output": 15.00},
    "haiku":  {"input": 0.80,  "output": 4.00},
    "claude-haiku-4-5-20251001": {"input": 0.80, "output": 4.00},
}


def parse_args:
    args = {"since": "-7d", "top": 10, "format": "text", "include_no_cost": False}
    for arg in sys.argv[1:]:
        if arg.startswith("--since="):
            args["since"] = arg.split("=")[1]
        elif arg.startswith("--top="):
            args["top"] = int(arg.split("=")[1])
        elif arg.startswith("--format="):
            args["format"] = arg.split("=")[1]
        elif arg == "--include-no-cost":
            args["include_no_cost"] = True
    return args


def parse_since(arg):
    if arg.startswith("-") and arg.endswith("d"):
        days = int(arg[1:-1])
        return datetime.now(timezone.utc) - timedelta(days=days)
    try:
        return datetime.fromisoformat(arg.replace("Z", "+00:00"))
    except:
        return datetime.now(timezone.utc) - timedelta(days=7)


def estimate_cost(input_tokens, output_tokens, model):
    """USD cost estimation."""
    model_norm = model.lower if model else "opus"
    # Find matching pricing
    pricing = None
    for k, v in PRICING.items:
        if k.lower in model_norm or model_norm in k.lower:
            pricing = v
            break
    if not pricing:
        pricing = PRICING["opus"]  # default opus (conservative)

    cost = (input_tokens * pricing["input"] + output_tokens * pricing["output"]) / 1_000_000
    return cost


def aggregate(since):
    """Returns dict: agent_name → {runs, input, output, total, model_breakdown}."""
    stats = defaultdict(lambda: {
        "runs": 0,
        "input": 0,
        "output": 0,
        "total": 0,
        "model_breakdown": defaultdict(int),
        "without_cost": 0
    })

    with open(LOG_FILE) as f:
        for line in f:
            line = line.strip
            if not line:
                continue
            try:
                e = json.loads(line)
            except:
                continue

            ts = e.get("ts", "")
            if "T" not in ts:
                continue
            try:
                dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                if dt < since:
                    continue
            except:
                continue

            actor = e.get("actor", "unknown")
            cost = e.get("actual_token_cost")

            stats[actor]["runs"] += 1

            if cost:
                stats[actor]["input"] += cost.get("input", 0)
                stats[actor]["output"] += cost.get("output", 0)
                stats[actor]["total"] += cost.get("total", 0)
                model = cost.get("model", "unknown")
                stats[actor]["model_breakdown"][model] += cost.get("total", 0)
            else:
                stats[actor]["without_cost"] += 1

    return stats


def format_text(stats, top, include_no_cost, since_str):
    lines = []
    lines.append("")
    lines.append(f"=== Token costs ({since_str}) ===")
    lines.append("")

    # Sort by total tokens DESC
    sorted_agents = sorted(stats.items, key=lambda x: -x[1]["total"])

    if not include_no_cost:
        sorted_agents = [(k, v) for k, v in sorted_agents if v["total"] > 0]

    lines.append(f"{'Agent':<28} | {'Runs':>4} | {'Input':>8} | {'Output':>8} | {'Total':>8} | {'Model(s)':<20} | {'Cost USD':>9}")
    lines.append("-" * 110)

    grand_total = 0
    grand_cost = 0.0

    for actor, s in sorted_agents[:top]:
        models = sorted(s["model_breakdown"].items, key=lambda x: -x[1])
        models_str = ", ".join(f"{m}({t//1000}k)" for m, t in models[:2])
        # Estimate cost (use dominant model)
        dom_model = models[0][0] if models else "opus"
        cost_usd = estimate_cost(s["input"], s["output"], dom_model)

        lines.append(
            f"{actor:<28} | {s['runs']:>4} | {s['input']:>8,} | {s['output']:>8,} | "
            f"{s['total']:>8,} | {models_str:<20} | ${cost_usd:>7.4f}"
        )
        grand_total += s["total"]
        grand_cost += cost_usd

    lines.append("-" * 110)
    lines.append(f"{'TOTAL':<28} | {'':<4} | {'':<8} | {'':<8} | {grand_total:>8,} | {'':<20} | ${grand_cost:>7.4f}")
    lines.append("")

    # Agents without cost data
    no_cost_agents = [(k, v) for k, v in stats.items if v["without_cost"] > 0]
    if no_cost_agents:
        lines.append(f"⚠️  Entries without actual_token_cost:")
        for actor, s in sorted(no_cost_agents, key=lambda x: -x[1]["without_cost"])[:5]:
            lines.append(f"   - {actor}: {s['without_cost']} entries (need emit fix — patrz token-budget-tracking skill)")
        lines.append("")

    return "\n".join(lines)


def format_json(stats, top, since_str):
    sorted_agents = sorted(stats.items, key=lambda x: -x[1]["total"])[:top]
    output = {
        "since": since_str,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "agents": [
            {
                "name": actor,
                "runs": s["runs"],
                "input": s["input"],
                "output": s["output"],
                "total": s["total"],
                "models": dict(s["model_breakdown"]),
                "estimated_cost_usd": round(
                    estimate_cost(s["input"], s["output"], list(s["model_breakdown"].keys)[0] if s["model_breakdown"] else "opus"),
                    4
                ),
                "entries_without_cost": s["without_cost"]
            }
            for actor, s in sorted_agents
        ],
        "totals": {
            "input": sum(s["input"] for _, s in sorted_agents),
            "output": sum(s["output"] for _, s in sorted_agents),
            "total": sum(s["total"] for _, s in sorted_agents),
            "estimated_cost_usd": round(sum(
                estimate_cost(s["input"], s["output"], list(s["model_breakdown"].keys)[0] if s["model_breakdown"] else "opus")
                for _, s in sorted_agents
            ), 4)
        }
    }
    return json.dumps(output, indent=2, ensure_ascii=False)


def main:
    args = parse_args
    since = parse_since(args["since"])
    stats = aggregate(since)

    if args["format"] == "json":
        print(format_json(stats, args["top"], args["since"]))
    else:
        print(format_text(stats, args["top"], args["include_no_cost"], args["since"]))

    # Activity-log entry
    try:
        with open(LOG_FILE, "a") as f:
            entry = {
                "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                "actor": "cost-per-agent",
                "action": "factory_status_run",
                "artifact": "stdout",
                "status": "ok",
                "notes": f"cost analytics {args['since']}, top={args['top']}"
            }
            f.write(json.dumps(entry) + "\n")
    except: pass


if __name__ == "__main__":
    main
