# Setting Up a New Machine

This guide walks through bootstrapping a new machine from scratch.

## Prerequisites

- An internet connection
- 1Password account with the required secrets (see [secrets.md](secrets.md))
- GitHub access (public repo — no auth needed for initial bootstrap)

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
   - Prompts: **profile** (common/gaming/work), **hostname**, **email**
   - Applies dotfiles, runs package install scripts, applies system settings

### After bootstrap

```bash
exec $SHELL -l   # Pick up new shell config
```

---

## Linux / WSL

### One-liner (same as macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/bootstrap.sh | bash
```

### WSL-specific notes

- Run this inside the WSL Ubuntu terminal (not PowerShell)
- The Windows bootstrap (`bootstrap.ps1`) installs WSL automatically if you choose
- After WSL bootstrap, Windows Terminal is configured to open Ubuntu by default
- `/etc/wsl.conf` is managed by chezmoi (enables systemd, configures automount)

---

## Windows

### One-liner (run in PowerShell — self-elevates automatically)

```powershell
irm https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/bootstrap.ps1 | iex
```

> **Note:** The script works under legacy PowerShell 5.1 — it upgrades to pwsh 7 internally.

### What happens

| Phase | Action |
|-------|--------|
| 1 | Installs PowerShell 7, re-launches under it |
| 2 | Self-elevates to Administrator |
| 3 | Sets execution policy to RemoteSigned |
| 4 | Enables Developer Mode + Windows sudo |
| 5 | Installs Git via winget |
| 6 | Installs 1Password CLI via winget, prompts for account |
| 7 | Optionally installs WSL 2 with Ubuntu (requires restart — resumes automatically) |
| 8 | Installs chezmoi via winget |
| 9 | Runs `chezmoi init --apply` with prompts for profile/hostname/email |

### After bootstrap

Open a new Windows Terminal (installed by chezmoi). The PowerShell 7 profile should be active.

---

## Profile selection

During `chezmoi init`, you will be prompted:

```
Machine profile (common/gaming/work):
```

Choose:
- `common` — developer baseline, suitable for most machines
- `gaming` — adds Steam, Epic Games Launcher, Discord, etc.
- `work` — adds AWS CLI, kubectl, Slack, Zoom, work git identity

---

## Switching profiles later

```bash
chezmoi edit-config
# Edit:  profile = "gaming"
chezmoi apply
```

---

## Keeping dotfiles up to date

```bash
chezmoi update    # Pull latest from GitHub and apply
chezmoi diff      # Preview changes before applying
chezmoi apply     # Apply without fetching (local source only)
```

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
