#!/usr/bin/env bash
# .github/scripts/validate-brew-ids.sh
# Validates all Homebrew formula and cask IDs in packages/*.yaml

set -euo pipefail

FAILED=0

for yaml_file in packages/*.yaml; do
    echo ""
    echo "Checking ${yaml_file}..."

    # Formulae
    while IFS= read -r formula; do
        [[ -z "$formula" ]] && continue
        if brew info "$formula" &>/dev/null; then
            echo "  OK formula: $formula"
        else
            echo "  FAIL formula: $formula — not found" >&2
            FAILED=1
        fi
    done < <(yq e '.brew.formulae[]' "$yaml_file" 2>/dev/null || true)

    # Casks
    while IFS= read -r cask; do
        [[ -z "$cask" ]] && continue
        if brew info --cask "$cask" &>/dev/null; then
            echo "  OK cask: $cask"
        else
            echo "  FAIL cask: $cask — not found" >&2
            FAILED=1
        fi
    done < <(yq e '.brew.casks[]' "$yaml_file" 2>/dev/null || true)
done

if [[ "$FAILED" -ne 0 ]]; then
    echo "" >&2
    echo "One or more Homebrew IDs failed validation." >&2
    exit 1
fi

echo ""
echo "All Homebrew IDs validated successfully."
