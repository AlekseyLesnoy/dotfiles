#!/usr/bin/env bash
# bootstrap/lib/install-op.sh — Install 1Password CLI on macOS/Linux
# Idempotent: skips if 'op' already in PATH

set -euo pipefail

install_op() {
    if command -v op &>/dev/null; then
        echo "[op] Already installed ($(op --version)). Skipping."
        return 0
    fi

    local os
    os="$(uname -s)"

    case "$os" in
        Darwin)
            echo "[op] Installing 1Password CLI via Homebrew..."
            brew install --cask 1password-cli
            ;;
        Linux)
            echo "[op] Installing 1Password CLI on Linux..."
            local arch
            arch="$(uname -m)"
            case "$arch" in
                x86_64)  arch="amd64" ;;
                aarch64) arch="arm64" ;;
                armv7l)  arch="arm" ;;
                *)
                    echo "[op] ERROR: Unsupported architecture: $arch" >&2
                    return 1
                    ;;
            esac

            # Use the official 1Password apt repository
            curl -sS https://downloads.1password.com/linux/keys/1password.asc \
                | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
                | sudo tee /etc/apt/sources.list.d/1password.list > /dev/null

            sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
            curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
                | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null

            sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
            curl -sS https://downloads.1password.com/linux/keys/1password.asc \
                | sudo gpg --dearmor \
                | sudo tee /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg > /dev/null

            sudo apt update -qq
            sudo apt install -y 1password-cli
            ;;
        *)
            echo "[op] ERROR: Unsupported OS: $os" >&2
            return 1
            ;;
    esac

    if command -v op &>/dev/null; then
        echo "[op] Installed successfully ($(op --version))."
    else
        echo "[op] ERROR: Installation failed — 'op' not found in PATH." >&2
        return 1
    fi
}

install_op
