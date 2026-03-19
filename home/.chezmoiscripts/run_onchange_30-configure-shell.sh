#!/usr/bin/env bash
# home/.chezmoiscripts/run_onchange_30-configure-shell.sh
# chezmoi run_once_ script: configure zsh as default shell and bootstrap zinit

set -euo pipefail

log() { echo "[configure-shell] $*"; }

# ─── Set zsh as default shell ─────────────────────────────────────────────────
ZSH_PATH="$(command -v zsh 2>/dev/null || true)"

if [[ -z "$ZSH_PATH" ]]; then
    log "zsh not found — skipping shell configuration."
    exit 0
fi

if [[ "$SHELL" == "$ZSH_PATH" ]]; then
    log "zsh is already the default shell."
else
    log "Setting zsh as default shell ($ZSH_PATH)..."
    # Add to /etc/shells if needed
    if ! grep -qF "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
        log "Added $ZSH_PATH to /etc/shells."
    fi
    sudo chsh -s "$ZSH_PATH" "$(whoami)"
    log "Default shell changed to zsh. Re-login to take effect."
fi

# ─── Bootstrap zinit ──────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ -d "$ZINIT_HOME" ]]; then
    log "zinit already installed at $ZINIT_HOME."
else
    log "Installing zinit..."
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    log "zinit installed."
fi

# ─── Install starship if not present ──────────────────────────────────────────
if ! command -v starship &>/dev/null; then
    log "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

log "Shell configuration complete."
