# dotfiles

Cross-platform machine setup automation using [chezmoi](https://chezmoi.io), [1Password CLI](https://developer.1password.com/docs/cli/), and platform package managers.

Supports **Windows**, **WSL Ubuntu**, and **macOS** from a single repository.

---

## Quick Start

### macOS / Linux / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/bootstrap.sh | bash
```

### Windows (PowerShell — run as Administrator or let it self-elevate)

```powershell
irm https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/bootstrap.ps1 | iex
```

---

## What Gets Installed

| Component | macOS | Linux/WSL | Windows |
|-----------|-------|-----------|---------|
| Homebrew | ✓ | ✓ | — |
| 1Password CLI | ✓ | ✓ | ✓ (winget) |
| chezmoi | ✓ | ✓ | ✓ (winget) |
| zsh + zinit | ✓ | ✓ | — |
| Starship prompt | ✓ | ✓ | ✓ |
| Neovim + lazy.nvim | ✓ | ✓ | ✓ |
| Git | ✓ | ✓ | ✓ |
| Alacritty | ✓ (cask) | — | — |
| Windows Terminal | — | — | ✓ |
| WSL 2 (Ubuntu) | — | — | ✓ (optional) |

---

## Machine Profiles

Three profiles are available, selected at first run via `chezmoi init` prompt:

| Profile | Description |
|---------|-------------|
| `common` | Developer baseline — all machines |
| `gaming` | Common + gaming tools (Steam, game launchers) |
| `work` | Common + work tools (corp VPN, extra git identity) |

To switch profile after initial setup:
```bash
chezmoi edit-config   # Edit data.profile
chezmoi apply
```

---

## Secrets

All secrets are fetched at apply-time from 1Password via `onepasswordRead`. Nothing secret is stored in the repository. See [docs/secrets.md](docs/secrets.md).

---

## Adding Packages

See [docs/adding-packages.md](docs/adding-packages.md).

---

## Setting Up a New Machine

See [docs/new-machine.md](docs/new-machine.md).

---

## Repository Structure

```
dotfiles/
├── bootstrap/          # Entry-point scripts + install helpers
├── packages/           # YAML package lists (common / gaming / work)
├── scripts/            # chezmoi run_onchange_ scripts
├── home/               # Source state for ~/ (chezmoi-managed dotfiles)
├── windows/            # Windows-specific managed files
├── tests/              # Docker + stub tests
├── .github/            # CI workflows + validation scripts
└── docs/               # Human-readable guides
```

---

## CI Status

![CI](https://github.com/AlekseyLesnoy/dotfiles/actions/workflows/ci.yml/badge.svg)
