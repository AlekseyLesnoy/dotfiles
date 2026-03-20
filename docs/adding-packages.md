# Adding Packages <!-- omit in toc -->

This guide explains how to add, update, or remove packages from the dotfiles setup.

## Table of Contents <!-- omit in toc -->
- [Package file locations](#package-file-locations)
- [Adding a package](#adding-a-package)
- [Removing a package (flagged removal)](#removing-a-package-flagged-removal)
- [Profile-specific packages](#profile-specific-packages)
- [Staleness checks](#staleness-checks)

## Package file locations

```
packages/
├── common.yaml   # Installed on every machine
├── gaming.yaml   # Installed when profile = gaming (in addition to common)
└── work.yaml     # Installed when profile = work (in addition to common)
```

[↑ Back to top](#table-of-contents)

---

## Adding a package

### 1. Find the correct package ID

**Homebrew formula:**
```bash
brew search <name>
brew info <name>
```

**Homebrew cask:**
```bash
brew search --cask <name>
brew info --cask <name>
```

**apt (Ubuntu/Debian):**
```bash
apt-cache search <name>
apt-cache show <name>
```

**winget (Windows):**
```powershell
winget search <name>
winget show --id <exact-id> --exact
```

### 2. Add to the appropriate YAML file

Edit `packages/common.yaml`, `packages/gaming.yaml`, or `packages/work.yaml`.

**Example — adding `ripgrep` to common:**
```yaml
brew:
  formulae:
    - ripgrep    # ← add here

apt:
  packages:
    - ripgrep    # ← add here (same name on Ubuntu)

winget:
  packages:
    - id: BurntSushi.ripgrep.MSVC   # ← add here (exact winget ID)
```

### 3. Apply the change

The `run_onchange_20-install-packages` scripts embed a SHA hash of the YAML files.
When the YAML changes, chezmoi detects the hash change and re-runs the install script automatically:

```bash
chezmoi apply
```

Or to preview first:
```bash
chezmoi diff
```

[↑ Back to top](#table-of-contents)

---

## Removing a package (flagged removal)

Packages are **never auto-removed**. Instead, add them to the `remove` list to flag them:

```yaml
winget:
  remove:
    - id: SomeApp.Publisher   # printed in post-apply report
```

The `run_onchange_99-report.sh` script will print these as manual action items after every apply.

To actually remove: uninstall manually, then delete the entry from the `remove` list.

[↑ Back to top](#table-of-contents)

---

## Profile-specific packages

`gaming.yaml` and `work.yaml` are **additive** — they extend `common.yaml`, not replace it.
Both files are applied when the matching profile is active:

```bash
# Switch to gaming profile
chezmoi edit-config   # Edit data.profile = "gaming"
chezmoi apply         # gaming.yaml is now applied in addition to common.yaml
```

[↑ Back to top](#table-of-contents)

---

## Staleness checks

The weekly GitHub Actions workflow (`.github/workflows/staleness.yml`) validates
that all package IDs still resolve. If a package ID changes (e.g. winget publisher
renames a package), the staleness job will file a GitHub Issue with details.

Run manually:
```
GitHub → Actions → Staleness Check → Run workflow
```

[↑ Back to top](#table-of-contents)
