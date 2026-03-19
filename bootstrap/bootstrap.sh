#!/usr/bin/env bash
# bootstrap/bootstrap.sh — Entry point for macOS / Linux / WSL
#
# Remote one-liner:
#   curl -fsSL https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/bootstrap.sh | bash
#
# Flags:
#   --ci          Skip interactive prompts (for CI/Docker)
#   --dry-run     Print steps without executing (syntax check)

set -euo pipefail

# ─── Script location ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
DOTFILES_REPO="https://github.com/AlekseyLesnoy/dotfiles.git"

# ─── Flags ────────────────────────────────────────────────────────────────────
CI_MODE=false
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --ci)      CI_MODE=true ;;
        --dry-run) DRY_RUN=true ;;
    esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────
log()  { echo "[bootstrap] $*"; }
step() { echo; echo "═══ $* ═══"; }
run()  {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

# Source state helpers (if running from cloned repo; skip when piped)
if [[ -f "${LIB_DIR}/state.sh" ]]; then
    # shellcheck source=bootstrap/lib/state.sh
    source "${LIB_DIR}/state.sh"
else
    # Minimal inline fallbacks when bootstrapping from pipe
    STATE_FILE="${HOME}/.dotfiles-bootstrap-state"
    mark_phase_done()  { echo "phase_$1=done" >> "$STATE_FILE"; }
    is_phase_done()    { grep -q "^phase_$1=done" "$STATE_FILE" 2>/dev/null; }
fi

# ─── Platform detection ───────────────────────────────────────────────────────
step "Phase 0: Detect platform"
OS="$(uname -s)"
IS_WSL=false
IS_MACOS=false
IS_LINUX=false

case "$OS" in
    Darwin) IS_MACOS=true ;;
    Linux)
        IS_LINUX=true
        if grep -qi microsoft /proc/version 2>/dev/null; then
            IS_WSL=true
            log "Detected WSL (Windows Subsystem for Linux)"
        fi
        ;;
    *)
        echo "ERROR: Unsupported OS: $OS" >&2
        exit 1
        ;;
esac

log "OS: $OS  |  macOS: $IS_MACOS  |  Linux: $IS_LINUX  |  WSL: $IS_WSL"

# ─── Phase 1: Build tools ─────────────────────────────────────────────────────
step "Phase 1: Install build tools"
if ! is_phase_done "build_tools"; then
    if [[ "$IS_MACOS" == "true" ]]; then
        if ! xcode-select -p &>/dev/null; then
            log "Installing Xcode Command Line Tools..."
            if [[ "$CI_MODE" == "true" ]]; then
                log "[CI] Skipping interactive xcode-select --install"
            else
                run xcode-select --install || true
                log "If a dialog appeared, complete the installation, then re-run this script."
                exit 0
            fi
        else
            log "Xcode CLT already installed."
        fi
    elif [[ "$IS_LINUX" == "true" ]]; then
        log "Installing build-essential..."
        run sudo apt-get update -qq
        run sudo apt-get install -y build-essential curl wget git
    fi
    mark_phase_done "build_tools"
else
    log "Build tools already installed. Skipping."
fi

# ─── Phase 2: Homebrew ────────────────────────────────────────────────────────
step "Phase 2: Install Homebrew"
if ! is_phase_done "homebrew"; then
    if [[ "$IS_MACOS" == "true" ]] || [[ "$IS_LINUX" == "true" ]]; then
        if ! command -v brew &>/dev/null; then
            log "Installing Homebrew..."
            if [[ "$CI_MODE" == "true" ]]; then
                run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" <<< ""
            else
                run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            # Add brew to PATH for this session
            if [[ "$IS_LINUX" == "true" ]]; then
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" || true
            fi
        else
            log "Homebrew already installed ($(brew --version | head -1)). Skipping."
        fi
    fi
    mark_phase_done "homebrew"
else
    log "Homebrew phase already done. Skipping."
fi

# ─── Phase 3: 1Password CLI ───────────────────────────────────────────────────
step "Phase 3: Install 1Password CLI"
if ! is_phase_done "op_install"; then
    if [[ -f "${LIB_DIR}/install-op.sh" ]]; then
        run bash "${LIB_DIR}/install-op.sh"
    else
        # Running from pipe — inline minimal install
        if ! command -v op &>/dev/null; then
            log "Fetching and running install-op.sh from GitHub..."
            run bash <(curl -fsSL "https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/lib/install-op.sh")
        else
            log "op already installed. Skipping."
        fi
    fi
    mark_phase_done "op_install"
else
    log "1Password CLI already installed. Skipping."
fi

# ─── Phase 4: 1Password authentication ───────────────────────────────────────
step "Phase 4: Authenticate 1Password"
if ! is_phase_done "op_auth"; then
    if [[ "$CI_MODE" == "true" ]]; then
        log "[CI] Skipping 1Password authentication."
    elif command -v op &>/dev/null; then
        # Check if any account is already listed
        if ! op account list 2>/dev/null | grep -q .; then
            log "Adding 1Password account (follow prompts)..."
            run op account add
        else
            log "1Password account already configured."
        fi
        log "Signing in to 1Password..."
        eval "$(op signin)" || true
    fi
    mark_phase_done "op_auth"
else
    log "1Password auth already done. Skipping."
fi

# ─── Phase 5: yq ──────────────────────────────────────────────────────────────
step "Phase 5: Install yq"
if ! is_phase_done "yq_install"; then
    if ! command -v yq &>/dev/null; then
        if command -v brew &>/dev/null; then
            run brew install yq
        elif [[ "$IS_LINUX" == "true" ]]; then
            local_arch="$(uname -m)"
            case "$local_arch" in
                x86_64)  yq_arch="amd64" ;;
                aarch64) yq_arch="arm64" ;;
                *)        yq_arch="amd64" ;;
            esac
            YQ_VERSION="$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name"' | cut -d'"' -f4)"
            run sudo wget -qO /usr/local/bin/yq \
                "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${yq_arch}"
            run sudo chmod +x /usr/local/bin/yq
        fi
    else
        log "yq already installed ($(yq --version)). Skipping."
    fi
    mark_phase_done "yq_install"
else
    log "yq already installed. Skipping."
fi

# ─── Phase 6: chezmoi ─────────────────────────────────────────────────────────
step "Phase 6: Install chezmoi"
if ! is_phase_done "chezmoi_install"; then
    if [[ -f "${LIB_DIR}/install-chezmoi.sh" ]]; then
        run bash "${LIB_DIR}/install-chezmoi.sh"
    else
        if ! command -v chezmoi &>/dev/null; then
            log "Fetching and running install-chezmoi.sh from GitHub..."
            run bash <(curl -fsSL "https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/lib/install-chezmoi.sh")
        else
            log "chezmoi already installed. Skipping."
        fi
    fi
    mark_phase_done "chezmoi_install"
else
    log "chezmoi already installed. Skipping."
fi

# Ensure common binary locations are on PATH (unconditional — needed on every run)
for _bindir in "$HOME/.local/bin" "/usr/local/bin" "/usr/bin" "/home/linuxbrew/.linuxbrew/bin"; do
    if [[ -d "$_bindir" ]] && [[ ":$PATH:" != *":$_bindir:"* ]]; then
        export PATH="$_bindir:$PATH"
    fi
done
unset _bindir

# ─── Phase 7: chezmoi init + apply ───────────────────────────────────────────
step "Phase 7: chezmoi init --apply"

# Locate chezmoi — search common install locations in case PATH is minimal (e.g. Docker root)
CHEZMOI_BIN=""
for _candidate in \
    "${HOME}/.local/bin/chezmoi" \
    "/usr/local/bin/chezmoi" \
    "/usr/bin/chezmoi" \
    "/home/linuxbrew/.linuxbrew/bin/chezmoi" \
    "$(command -v chezmoi 2>/dev/null || true)"; do
    [[ -z "$_candidate" ]] && continue
    if [[ -x "$_candidate" ]]; then
        CHEZMOI_BIN="$_candidate"
        break
    fi
done
unset _candidate
if [[ -z "$CHEZMOI_BIN" ]]; then
    echo "ERROR: chezmoi not found. Cannot proceed." >&2
    echo "  Searched: ~/.local/bin, /usr/local/bin, /usr/bin, PATH" >&2
    echo "  PATH=$PATH" >&2
    exit 1
fi
log "Using chezmoi at: ${CHEZMOI_BIN}"

if [[ "$DRY_RUN" == "true" ]]; then
    log "[dry-run] Would run: chezmoi init --apply --verbose ${DOTFILES_REPO}"
elif ! is_phase_done "chezmoi_apply"; then
    log "Handing off to chezmoi..."
    run "$CHEZMOI_BIN" init --apply --verbose "$DOTFILES_REPO"
    mark_phase_done "chezmoi_apply"
else
    log "chezmoi already applied. Running update..."
    run "$CHEZMOI_BIN" update --verbose
fi

log ""
log "Bootstrap complete! Open a new shell or run: exec \$SHELL -l"
