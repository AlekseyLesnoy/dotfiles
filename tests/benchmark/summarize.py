#!/usr/bin/env python3
"""
tests/benchmark/summarize.py

Usage: summarize.py <result.json> [baseline.json]
Prints a markdown summary to stdout.
Exits 1 if a regression is detected.

A regression is:
  - Any key metric crosses the absolute 'slow' threshold, OR
  - Any key metric is >= 50% worse than the stored baseline.
"""
import json, re, sys
from pathlib import Path

# Ensure UTF-8 output (Windows defaults to cp1252)
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ANSI_ESCAPE = re.compile(r"\x1b\[[0-9;]*m")

REGRESSION_PCT = 50  # percent increase to flag as regression


def icon(val, excellent, slow):
    if val <= excellent: return "✅"
    if val >= slow:      return "🔴"
    return "⚠️"


def delta_str(current, b_val):
    if b_val <= 0:
        return ""
    pct = (current - b_val) / b_val * 100
    sign = "+" if pct >= 0 else ""
    return f" ({sign}{pct:.0f}%)"


result   = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))

# collect remaining args
args = sys.argv[2:]
no_regression = "--no-regression" in args
baseline_path = next((a for a in args if not a.startswith("--")), None)
baseline = json.loads(Path(baseline_path).read_text(encoding="utf-8")) if baseline_path and Path(baseline_path).exists() else None

thr          = result.get("thresholds", {})
exc_startup  = thr.get("startup_excellent_ms",       150)
slow_startup = thr.get("startup_slow_ms",            500)
exc_prompt   = thr.get("prompt_render_excellent_ms",  10)
slow_prompt  = thr.get("prompt_render_slow_ms",       50)

platform  = result["platform"]
shell     = result["shell"]
profile   = result.get("profile", "default")
shell_ver = result.get("pwsh_version" if shell == "pwsh" else "zsh_version", "?")
star_ver  = result.get("starship_version", "?")

def b(key):
    return baseline.get(key, 0) if baseline else 0

rows = []

def row(label, cur, std, b_val, b_std, exc, slow):
    status = icon(cur, exc, slow) + delta_str(cur, b_val)
    val = f"{cur} ms ±{std}"
    if baseline and b_val:
        val += f" _(baseline: {b_val} ms ±{b_std})_"
    rows.append((label, val, status))

startup_ms  = result.get("startup_ms", 0)
startup_std = result.get("startup_stddev_ms", 0)
row("Startup (w/ profile)", startup_ms, startup_std, b("startup_ms"), b("startup_stddev_ms"), exc_startup, slow_startup)

if "startup_noprofile_ms" in result:
    nm  = result["startup_noprofile_ms"]
    nm_std = result.get("startup_noprofile_stddev_ms", 0)
    row("Startup (no profile)", nm, nm_std, b("startup_noprofile_ms"), b("startup_noprofile_stddev_ms"), exc_startup, slow_startup)

plain_ms  = result.get("prompt_plain_ms", 0)
plain_std = result.get("prompt_plain_stddev_ms", 0)
row("Prompt — plain dir", plain_ms, plain_std, b("prompt_plain_ms"), b("prompt_plain_stddev_ms"), exc_prompt, slow_prompt)

git_ms  = result.get("prompt_git_ms", 0)
git_std = result.get("prompt_git_stddev_ms", 0)
row("Prompt — git dir", git_ms, git_std, b("prompt_git_ms"), b("prompt_git_stddev_ms"), exc_prompt, slow_prompt)

rows.append(("Git overhead", f"{result.get('git_overhead_ms', 0)} ms", "—"))

lines = [
    f"## {platform.capitalize()} · {profile} profile ({shell} {shell_ver} · starship {star_ver})",
    "",
    "| Metric | Value | Status |",
    "|--------|------:|--------|",
    *[f"| {name} | {val} | {st} |" for name, val, st in rows],
]

timings = ANSI_ESCAPE.sub("", result.get("starship_timings", "")).strip()
if timings:
    lines += [
        "",
        "<details><summary>Starship module timings</summary>",
        "",
        "```",
        timings,
        "```",
        "</details>",
    ]

print("\n".join(lines))

# ── Regression detection ──────────────────────────────────────────────────────
regressions = []

def check(current, b_val, exc, slow, label):
    if current >= slow:
        regressions.append(f"{label}: **{current} ms** exceeds slow threshold ({slow} ms)")
    elif baseline and b_val > 0 and (current - b_val) / b_val * 100 >= REGRESSION_PCT:
        pct = (current - b_val) / b_val * 100
        regressions.append(f"{label}: {b_val} ms → **{current} ms** (+{pct:.0f}%)")

check(startup_ms, b("startup_ms"),       exc_startup, slow_startup, "Startup (w/ profile)")
check(plain_ms,   b("prompt_plain_ms"),  exc_prompt,  slow_prompt,  "Prompt (plain dir)")
check(git_ms,     b("prompt_git_ms"),    exc_prompt,  slow_prompt,  "Prompt (git dir)")

if regressions:
    print("\n### ⚠️ Performance regressions detected")
    for r in regressions:
        print(f"- {r}")
    if not no_regression:
        sys.exit(1)
