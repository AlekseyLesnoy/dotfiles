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

## Total Commander
- [x] create_wincmd.ini.tmpl (Dracula colors, VS Code editor, profile-conditional DirMenu)
- [x] create_DEFAULT.BAR (VS Code diff button)
- [x] create_lsplugin.ini (CudaLister plugin settings)
- [x] run_once_21-remove-existing-totalcmd-config.ps1
- [x] run_once_25-install-totalcmd-plugins.ps1 (CudaLister from GitHub releases)

## PowerToys
- [x] Add Microsoft.PowerToys to packages/common.yaml
- [x] run_once_22-remove-existing-powertoys-config.ps1 (stops PowerToys, clears managed files)
- [x] 14 create_ settings files for non-default modules (AdvancedPaste, AlwaysOnTop, FancyZones, FindMyMouse, Measure Tool, MouseJump, Peek, PowerToys Run, QuickAccent, Shortcut Guide)
- [x] CmdPal settings (Packages/Microsoft.CommandPalette_8wekyb3d8bbwe/LocalState) with Shift+Backspace hotkey
- [x] CmdPal plugins: WorkspaceLauncherForVSCode + EdgeFavorites (common), VisualStudio (work)
- [ ] Add ZoomIt configuration (`home/AppData/Local/Microsoft/PowerToys/ZoomIt/create_settings.json`)

## Pending
- [ ] Install and integrate mise (runtime version manager)
- [ ] home/dot_config/nvim/ (init.lua + lazy.nvim plugins)
- [ ] home/AppData/Local/Packages/.../wsl.conf
- [ ] Work gitconfig full setup (dot_gitconfig_work.tmpl)
- [ ] SSH key setup
- [ ] Move Windows Terminal settings.json to run_once_ script (currently uses [apply] force = true as workaround)
- [x] MonaspiceNE Nerd Font Windows install (GitHub release download in install script)
- [x] Total Commander: fix CompareTool and Editor to use VS Code (code CLI doesn't work directly in TC, %LOCALAPPDATA% path didn't work either — needs investigation)

## PowerShell Profile
- [ ] Review and improve PowerShell profile (`home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl`)

## Starship Transient Prompt
- [x] Implement transient prompt for Starship in both profiles
  - Transient prompt replaces the previous prompt line with a minimal version after a command runs,
    keeping scrollback clean (only the current prompt is full-featured)
  - Starship supports this via `[transient_prompt]` in the TOML config
  - Needs to be enabled in the shell init too:
    - zsh: `enable-starship-transience` function or `starship init zsh --print-full-init` with transience flag
    - pwsh: `Enable-TransientPrompt` after `Invoke-Expression (&starship init powershell)`
  - Add to both `starship-al.toml` and `starship-minimal.toml`
  - Test that `prompt-al` / `prompt-minimal` switcher functions re-enable transience after switching

## GitHub Repo Command Palette Extension
- [x] Scaffold `CmdPal-GitHubRepoSearch` project at `C:/_Projects/CmdPal-GitHubRepoSearch`
  - Based on [PowerToysRun-GitHubRepo](https://github.com/8LWXpg/PowerToysRun-GitHubRepo) by 8LWXpg (MIT) — credited in every file header + README
  - Three projects: `GitHubRepoSearch` (MSIX app), `GitHubRepoSearch.Core` (testable logic), `GitHubRepoSearch.Tests` (xUnit)
- [x] Implement `GitHubService` — per-user HttpClient, auth tokens, `RepoQueryAsync` + `UserReposAsync`
- [x] Implement `SettingsService` — local JSON at `%LOCALAPPDATA%\CmdPal-GitHubRepoSearch\settings.json`
- [x] Implement `GitHubSearchPage` — `DynamicListPage`, 4 search modes, context commands
- [x] Implement `GitHubRepoCommandsProvider` + `GitHubRepoSearchExtension` + `Program.cs` COM server
- [x] `Package.appxmanifest` — `internetClient` + `runFullTrust`, `com.microsoft.commandpalette`
- [x] xUnit tests for `GitHubService` and `SettingsService` (using MockHttp, no network)
- [x] GitHub Actions CI — build Core + run tests + build MSIX artifact
- [ ] Add Dependabot config (`.github/dependabot.yml`) — **defer until extension is working**
- [ ] Generate/copy placeholder MSIX assets PNGs into `GitHubRepoSearch/Assets/`
- [ ] First sideload + smoke test on local machine
- [ ] Create GitHub remote repo and push
- [ ] Remove PowerToys Run config from dotfiles once migration is complete (delete `home/AppData/Local/Microsoft/PowerToys/PowerToys Run/create_settings.json`, remove from cleanup script)

## Benchmark CI baselines
- [ ] Set up CI-captured baselines for regression detection
  - Currently: local baselines committed to repo, but CI runners are faster so thresholds never fire
  - Currently: `--no-regression` flag disables issue creation from CI
  - Plan:
    1. Add `update-baselines` job (manual `workflow_dispatch` only) that downloads artifacts
       from a completed bench run and commits them to `tests/benchmark/baselines/ci/`
    2. Change CI summarize steps to compare against `ci/` baselines (without `--no-regression`)
    3. `open-issue` job fires when summarize exits 1 (regression vs CI baseline detected)
  - Local baselines in `tests/benchmark/baselines/` stay for local `prompt-al`/`prompt-minimal` comparison
