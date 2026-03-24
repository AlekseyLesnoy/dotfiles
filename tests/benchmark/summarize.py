#!/usr/bin/env python3
"""
tests/benchmark/summarize.py

Single result:
  summarize.py <result.json> [--no-regression] [baseline.json]

Side-by-side comparison (two profiles):
  summarize.py --compare <result1.json> <result2.json> [--no-regression]

Prints a markdown summary to stdout.
Exits 1 if a regression is detected (unless --no-regression).

A regression is:
  - Any key metric crosses the absolute 'slow' threshold, OR
  - Any key metric is >= 50% worse than the stored baseline.
"""
import json, re, sys
from pathlib import Path

# Ensure UTF-8 output (Windows defaults to cp1252)
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ANSI_ESCAPE   = re.compile(r"\x1b\[[0-9;]*m")
REGRESSION_PCT = 50


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def icon(val, excellent, slow):
    if val <= excellent: return "✅"
    if val >= slow:      return "🔴"
    return "⚠️"


def delta_str(current, b_val):
    if not b_val:
        return ""
    pct  = (current - b_val) / b_val * 100
    sign = "+" if pct >= 0 else ""
    return f" ({sign}{pct:.0f}%)"


def thresholds(result):
    thr = result.get("thresholds", {})
    return (
        thr.get("startup_excellent_ms",       150),
        thr.get("startup_slow_ms",            500),
        thr.get("prompt_render_excellent_ms",  10),
        thr.get("prompt_render_slow_ms",       50),
    )


def cell(cur, std, b_val, b_std, exc, slow, show_baseline):
    st  = icon(cur, exc, slow) + delta_str(cur, b_val)
    val = f"{cur} ms ±{std}"
    if show_baseline and b_val:
        val += f" _(b: {b_val} ms)_"
    return val, st


def summarize_single(result, baseline, no_regression):
    exc_startup, slow_startup, exc_prompt, slow_prompt = thresholds(result)
    platform  = result["platform"]
    shell     = result["shell"]
    profile   = result.get("profile", "?")
    shell_ver = result.get("pwsh_version" if shell == "pwsh" else "zsh_version", "?")
    star_ver  = result.get("starship_version", "?")

    def b(key): return baseline.get(key, 0) if baseline else 0

    rows = []
    def row(label, cur, std, b_key, b_std_key, exc, slow):
        v, s = cell(cur, std, b(b_key), b(b_std_key), exc, slow, baseline is not None)
        rows.append((label, v, s))
        return cur

    startup_ms = result.get("startup_ms", 0)
    row("Startup (w/ profile)", startup_ms, result.get("startup_stddev_ms", 0),
        "startup_ms", "startup_stddev_ms", exc_startup, slow_startup)

    if "startup_noprofile_ms" in result:
        row("Startup (no profile)", result["startup_noprofile_ms"],
            result.get("startup_noprofile_stddev_ms", 0),
            "startup_noprofile_ms", "startup_noprofile_stddev_ms", exc_startup, slow_startup)

    plain_ms = result.get("prompt_plain_ms", 0)
    row("Prompt — plain dir", plain_ms, result.get("prompt_plain_stddev_ms", 0),
        "prompt_plain_ms", "prompt_plain_stddev_ms", exc_prompt, slow_prompt)

    git_ms = result.get("prompt_git_ms", 0)
    row("Prompt — git dir", git_ms, result.get("prompt_git_stddev_ms", 0),
        "prompt_git_ms", "prompt_git_stddev_ms", exc_prompt, slow_prompt)

    rows.append(("Git overhead", f"{result.get('git_overhead_ms', 0)} ms", "—"))

    lines = [
        f"## {platform.capitalize()} · {profile} profile ({shell} {shell_ver} · starship {star_ver})",
        "",
        "| Metric | Value | Status |",
        "|--------|------:|--------|",
        *[f"| {n} | {v} | {s} |" for n, v, s in rows],
    ]

    timings = ANSI_ESCAPE.sub("", result.get("starship_timings", "")).strip()
    if timings:
        lines += ["", "<details><summary>Starship module timings</summary>", "", "```", timings, "```", "</details>"]

    print("\n".join(lines))

    # regression detection
    regressions = []
    def check(cur, b_key, exc, slow, label):
        b_val = b(b_key)
        if cur >= slow:
            regressions.append(f"{label}: **{cur} ms** exceeds slow threshold ({slow} ms)")
        elif baseline and b_val > 0 and (cur - b_val) / b_val * 100 >= REGRESSION_PCT:
            pct = (cur - b_val) / b_val * 100
            regressions.append(f"{label}: {b_val} ms → **{cur} ms** (+{pct:.0f}%)")

    check(startup_ms, "startup_ms",      exc_startup, slow_startup, "Startup (w/ profile)")
    check(plain_ms,   "prompt_plain_ms", exc_prompt,  slow_prompt,  "Prompt (plain dir)")
    check(git_ms,     "prompt_git_ms",   exc_prompt,  slow_prompt,  "Prompt (git dir)")

    if regressions:
        print("\n### ⚠️ Performance regressions detected")
        for r in regressions:
            print(f"- {r}")
        if not no_regression:
            sys.exit(1)


def summarize_compare(r1, r2, no_regression):
    exc_startup, slow_startup, exc_prompt, slow_prompt = thresholds(r1)
    platform  = r1["platform"]
    shell     = r1["shell"]
    shell_ver = r1.get("pwsh_version" if shell == "pwsh" else "zsh_version", "?")
    star_ver  = r1.get("starship_version", "?")
    p1        = r1.get("profile", "profile1")
    p2        = r2.get("profile", "profile2")

    METRICS = [
        ("Startup (w/ profile)", "startup_ms",          "startup_stddev_ms",          exc_startup, slow_startup),
        ("Startup (no profile)", "startup_noprofile_ms", "startup_noprofile_stddev_ms", exc_startup, slow_startup),
        ("Prompt — plain dir",   "prompt_plain_ms",      "prompt_plain_stddev_ms",      exc_prompt,  slow_prompt),
        ("Prompt — git dir",     "prompt_git_ms",        "prompt_git_stddev_ms",        exc_prompt,  slow_prompt),
        ("Git overhead",         "git_overhead_ms",      None,                          None,        None),
    ]

    rows = []
    for label, key, std_key, exc, slow in METRICS:
        v1 = r1.get(key, 0)
        v2 = r2.get(key, 0)
        s1 = r1.get(std_key, 0) if std_key else None
        s2 = r2.get(std_key, 0) if std_key else None
        if exc is None:
            rows.append((label, f"{v1} ms", f"{v2} ms", "—", "—"))
        else:
            ic1 = icon(v1, exc, slow) + delta_str(v1, v2)
            ic2 = icon(v2, exc, slow) + delta_str(v2, v1)
            rows.append((label, f"{v1} ms ±{s1}", f"{v2} ms ±{s2}", ic1, ic2))

    lines = [
        f"## {platform.capitalize()} comparison ({shell} {shell_ver} · starship {star_ver})",
        "",
        f"| Metric | {p1} | {p2} | {p1} status | {p2} status |",
        "|--------|------:|------:|:-----------:|:-----------:|",
        *[f"| {n} | {c1} | {c2} | {s1} | {s2} |" for n, c1, c2, s1, s2 in rows],
    ]

    # timings for both profiles
    for r, p in ((r1, p1), (r2, p2)):
        timings = ANSI_ESCAPE.sub("", r.get("starship_timings", "")).strip()
        if timings:
            lines += ["", f"<details><summary>Starship module timings — {p}</summary>", "", "```", timings, "```", "</details>"]

    print("\n".join(lines))


# ── Entry point ───────────────────────────────────────────────────────────────
args = sys.argv[1:]
no_regression = "--no-regression" in args
args = [a for a in args if a != "--no-regression"]

if args and args[0] == "--compare":
    r1 = load(args[1])
    r2 = load(args[2])
    summarize_compare(r1, r2, no_regression)
else:
    result       = load(args[0])
    baseline_path = args[1] if len(args) > 1 else None
    baseline     = load(baseline_path) if baseline_path and Path(baseline_path).exists() else None
    summarize_single(result, baseline, no_regression)
