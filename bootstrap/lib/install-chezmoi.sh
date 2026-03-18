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

    local os
    os="$(uname -s)"

    case "$os" in
        Darwin)
            if command -v brew &>/dev/null; then
                brew install chezmoi
            else
                # Fallback: official install script
                sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
                export PATH="$HOME/.local/bin:$PATH"
            fi
            ;;
        Linux)
            if command -v brew &>/dev/null; then
                brew install chezmoi
            elif command -v apt-get &>/dev/null; then
                # Use official install script to get latest version
                sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
                export PATH="$HOME/.local/bin:$PATH"
            else
                sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
                export PATH="$HOME/.local/bin:$PATH"
            fi
            ;;
        *)
            echo "[chezmoi] ERROR: Unsupported OS: $os" >&2
            return 1
            ;;
    esac

    if command -v chezmoi &>/dev/null; then
        echo "[chezmoi] Installed successfully ($(chezmoi --version | head -1))."
    else
        echo "[chezmoi] ERROR: Installation failed — 'chezmoi' not found in PATH." >&2
        return 1
    fi
}

install_chezmoi
