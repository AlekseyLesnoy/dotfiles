#!/usr/bin/env bash
# scripts/run_onchange_99-report.sh
# chezmoi run_onchange_ script: post-apply summary + flagged removals

set -euo pipefail

DOTFILES_DIR="{{ .chezmoi.sourceDir }}"
PACKAGES_DIR="${DOTFILES_DIR}/packages"
PROFILE="{{ .chezmoi.data.profile }}"
HOSTNAME_VAL="{{ .chezmoi.data.hostname }}"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║            dotfiles — apply complete                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Profile : ${PROFILE}"
echo "  Host    : ${HOSTNAME_VAL}"
echo "  OS      : $(uname -s) $(uname -m)"
echo "  Shell   : ${SHELL}"
echo ""

# ─── Installed tool versions ──────────────────────────────────────────────────
echo "── Tool versions ─────────────────────────────────────"
for tool in git nvim zsh starship fzf rg fd bat eza chezmoi; do
    if command -v "$tool" &>/dev/null; then
        ver=$("$tool" --version 2>&1 | head -1 | sed 's/^[^0-9]*//')
        printf "  %-12s %s\n" "$tool" "$ver"
    else
        printf "  %-12s %s\n" "$tool" "(not found)"
    fi
done

{{ if .chezmoi.data.is_work }}
echo ""
echo "── Work profile extras ────────────────────────────────"
for tool in aws kubectl helm terraform; do
    if command -v "$tool" &>/dev/null; then
        ver=$("$tool" version --short 2>&1 | head -1 || "$tool" --version 2>&1 | head -1)
        printf "  %-12s %s\n" "$tool" "$ver"
    else
        printf "  %-12s %s\n" "$tool" "(not found)"
    fi
done
{{ end }}

# ─── Flagged removals ────────────────────────────────────────────────────────
if command -v yq &>/dev/null && [[ -f "${PACKAGES_DIR}/common.yaml" ]]; then
    REMOVALS="$(yq e '.winget.remove[].id' "${PACKAGES_DIR}/common.yaml" 2>/dev/null || true)"
    if [[ -n "$REMOVALS" ]]; then
        echo ""
        echo "── Packages flagged for manual removal ────────────────"
        echo "   These are NOT auto-removed. Remove manually if desired:"
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            echo "   - $pkg"
        done <<< "$REMOVALS"
    fi
fi

echo ""
echo "  Run 'chezmoi update' to pull latest changes."
echo "  Run 'chezmoi diff'   to preview changes."
echo ""
