#!/usr/bin/env bash
# .github/scripts/validate-apt-ids.sh
# Validates all apt package names in packages/*.yaml
# Also used by ci.yml validate-yaml job with --dry-run to just check YAML syntax

set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

FAILED=0

# Validate YAML syntax first (always)
echo "Validating YAML syntax..."
for yaml_file in packages/*.yaml; do
    if yq e '.' "$yaml_file" > /dev/null 2>&1; then
        echo "  OK syntax: $yaml_file"
    else
        echo "  FAIL syntax: $yaml_file" >&2
        FAILED=1
    fi

    # Check required top-level keys
    for key in meta brew apt winget; do
        if yq e ".${key}" "$yaml_file" 2>/dev/null | grep -q 'null'; then
            echo "  WARN: $yaml_file missing key: $key" >&2
        fi
    done
done

if [[ "$DRY_RUN" == "true" ]]; then
    if [[ "$FAILED" -ne 0 ]]; then
        exit 1
    fi
    echo "YAML validation complete (dry-run, skipping apt-cache checks)."
    exit 0
fi

# Check apt package availability
echo ""
echo "Updating apt cache..."
sudo apt-get update -qq

for yaml_file in packages/*.yaml; do
    echo ""
    echo "Checking ${yaml_file}..."
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        if apt-cache show "$pkg" &>/dev/null; then
            echo "  OK: $pkg"
        else
            echo "  FAIL: $pkg — not found in apt-cache" >&2
            FAILED=1
        fi
    done < <(yq e '.apt.packages[]' "$yaml_file" 2>/dev/null || true)
done

if [[ "$FAILED" -ne 0 ]]; then
    echo "" >&2
    echo "One or more apt package names failed validation." >&2
    exit 1
fi

echo ""
echo "All apt package names validated successfully."
