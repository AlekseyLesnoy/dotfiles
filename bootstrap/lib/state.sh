#!/usr/bin/env bash
# bootstrap/lib/state.sh — State file read/write helpers for Unix bootstrap

STATE_FILE="${HOME}/.dotfile-bootstrap-state"

set_bootstrap_state() {
    local key="$1"
    local value="$2"
    # Create or update key=value in state file
    if [[ -f "$STATE_FILE" ]]; then
        # Remove existing key if present
        grep -v "^${key}=" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
    echo "${key}=${value}" >> "$STATE_FILE"
}

get_bootstrap_state() {
    local key="$1"
    if [[ -f "$STATE_FILE" ]]; then
        grep "^${key}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2- | head -1
    fi
}

clear_bootstrap_state() {
    rm -f "$STATE_FILE"
}

mark_phase_done() {
    local phase="$1"
    set_bootstrap_state "phase_${phase}" "done"
}

is_phase_done() {
    local phase="$1"
    [[ "$(get_bootstrap_state "phase_${phase}")" == "done" ]]
}
