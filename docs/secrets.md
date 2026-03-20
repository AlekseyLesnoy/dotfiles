# Secrets Management <!-- omit in toc -->

All secrets in this dotfiles repository are fetched **at apply-time** from 1Password.
Zero secret material is stored in the repository.

## Table of Contents <!-- omit in toc -->
- [How it works](#how-it-works)
- [Required 1Password items](#required-1password-items)
- [First-time setup](#first-time-setup)
- [Authenticating for chezmoi apply](#authenticating-for-chezmoi-apply)
- [CI / testing](#ci--testing)
- [Adding a new secret](#adding-a-new-secret)

## How it works

[chezmoi](https://chezmoi.io/user-guide/password-managers/1password/) has built-in
support for 1Password via the `onepasswordRead` template function.

In any `.tmpl` file, reference a secret like this:

```
{{ onepasswordRead "op://Personal/GPG Signing Key/fingerprint" }}
```

When `chezmoi apply` runs, it calls the 1Password CLI (`op`) to fetch the value
and injects it into the rendered file. The rendered file lives only on disk — never in git.

[↑ Back to top](#table-of-contents)

---

## Required 1Password items

| Item path | Used in | Description |
|-----------|---------|-------------|
| `op://Personal/github.com/login` | `.chezmoi.toml.tmpl` | GitHub email address |
| `op://Personal/GPG Signing Key/fingerprint` | `dot_gitconfig.tmpl` | GPG key fingerprint for commit signing |
| `op://Kobo/GPG Signing Key Work/fingerprint` | `dot_gitconfig_work.tmpl` | Work GPG key fingerprint |
| `op://Kobo/GPG Signing Key Work/email` | `dot_gitconfig_work.tmpl` | Work email address |

[↑ Back to top](#table-of-contents)

---

## First-time setup

1. Install 1Password desktop app and sign in
2. Install 1Password CLI:
   - macOS/Linux: handled by `bootstrap.sh` via `lib/install-op.sh`
   - Windows: handled by `bootstrap.ps1` via `lib/install-op.ps1`
3. Add your account: `op account add`
4. Sign in: `eval $(op signin)` (macOS/Linux) or `op signin` (Windows)

The bootstrap scripts handle steps 2–4 automatically.

[↑ Back to top](#table-of-contents)

---

## Authenticating for chezmoi apply

chezmoi is configured with `mode = "opapp"` in `.chezmoi.toml.tmpl`.
This means it uses the 1Password desktop app for authentication — **no CLI session needed**.

If you prefer CLI sessions, change to `mode = "cli"` in `~/.config/chezmoi/chezmoi.toml`.

[↑ Back to top](#table-of-contents)

---

## CI / testing

In CI, the 1Password CLI is replaced by a fake stub at `tests/stubs/op`.
Templates use a CI guard as defense-in-depth:

```
{{ if not (env "CI") }}{{ onepasswordRead "op://Personal/GPG Signing Key/fingerprint" }}{{ else }}ci-stub-gpg-key{{ end }}
```

The `tests/stubs/chezmoi-ci.toml` config file also seeds all template variables
with stub values so no real 1Password interaction is required in CI.

[↑ Back to top](#table-of-contents)

---

## Adding a new secret

1. Create the item in 1Password
2. Reference it in the appropriate `.tmpl` file using `onepasswordRead`
3. Test locally: `chezmoi apply --dry-run`
4. Add a stub response to `tests/stubs/op` for the new field
5. Commit the template change (the actual secret is never committed)

[↑ Back to top](#table-of-contents)
