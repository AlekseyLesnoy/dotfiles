#!/usr/bin/env bash
# tests/benchmark/bench-prompt.sh
# Measures zsh startup time and starship prompt render time in two scenarios:
# plain home directory vs. inside a git repository.
#
# Usage: bench-prompt.sh [GIT_DIR] [--profile minimal|al]
#   GIT_DIR    Path to a git repo for the git scenario (default: current dir)
#   --profile  Starship profile to benchmark (default: default)
#
# Output: bench-results-<OS>-<profile>.json in current directory
# Requires: hyperfine, starship, zsh, python3

set -euo pipefail

GIT_DIR="${1:-$PWD}"
PROFILE="minimal"
# parse --profile flag
for arg in "$@"; do
    case $arg in
        --profile=*) PROFILE="${arg#*=}" ;;
        --profile)   shift; PROFILE="$1" ;;
    esac
done

PLAIN_DIR="$HOME"
OS="$(uname -s)"
OUTPUT="bench-results-${OS}-${PROFILE}.json"
STARSHIP_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/starship"

case "$PROFILE" in
    al)      export STARSHIP_CONFIG="$STARSHIP_CONF_DIR/starship-al.toml" ;;
    minimal) unset STARSHIP_CONFIG 2>/dev/null || true ;;
    *)       echo "ERROR: unknown profile '$PROFILE' (use minimal|al)" >&2; exit 1 ;;
esac

log() { echo "[bench] $*" >&2; }

# ─── Dependency checks ────────────────────────────────────────────────────────
for cmd in hyperfine starship zsh python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd not found — install it first" >&2; exit 1
    fi
done

log "Platform:  $OS"
log "Profile:   $PROFILE"
log "Plain dir: $PLAIN_DIR"
log "Git dir:   $GIT_DIR"

# ─── 1. zsh startup time ─────────────────────────────────────────────────────
log "Measuring zsh startup time..."
hyperfine --warmup 3 --runs 20 \
    --export-json /tmp/bench-startup.json \
    'zsh --no-rcs -c exit' 2>/dev/null

# ─── 2. Prompt render — plain dir ────────────────────────────────────────────
log "Measuring prompt render in plain dir..."
STARSHIP_ENV="${STARSHIP_CONFIG:+STARSHIP_CONFIG=$STARSHIP_CONFIG}"
hyperfine --warmup 3 --runs 20 \
    --export-json /tmp/bench-prompt-plain.json \
    --shell zsh \
    "cd ${PLAIN_DIR} && ${STARSHIP_ENV} starship prompt" 2>/dev/null

# ─── 3. Prompt render — git dir ──────────────────────────────────────────────
log "Measuring prompt render in git dir..."
hyperfine --warmup 3 --runs 20 \
    --export-json /tmp/bench-prompt-git.json \
    --shell zsh \
    "cd ${GIT_DIR} && ${STARSHIP_ENV} starship prompt" 2>/dev/null

# ─── 4. starship module timings ──────────────────────────────────────────────
log "Capturing starship module timings..."
(cd "$GIT_DIR" && starship timings 2>/dev/null) > /tmp/bench-timings.txt || true

# ─── 5. Merge and print results ──────────────────────────────────────────────
log "Writing results to $OUTPUT..."

python3 << PYEOF
import json, subprocess, sys

def ms(val): return round(val * 1000, 1)

startup = json.load(open('/tmp/bench-startup.json'))['results'][0]
plain   = json.load(open('/tmp/bench-prompt-plain.json'))['results'][0]
git_    = json.load(open('/tmp/bench-prompt-git.json'))['results'][0]
timings = open('/tmp/bench-timings.txt').read().strip()

zsh_ver  = subprocess.check_output(['zsh', '--version']).decode().split()[1]
star_ver = subprocess.check_output(['starship', '--version']).decode().split()[1]

result = {
    "platform":                  "${OS}",
    "profile":                   "${PROFILE}",
    "shell":                     "zsh",
    "zsh_version":               zsh_ver,
    "starship_version":          star_ver,
    "startup_ms":                ms(startup['mean']),
    "startup_stddev_ms":         ms(startup['stddev']),
    "prompt_plain_ms":           ms(plain['mean']),
    "prompt_plain_stddev_ms":    ms(plain['stddev']),
    "prompt_git_ms":             ms(git_['mean']),
    "prompt_git_stddev_ms":      ms(git_['stddev']),
    "git_overhead_ms":           ms(git_['mean'] - plain['mean']),
    "starship_timings":          timings,
    "thresholds": {
        "startup_excellent_ms":       150,
        "startup_slow_ms":            500,
        "prompt_render_excellent_ms":  10,
        "prompt_render_slow_ms":       50,
    },
}

with open('${OUTPUT}', 'w') as f:
    json.dump(result, f, indent=2)

print()
print('─' * 52)
print(f"  Profile:            ${PROFILE}")
print(f"  zsh startup:        {result['startup_ms']} ms  (±{result['startup_stddev_ms']})")
print(f"  prompt (plain dir): {result['prompt_plain_ms']} ms  (±{result['prompt_plain_stddev_ms']})")
print(f"  prompt (git dir):   {result['prompt_git_ms']} ms  (±{result['prompt_git_stddev_ms']})")
print(f"  git overhead:       {result['git_overhead_ms']} ms")
print('─' * 52)
print(f"  Results written to: ${OUTPUT}")
print('─' * 52)
print()
PYEOF
