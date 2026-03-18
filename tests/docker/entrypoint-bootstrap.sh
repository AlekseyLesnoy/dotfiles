#!/usr/bin/env bash
# tests/docker/entrypoint-bootstrap.sh
# Runs inside Dockerfile.ubuntu-bootstrap
# Executes bootstrap twice and diffs the filesystem

set -euo pipefail

REPO_DIR="/repo"
SNAPSHOT_DIR="/tmp/snapshot"

log() { echo "[test] $*"; }
fail() { echo "[FAIL] $*" >&2; exit 1; }

cd "$REPO_DIR"

# ─── Run 1 ────────────────────────────────────────────────────────────────────
log "=== Bootstrap run 1 ==="
bash bootstrap/bootstrap.sh --ci

log "Snapshot filesystem after run 1..."
mkdir -p "$SNAPSHOT_DIR"
# Snapshot home directory state (excluding known volatile paths)
find "$HOME" -type f \
    ! -path "${HOME}/.dotfile-bootstrap-state" \
    ! -path "${HOME}/.local/share/zinit/*" \
    ! -path "${HOME}/.cache/*" \
    | sort > "${SNAPSHOT_DIR}/run1-files.txt"

# ─── Run 2 (idempotency check) ───────────────────────────────────────────────
log "=== Bootstrap run 2 (idempotency check) ==="
bash bootstrap/bootstrap.sh --ci

log "Snapshot filesystem after run 2..."
find "$HOME" -type f \
    ! -path "${HOME}/.dotfile-bootstrap-state" \
    ! -path "${HOME}/.local/share/zinit/*" \
    ! -path "${HOME}/.cache/*" \
    | sort > "${SNAPSHOT_DIR}/run2-files.txt"

# ─── Diff ─────────────────────────────────────────────────────────────────────
log "Comparing run 1 vs run 2..."
if diff -u "${SNAPSHOT_DIR}/run1-files.txt" "${SNAPSHOT_DIR}/run2-files.txt"; then
    log "✓ Idempotency check PASSED — no unexpected filesystem changes."
else
    fail "Idempotency check FAILED — filesystem changed between run 1 and run 2."
fi

log "All bootstrap tests passed."
