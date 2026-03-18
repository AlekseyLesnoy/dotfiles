#!/usr/bin/env bash
# tests/docker/entrypoint-template.sh
# Runs inside Dockerfile.chezmoi-template
# Verifies all chezmoi templates render without errors

set -euo pipefail

REPO_DIR="/repo"
STUB_DIR="${REPO_DIR}/tests/stubs"
CONFIG="${STUB_DIR}/chezmoi-ci.toml"

log()  { echo "[test] $*"; }
fail() { echo "[FAIL] $*" >&2; exit 1; }

# Put stub op binary first on PATH
export PATH="${STUB_DIR}:${PATH}"
export CI=true

cd "$REPO_DIR"

log "Testing chezmoi template rendering (dry-run)..."

chezmoi apply \
    --dry-run \
    --source "${REPO_DIR}/home" \
    --config "$CONFIG" \
    --no-tty \
    --force \
    2>&1 | tee /tmp/chezmoi-dry-run.log

EXIT_CODE="${PIPESTATUS[0]}"

if [[ "$EXIT_CODE" -ne 0 ]]; then
    fail "chezmoi dry-run failed. See /tmp/chezmoi-dry-run.log for details."
fi

# Check for template errors in output
if grep -qi "error\|failed\|undefined" /tmp/chezmoi-dry-run.log; then
    log "Possible errors in output:"
    grep -i "error\|failed\|undefined" /tmp/chezmoi-dry-run.log || true
    fail "Template rendering produced errors."
fi

log "✓ Template rendering PASSED."
