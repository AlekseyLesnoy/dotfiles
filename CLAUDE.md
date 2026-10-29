# CLAUDE.md

Cross-platform machine setup automation: chezmoi manages dotfiles, 1Password CLI provides secrets, bootstrap scripts set up new machines from scratch. Targets Windows, WSL Ubuntu, and macOS.

## Validation flow

Run the cheapest checks first.

### After any change

**1. Template dry-run** (~2s, catches most issues, no Docker needed)
```bash
export CI=1 PATH="$PWD/tests/stubs:$PATH"
chezmoi apply --dry-run --source home/ --config tests/stubs/chezmoi-ci.toml --no-tty --force
```
`CI=1` is what keeps this offline: every `onepasswordRead` is guarded by `env "CI"`. The `tests/stubs/op` stub is a bash script with no `.exe`, so on Windows chezmoi skips it and resolves the real `op.exe` — without `CI=1` the dry-run reads real secrets from 1Password.

**2. Lint the file type you touched**
```bash
shellcheck --severity=warning <file>.sh          # shell script
bash -n bootstrap/bootstrap.sh                   # syntax-only, no execution
yq e '.' packages/common.yaml                   # YAML sanity
```

### Before committing

**3. Full lint pass**
```bash
# Only plain .sh files — .sh.tmpl files contain Go template syntax and are not valid shell
find . -name "*.sh" | xargs shellcheck --severity=warning
bash .github/scripts/validate-apt-ids.sh --dry-run

# PowerShell (Windows)
Get-ChildItem -Recurse -Filter "*.ps1" | Invoke-ScriptAnalyzer -Severity Warning,Error -Settings PSScriptAnalyzerSettings.psd1
```

### When touching packages

**4. Package ID validation** (requires network)
```bash
bash .github/scripts/validate-apt-ids.sh         # apt
bash .github/scripts/validate-brew-ids.sh        # Homebrew
pwsh .github/scripts/validate-winget-ids.ps1     # winget
```

### When touching bootstrap or `.chezmoiscripts/`

**5. Docker tests** (slow, but catches real bootstrap issues)
```bash
# Bootstrap idempotency
docker build -f tests/docker/Dockerfile.ubuntu-bootstrap -t dotfiles-ubuntu-bootstrap . && docker run --rm dotfiles-ubuntu-bootstrap

# Template rendering
docker build -f tests/docker/Dockerfile.chezmoi-template -t dotfiles-chezmoi-template . && docker run --rm dotfiles-chezmoi-template
```

For dotfile edits, steps 1–2 are enough before committing; CI runs the rest.

## Architecture

### How the pieces connect

Bootstrap installs prerequisites (git, pwsh7, 1password-cli, yq, chezmoi), then hands off to `chezmoi init --apply`. `.chezmoiroot` points chezmoi at `home/`. `home/.chezmoi.toml.tmpl` prompts for `profile` and `has_local_repo` and reads `email` from 1Password, then chezmoi applies `home/` to `~/`.

After applying dotfiles, chezmoi runs `home/.chezmoiscripts/` in numeric prefix order. `home/.chezmoiignore` splits them by OS: `.ps1` scripts run only on Windows, `.sh` scripts only on macOS/Linux — a new step needs a script per platform it should run on.

### chezmoi source conventions

| Convention | Meaning |
|---|---|
| `dot_` prefix | Becomes `.<name>` in home directory |
| `.tmpl` suffix | Rendered through Go templates |
| `create_` prefix | Written once only; never overwritten on subsequent `chezmoi apply` |
| `run_once_` | Runs once per machine (tracked by content hash in chezmoi state DB) |
| `run_onchange_` | Re-runs whenever its content changes |

### Template variables

Available in all `.tmpl` files: `.profile`, `.hostname`, `.email`, `.is_work`, `.is_gaming`, `.has_local_repo`, `.chezmoi.os`. CI seeds them via `tests/stubs/chezmoi-ci.toml`.

### Machine profiles

`common` packages install on every machine; the chosen profile (`gaming` or `work`) adds its own `packages/<profile>.yaml` on top.

### Package management pattern

Packages live in `packages/*.yaml`, one section per package manager (`brew` taps/formulae/casks, `apt`, `winget`). The `run_onchange_20-install-packages` scripts embed `sha256sum` hashes of the YAML files in comments, so editing a package YAML re-triggers install on the next `chezmoi apply`.

Packages are never auto-removed. To remove one: uninstall manually, then delete it from the YAML. Items under `remove:` are reported as manual action items.

### Secrets

All secrets use `onepasswordRead "op://..."` in `.tmpl` files, guarded for CI:
```
{{ if not (env "CI") }}{{ onepasswordRead "op://..." }}{{ else }}ci-stub-value{{ end }}
```
Every new secret needs this guard, or the dry-run and CI break.

### Bootstrap phase state

Both bootstrap scripts write `phase_<name>=done` to `~/.dotfiles-bootstrap-state` (Unix) or `~/.dotfiles-bootstrap-state.ini` (Windows). Re-running after interruption resumes from the last incomplete phase. To force a full re-run: delete that file.

### Local repo workflow

When `has_local_repo = true`, `autoCommit`/`autoPush` are disabled. On the Windows dev machine `~/.local/share/chezmoi` is a junction to this repo, so the repo *is* the chezmoi source: `chezmoi diff` shows how the live machine has drifted from it, and `chezmoi apply` writes this working tree onto the machine.

## Gotchas

- **App-saved settings drift.** Apps like Windows Terminal rewrite their own `settings.json`. To capture a change made in the app's UI, run `chezmoi diff <target>` and copy it into the template, keeping the key order and layout the app saves so the next save does not show up as a diff.
- **`create_` files land once.** PowerToys, Total Commander, and Command Palette configs are `create_` files: editing them in the repo changes new machines only, never an existing one.
- **Nerd Font glyphs** go in TOML as `\uXXXX` / `\UXXXXXXXX` escapes, not raw characters — raw private-use glyphs get silently lost in editors and tools.

## CI

`.github/workflows/ci.yml` runs six parallel jobs on every push/PR to `main` (`lint-shell`, `lint-powershell`, `validate-yaml`, `test-linux-docker`, `test-macos-runner`, `test-windows-runner`), gated by a `report` job. Docs-only changes (`**.md`, `docs/**`, and the paths in its `paths-ignore`) skip `ci.yml`; `ci-skip.yml` satisfies the required gate instead — keep the two path lists in sync.

`staleness.yml` runs weekly, validating that winget/Homebrew/apt IDs and bootstrap URLs still resolve, and opens a GitHub Issue on failure. `benchmark.yml` runs on changes to the starship config, the PowerShell profile, or `.zshrc`.

## Working conventions

- Commits follow Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `build(deps):`).
- `TASKS.md` is the backlog: add new follow-up work there and tick items off when done.
