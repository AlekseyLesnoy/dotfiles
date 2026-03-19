#!/usr/bin/env bash
# bootstrap/lib/install-chezmoi.sh — Install chezmoi on macOS/Linux
# Idempotent: skips if 'chezmoi' already in PATH

set -euo pipefail

install_chezmoi() {
    if command -v chezmoi &>/dev/null; then
        echo "[chezmoi] Already installed ($(chezmoi --version | head -1)). Skipping."
        return 0
    fi

    echo "[chezmoi] Installing chezmoi..."

    # Install to /usr/local/bin when root (e.g. Docker), ~/.local/bin otherwise
    if [[ "$(id -u)" -eq 0 ]]; then
        local bin_dir="/usr/local/bin"
    else
        local bin_dir="$HOME/.local/bin"
        mkdir -p "$bin_dir"
    fi

    local os
    os="$(uname -s)"

    case "$os" in
        Darwin)
            if command -v brew &>/dev/null; then
                brew install chezmoi
            else
                sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin_dir"
            fi
            ;;
        Linux)
            if command -v brew &>/dev/null; then
                brew install chezmoi
            else
                sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin_dir"
            fi
            ;;
        *)
            echo "[chezmoi] ERROR: Unsupported OS: $os" >&2
            return 1
            ;;
    esac

    # Ensure install dir is on PATH for the rest of this session
    if [[ ":$PATH:" != *":${bin_dir}:"* ]]; then
        export PATH="${bin_dir}:$PATH"
    fi

    if command -v chezmoi &>/dev/null; then
        echo "[chezmoi] Installed successfully ($(chezmoi --version | head -1))."
    else
        echo "[chezmoi] ERROR: Installation failed — 'chezmoi' not found in PATH." >&2
        return 1
    fi
}

install_chezmoi
