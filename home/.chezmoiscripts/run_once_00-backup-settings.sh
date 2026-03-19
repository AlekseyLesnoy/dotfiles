#!/usr/bin/env bash
# home/.chezmoiscripts/run_once_00-backup-settings.sh
# chezmoi run_once_ script: back up original macOS/Linux settings before any changes
# Runs exactly once (per machine), before system-settings apply.

set -euo pipefail

log() { echo "[backup-settings] $*"; }

BACKUP_DIR="${HOME}/.dotfiles-backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/settings-backup-${TIMESTAMP}.json"
FILES_BACKUP_DIR="${BACKUP_DIR}/files-${TIMESTAMP}"

mkdir -p "${BACKUP_DIR}" "${FILES_BACKUP_DIR}"
log "Backing up original settings to ${BACKUP_FILE}"

OS="$(uname -s)"

# ─── Back up managed config files ────────────────────────────────────────────
files_to_backup=(
    "${HOME}/.gitconfig"
    "${HOME}/.config/starship.toml"
    "${HOME}/.zshrc"
)

if [[ "$OS" == "Darwin" ]]; then
    files_to_backup+=(
        "${HOME}/Library/Application Support/Code/User/settings.json"
        "${HOME}/.config/alacritty/alacritty.toml"
    )
fi

for file in "${files_to_backup[@]}"; do
    if [[ -f "$file" ]]; then
        dest="${FILES_BACKUP_DIR}/$(echo "${file#"${HOME}/"}" | tr '/' '_')"
        cp "$file" "$dest"
        log "Backed up: $file"
    fi
done

# ─── macOS defaults snapshot ──────────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
    {
        echo "{"
        echo "  \"keyboard\": {"
        echo "    \"KeyRepeat\": $(defaults read NSGlobalDomain KeyRepeat 2>/dev/null || echo null),"
        echo "    \"InitialKeyRepeat\": $(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null || echo null)"
        echo "  },"
        echo "  \"trackpad\": {"
        echo "    \"Clicking\": $(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking 2>/dev/null || echo null)"
        echo "  },"
        echo "  \"finder\": {"
        echo "    \"AppleShowAllExtensions\": $(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null || echo null),"
        echo "    \"ShowHiddenFiles\": $(defaults read com.apple.finder ShowHiddenFiles 2>/dev/null || echo null),"
        echo "    \"ShowPathbar\": $(defaults read com.apple.finder ShowPathbar 2>/dev/null || echo null),"
        echo "    \"ShowStatusBar\": $(defaults read com.apple.finder ShowStatusBar 2>/dev/null || echo null)"
        echo "  },"
        echo "  \"dock\": {"
        echo "    \"autohide\": $(defaults read com.apple.dock autohide 2>/dev/null || echo null),"
        echo "    \"show-recents\": $(defaults read com.apple.dock show-recents 2>/dev/null || echo null),"
        echo "    \"tilesize\": $(defaults read com.apple.dock tilesize 2>/dev/null || echo null)"
        echo "  }"
        echo "}"
    } > "${BACKUP_FILE}"
    log "macOS defaults snapshot saved."
else
    # Linux: save sysctl values
    {
        echo "{"
        echo "  \"sysctl\": {"
        echo "    \"fs.inotify.max_user_watches\": $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo null),"
        echo "    \"fs.inotify.max_user_instances\": $(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo null)"
        echo "  }"
        echo "}"
    } > "${BACKUP_FILE}"
    log "Linux sysctl snapshot saved."
fi

log "Backup complete: ${BACKUP_FILE}"
log "File backups: ${FILES_BACKUP_DIR}"
log "To restore, manually re-apply defaults or copy files back."
