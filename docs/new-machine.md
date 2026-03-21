# Setting Up a New Machine <!-- omit in toc -->

This guide walks through bootstrapping a new machine from scratch.

## Table of Contents <!-- omit in toc -->
- [Prerequisites](#prerequisites)
- [macOS](#macos)
  - [One-liner (recommended)](#one-liner-recommended)
  - [What happens](#what-happens)
  - [After bootstrap](#after-bootstrap)
- [Linux / WSL](#linux--wsl)
  - [One-liner (same as macOS)](#one-liner-same-as-macos)
  - [WSL-specific notes](#wsl-specific-notes)
- [Windows](#windows)
  - [One-liner (run in PowerShell — self-elevates automatically)](#one-liner-run-in-powershell--self-elevates-automatically)
  - [What happens](#what-happens-1)
  - [After bootstrap](#after-bootstrap-1)
- [Profile selection](#profile-selection)
- [Switching profiles later](#switching-profiles-later)
- [Keeping dotfiles up to date](#keeping-dotfiles-up-to-date)
- [Troubleshooting](#troubleshooting)
  - [chezmoi template errors](#chezmoi-template-errors)
  - [1Password auth issues](#1password-auth-issues)
  - [Re-run bootstrap from scratch](#re-run-bootstrap-from-scratch)

## Prerequisites

- An internet connection
- 1Password account with the required secrets (see [secrets.md](secrets.md))
- GitHub access (public repo — no auth needed for initial bootstrap)

[↑ Back to top](#table-of-contents)

---

## macOS

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/bootstrap.sh | bash
```

### What happens

1. Detects macOS, installs Xcode Command Line Tools (prompts once)
2. Installs Homebrew
3. Installs 1Password CLI via `brew install --cask 1password-cli`
4. Prompts to add 1Password account and sign in
5. Installs `yq` (YAML parser)
6. Installs `chezmoi`
7. Runs `chezmoi init --apply https://github.com/AlekseyLesnoy/dotfiles.git`
   - Prompts: **profile** (common/gaming/work), email pulled from 1Password, hostname auto-detected
   - Applies dotfiles, runs package install scripts, applies system settings

### After bootstrap

```bash
exec $SHELL -l   # Pick up new shell config
```

[↑ Back to top](#table-of-contents)

---

## Linux / WSL

### One-liner (same as macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/bootstrap.sh | bash
```

### WSL-specific notes

- Run this inside the WSL Ubuntu terminal (not PowerShell)
- The Windows bootstrap (`bootstrap.ps1`) installs WSL automatically if no distro is found
- After WSL bootstrap, Windows Terminal is configured to open Ubuntu by default

[↑ Back to top](#table-of-contents)

---

## Windows

### One-liner (run in PowerShell — self-elevates automatically)

```powershell
irm https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/bootstrap.ps1 | iex
```

> **Note:** The script works under legacy PowerShell 5.1 — it upgrades to pwsh 7 internally.

### What happens

| Phase | Action                                                                                                      |
|-------|-------------------------------------------------------------------------------------------------------------|
| 1     | Installs PowerShell 7, re-launches under it                                                                 |
| 2     | Self-elevates to Administrator                                                                              |
| 3     | Sets execution policy to RemoteSigned                                                                       |
| 4     | Enables Developer Mode, Windows sudo, telemetry opt-out                                                     |
| 5     | Installs Git via winget                                                                                     |
| 6     | Installs 1Password CLI via winget, prompts for account                                                      |
| 7     | Checks for WSL distro — installs WSL 2 with Ubuntu if none found (requires restart, resumes automatically)  |
| 8     | Installs chezmoi via winget                                                                                 |
| 8.5   | Installs yq (required by package install scripts)                                                           |
| 9     | Runs `chezmoi init --apply` — prompts for profile, pulls email from 1Password                               |

### After bootstrap

Open a new Windows Terminal (installed by chezmoi). The PowerShell 7 profile should be active.

[↑ Back to top](#table-of-contents)

---

## Profile selection

During `chezmoi init`, you will be prompted:

```
Machine profile (common/gaming/work):
```

- `common` — developer baseline, suitable for most machines
- `gaming` — adds Steam, Epic Games Launcher, Discord, etc.
- `work` — adds AWS CLI, kubectl, Slack, Zoom, work git identity

Hostname is auto-detected from the machine name. Email is pulled from 1Password (`op://Personal/github.com/login`).

[↑ Back to top](#table-of-contents)

---

## Switching profiles later

```bash
chezmoi edit-config
# Edit:  profile = "gaming"
chezmoi apply
```

[↑ Back to top](#table-of-contents)

---

## Keeping dotfiles up to date

```bash
chezmoi update    # Pull latest from GitHub and apply
chezmoi diff      # Preview changes before applying
chezmoi apply     # Apply without fetching (local source only)
```

[↑ Back to top](#table-of-contents)

---

## Troubleshooting

### chezmoi template errors

```bash
chezmoi apply --verbose --dry-run
```

### 1Password auth issues

```bash
op account list           # Check accounts
eval $(op signin)         # Re-authenticate (macOS/Linux)
op signin                 # Re-authenticate (Windows)
```

### Re-run bootstrap from scratch

Delete the state file and re-run:

```bash
# macOS/Linux
rm -f ~/.dotfiles-bootstrap-state
bash bootstrap/bootstrap.sh

# Windows
Remove-Item $env:USERPROFILE\.dotfiles-bootstrap-state.ini -Force
pwsh bootstrap/bootstrap.ps1
```

[↑ Back to top](#table-of-contents)
