# Implementation Tasks

## Foundation
- [x] Init repo, push to GitHub, create TASKS.md + README skeleton
- [x] Create packages/common.yaml, packages/gaming.yaml, packages/work.yaml

## Bootstrap — Unix
- [x] bootstrap/bootstrap.sh (platform detect, build tools, brew, op, yq, chezmoi, handoff)
- [x] bootstrap/lib/install-op.sh
- [x] bootstrap/lib/install-chezmoi.sh
- [x] bootstrap/lib/state.sh

## Bootstrap — Windows
- [x] bootstrap/bootstrap.ps1 (Phase 1: pwsh 7 install + re-launch; Phase 2: elevation + all phases)
- [x] bootstrap/lib/install-op.ps1
- [x] bootstrap/lib/install-chezmoi.ps1
- [x] bootstrap/lib/state.ps1

## chezmoi Config
- [x] .chezmoi.toml.tmpl (profile/hostname/email prompts, 1Password integration)
- [x] .chezmoiignore (platform exclusions)

## Dotfiles
- [x] home/dot_zshrc.tmpl
- [x] home/dot_gitconfig.tmpl + dot_gitconfig_work.tmpl
- [x] home/dot_config/starship/starship.toml
- [ ] home/dot_config/nvim/ (init.lua + lazy.nvim plugins)
- [x] home/dot_config/alacritty/alacritty.toml.tmpl
- [x] home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl
- [x] home/AppData/.../WindowsTerminal/settings.json.tmpl
- [ ] home/AppData/.../wsl/wsl.conf

## run_onchange_ Scripts
- [x] .chezmoiscripts/run_once_00-backup-settings.ps1
- [x] .chezmoiscripts/run_once_00-backup-settings.sh
- [x] .chezmoiscripts/run_once_05-backup-bitlocker-keys.ps1.tmpl
- [x] .chezmoiscripts/run_onchange_10-system-settings.sh.tmpl
- [x] .chezmoiscripts/run_onchange_10-system-settings.ps1.tmpl
- [x] .chezmoiscripts/run_onchange_20-install-packages.sh.tmpl
- [x] .chezmoiscripts/run_onchange_20-install-packages.ps1.tmpl
- [x] .chezmoiscripts/run_onchange_30-configure-shell.sh
- [x] .chezmoiscripts/run_onchange_99-report.sh.tmpl

## Testing
- [x] tests/stubs/op (fake op binary)
- [x] tests/stubs/chezmoi-ci.toml
- [x] tests/docker/Dockerfile.ubuntu-bootstrap + entrypoint
- [x] tests/docker/Dockerfile.chezmoi-template + entrypoint

## CI / Automation
- [x] .github/workflows/ci.yml
- [x] .github/workflows/ci-skip.yml
- [x] .github/workflows/staleness.yml
- [x] .github/workflows/dependabot-auto-merge.yml
- [x] .github/dependabot.yml
- [x] .github/scripts/validate-winget-ids.ps1
- [x] .github/scripts/validate-brew-ids.sh
- [x] .github/scripts/validate-apt-ids.sh

## Docs
- [x] docs/adding-packages.md
- [x] docs/secrets.md
- [x] docs/new-machine.md
- [x] README.md (finalize with one-liner install commands)

## Pending
- [ ] home/dot_config/nvim/ (init.lua + lazy.nvim plugins)
- [ ] home/AppData/Local/Packages/.../wsl.conf
- [ ] Work gitconfig full setup (dot_gitconfig_work.tmpl)
- [ ] SSH key setup
- [ ] Move Windows Terminal settings.json to run_once_ script (currently uses [apply] force = true as workaround)
