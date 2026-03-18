# Implementation Tasks

## Foundation
- [ ] Init repo, push to GitHub, create TASKS.md + README skeleton
- [ ] Create packages/common.yaml, packages/gaming.yaml, packages/work.yaml

## Bootstrap — Unix
- [ ] bootstrap/bootstrap.sh (platform detect, build tools, brew, op, yq, chezmoi, handoff)
- [ ] bootstrap/lib/install-op.sh
- [ ] bootstrap/lib/install-chezmoi.sh
- [ ] bootstrap/lib/state.sh

## Bootstrap — Windows
- [ ] bootstrap/bootstrap.ps1 (Phase 1: pwsh 7 install + re-launch; Phase 2: elevation + all phases)
- [ ] bootstrap/lib/install-op.ps1
- [ ] bootstrap/lib/install-chezmoi.ps1
- [ ] bootstrap/lib/state.ps1

## chezmoi Config
- [ ] .chezmoi.toml.tmpl (profile/hostname/email prompts, 1Password integration)
- [ ] .chezmoiignore (platform exclusions)

## Dotfiles
- [ ] home/dot_zshrc.tmpl
- [ ] home/dot_gitconfig.tmpl + dot_gitconfig_work.tmpl
- [ ] home/dot_config/starship/starship.toml
- [ ] home/dot_config/nvim/ (init.lua + lazy.nvim plugins)
- [ ] home/dot_config/alacritty/alacritty.toml.tmpl
- [ ] windows/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl
- [ ] windows/AppData/.../WindowsTerminal/settings.json.tmpl
- [ ] windows/wsl/wsl.conf

## run_onchange_ Scripts
- [ ] scripts/run_onchange_10-system-settings.sh.tmpl
- [ ] scripts/run_onchange_10-system-settings.ps1.tmpl
- [ ] scripts/run_onchange_20-install-packages.sh.tmpl
- [ ] scripts/run_onchange_20-install-packages.ps1.tmpl
- [ ] scripts/run_onchange_30-configure-shell.sh
- [ ] scripts/run_onchange_99-report.sh

## Testing
- [ ] tests/stubs/op (fake op binary)
- [ ] tests/stubs/chezmoi-ci.toml
- [ ] tests/docker/Dockerfile.ubuntu-bootstrap + entrypoint
- [ ] tests/docker/Dockerfile.chezmoi-template + entrypoint

## CI / Automation
- [ ] .github/workflows/ci.yml
- [ ] .github/workflows/staleness.yml
- [ ] .github/scripts/validate-winget-ids.ps1
- [ ] .github/scripts/validate-brew-ids.sh
- [ ] .github/scripts/validate-apt-ids.sh

## Docs
- [ ] docs/adding-packages.md
- [ ] docs/secrets.md
- [ ] docs/new-machine.md
- [ ] README.md (finalize with one-liner install commands)
