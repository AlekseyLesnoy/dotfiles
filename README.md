# dotfiles <!-- omit in toc -->

[![CI](https://github.com/AlekseyLesnoy/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/AlekseyLesnoy/dotfiles/actions/workflows/ci.yml)

Cross-platform machine setup automation using [chezmoi](https://chezmoi.io), [1Password CLI](https://developer.1password.com/docs/cli/), and platform package managers.

Supports **Windows**, **WSL Ubuntu**, and **macOS** from a single repository.

---
## Table of Contents <!-- omit in toc -->
- [Quick Start](#quick-start)
  - [macOS / Linux / WSL](#macos--linux--wsl)
  - [Windows (PowerShell — run as Administrator or let it self-elevate)](#windows-powershell--run-as-administrator-or-let-it-self-elevate)
- [What Gets Installed](#what-gets-installed)
- [Machine Profiles](#machine-profiles)
  - [Editing managed files](#editing-managed-files)
  - [Machine with local repo clone](#machine-with-local-repo-clone)
  - [Machine without local repo clone](#machine-without-local-repo-clone)
- [Secrets](#secrets)
- [Adding Packages](#adding-packages)
- [Setting Up a New Machine](#setting-up-a-new-machine)
- [Repository Structure](#repository-structure)

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

[↑ Back to top](#table-of-contents)

---

## What Gets Installed

| Component            | macOS      | Linux/WSL | Windows      |
|----------------------|------------|-----------|--------------|
| Homebrew             | ✓          | ✓         | —            |
| 1Password CLI        | ✓          | ✓         | ✓ (winget)   |
| chezmoi              | ✓          | ✓         | ✓ (winget)   |
| zsh + zinit          | ✓          | ✓         | —            |
| Starship prompt      | ✓          | ✓         | ✓            |
| Neovim + lazy.nvim   | ✓          | ✓         | ✓            |
| Git                  | ✓          | ✓         | ✓            |
| Alacritty            | ✓ (cask)   | —         | —            |
| Windows Terminal     | —          | —         | ✓            |
| Total Commander      | —          | —         | ✓            |
| PowerToys            | —          | —         | ✓            |
| WSL 2 (Ubuntu)       | —          | —         | ✓ (optional) |

[↑ Back to top](#table-of-contents)

---

## Machine Profiles

Three profiles are available, selected at first run via `chezmoi init` prompt:

| Profile    | Description                                        |
|------------|----------------------------------------------------|
| `common`   | Developer baseline — all machines                  |
| `gaming`   | Common + gaming tools (Steam, game launchers)      |
| `work`     | Common + work tools (corp VPN, extra git identity) |

To switch profile after initial setup:
```bash
chezmoi edit-config   # Edit data.profile
chezmoi apply
```

### Editing managed files

Always edit dotfiles through chezmoi, not directly in the destination:

```bash
chezmoi edit
```

This opens the source repo in VS Code and applies changes on save.

### Machine with local repo clone

During `chezmoi init` you'll be asked: **"Has local dotfiles repo clone?"** — answer **yes**.

This skips `autoCommit`/`autoPush` and assumes you manage git yourself. Point chezmoi at your local clone so you never need `--source`:

```bash
# Replace the internal clone with a junction to your working repo (Windows)
Remove-Item -Recurse -Force ~/.local/share/chezmoi
New-Item -ItemType Junction -Path ~/.local/share/chezmoi -Target C:\_Projects\dotfiles

# Or on Unix (symlink)
rm -rf ~/.local/share/chezmoi
ln -s ~/Projects/dotfiles ~/.local/share/chezmoi
```

After this, all chezmoi commands work without `--source`:

```bash
chezmoi apply
chezmoi diff
chezmoi edit
```

You can also use git directly in `C:/_Projects/dotfiles` to commit and push — no need for `chezmoi git`.

### Machine without local repo clone

During `chezmoi init` you'll be asked: **"Has local dotfiles repo clone?"** — answer **no**.

This enables `autoCommit` and `autoPush` in the config, so chezmoi automatically commits and pushes any changes back to GitHub on every apply. Chezmoi manages its own source at `~/.local/share/chezmoi`.

[↑ Back to top](#table-of-contents)

---

## Secrets

All secrets are fetched at apply-time from 1Password via `onepasswordRead`. Nothing secret is stored in the repository. See [docs/secrets.md](docs/secrets.md).

[↑ Back to top](#table-of-contents)

---

## Adding Packages

See [docs/adding-packages.md](docs/adding-packages.md) for adding, removing, and upgrading packages.

[↑ Back to top](#table-of-contents)

---

## Setting Up a New Machine

See [docs/new-machine.md](docs/new-machine.md).

[↑ Back to top](#table-of-contents)

---

## Repository Structure

```
dotfiles/
├── bootstrap/          # Entry-point scripts + install helpers
├── packages/           # YAML package lists (common / gaming / work)
├── home/               # Source state for ~/ (chezmoi-managed dotfiles + scripts)
│   ├── .chezmoiscripts/  # run_once_ and run_onchange_ scripts
│   ├── dot_gitconfig.tmpl
│   ├── dot_zshrc.tmpl
│   ├── AppData/          # Windows-specific managed files
│   └── dot_config/       # macOS/Linux config files
├── tests/              # Docker + stub tests
├── .github/            # CI workflows + validation scripts
└── docs/               # Human-readable guides
```

[↑ Back to top](#table-of-contents)

---
