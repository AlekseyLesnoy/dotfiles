#Requires -Version 5.1
<#
.SYNOPSIS
    Dotfile bootstrap entry point for Windows.
    Compatible with Windows PowerShell 5.1 (Phase 1 only); upgrades to pwsh 7 for all real work.

.DESCRIPTION
    Remote one-liner:
        irm https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/bootstrap.ps1 | iex

    Flags:
        -Resume     Resume after a reboot (reads state file, removes run key)
        -CI         Skip interactive prompts
        -DryRun     Print steps without executing

.NOTES
    Phase 1 runs under PowerShell 5.1: installs pwsh 7, re-launches.
    All subsequent phases require pwsh 7+ (#Requires -Version 7.0 in lib scripts).
#>
param(
    [switch]$Resume,
    [switch]$CI,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$DOTFILES_REPO = 'https://github.com/AlekseyLesnoy/dotfiles.git'
$ScriptPath    = $MyInvocation.MyCommand.Path

# ─── Helpers (5.1-compatible) ─────────────────────────────────────────────────
function Write-Step        { param([string]$Msg) Write-Host "`n═══ $Msg ═══" -ForegroundColor Cyan }
function Write-BootstrapLog { param([string]$Msg) Write-Host "[bootstrap] $Msg" }

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = [Security.Principal.WindowsPrincipal]$id
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Run {
    param([string]$Command, [string[]]$ArgumentList = @())
    if ($DryRun) {
        Write-Host "[dry-run] $Command $($ArgumentList -join ' ')"
        return 0
    }
    & $Command @ArgumentList
    return $LASTEXITCODE
}

# ─── Phase 1: Install pwsh 7 and re-launch ────────────────────────────────────
Write-Step "Phase 1: Install pwsh 7 + re-launch"

$IsPwsh7 = ($PSVersionTable.PSVersion.Major -ge 7)

if (-not $IsPwsh7) {
    Write-BootstrapLog "Running under PowerShell $($PSVersionTable.PSVersion). Installing pwsh 7..."

    # winget may not be present on very old Win 10 — handle gracefully
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Warning "winget not found. Please install the App Installer from the Microsoft Store and re-run."
        exit 1
    }

    # Install pwsh 7 (idempotent — winget handles already-installed)
    winget install --id Microsoft.PowerShell --exact --silent --accept-package-agreements --accept-source-agreements
    # Note: exit code check is unreliable from PS5 iex pipe; proceed regardless

    # Re-launch under pwsh 7
    $pwsh = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    if (-not (Test-Path $pwsh)) {
        $pwsh = 'pwsh'  # Rely on PATH if the default install path differs
    }

    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$ScriptPath`"")
    if ($Resume)  { $argList += '-Resume' }
    if ($CI)      { $argList += '-CI' }
    if ($DryRun)  { $argList += '-DryRun' }

    Write-BootstrapLog "Re-launching under pwsh 7..."
    Start-Process $pwsh -ArgumentList $argList -Wait
    exit $LASTEXITCODE
}

Write-BootstrapLog "Running under pwsh $($PSVersionTable.PSVersion). Continuing..."

# ─── Load lib scripts ─────────────────────────────────────────────────────────
$LibDir    = Join-Path $PSScriptRoot 'lib'
$StateFile = Join-Path $env:USERPROFILE '.dotfiles-bootstrap-state.ini'

# Source lib scripts if running from cloned repo
if (Test-Path (Join-Path $LibDir 'state.ps1')) {
    . (Join-Path $LibDir 'state.ps1')
}
else {
    # Minimal inline state helpers when bootstrapping from pipe
    function Set-PhaseComplete { param([string]$Phase) Add-Content $StateFile "phase_${Phase}=done" }
    function Test-PhaseComplete {
        param([string]$Phase)
        if (Test-Path $StateFile) {
            return (Get-Content $StateFile) -match "^phase_${Phase}=done"
        }
        return $false
    }
    function Unregister-BootstrapResume {
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        Remove-ItemProperty -Path $key -Name 'DotfileBootstrapResume' -ErrorAction SilentlyContinue
    }
}

# ─── Resume handling ──────────────────────────────────────────────────────────
if ($Resume) {
    Write-Step "Resuming after reboot"
    Unregister-BootstrapResume
    Write-BootstrapLog "Resume key removed."
}

# ─── Phase 2: Self-elevation ──────────────────────────────────────────────────
Write-Step "Phase 2: Self-elevation"
if (-not (Test-IsAdmin)) {
    Write-BootstrapLog "Not running as Administrator. Re-launching elevated..."
    $argString = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$ScriptPath`"")
    if ($Resume)  { $argString += '-Resume' }
    if ($CI)      { $argString += '-CI' }
    if ($DryRun)  { $argString += '-DryRun' }
    Start-Process pwsh -Verb RunAs -ArgumentList $argString -Wait
    exit $LASTEXITCODE
}
Write-BootstrapLog "Running as Administrator."

# ─── Phase 3: Execution policy ────────────────────────────────────────────────
Write-Step "Phase 3: Execution policy"
if (-not (Test-PhaseComplete 'exec_policy')) {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-BootstrapLog "Execution policy set to RemoteSigned for CurrentUser."
    Set-PhaseComplete 'exec_policy'
}
else { Write-BootstrapLog "Execution policy already set. Skipping." }

# ─── Phase 4: System settings (require admin) ─────────────────────────────────
Write-Step "Phase 4: System settings"
if (-not (Test-PhaseComplete 'system_settings')) {
    Write-BootstrapLog "Enabling Developer Mode..."
    $devPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    if (-not (Test-Path $devPath)) { New-Item -Path $devPath -Force | Out-Null }
    Set-ItemProperty -Path $devPath -Name 'AllowDevelopmentWithoutDevLicense' -Value 1 -Type DWord
    Set-ItemProperty -Path $devPath -Name 'AllowAllTrustedApps' -Value 1 -Type DWord
    Write-BootstrapLog "Developer Mode enabled."

    # Windows sudo (Win 11 24H2+)
    Write-BootstrapLog "Enabling Windows sudo..."
    $sudoPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo'
    try {
        if (-not (Test-Path $sudoPath)) { New-Item -Path $sudoPath -Force | Out-Null }
        # Mode 1 = inline (prompt-less equivalent)
        Set-ItemProperty -Path $sudoPath -Name 'Enabled' -Value 1 -Type DWord
        Write-BootstrapLog "Windows sudo enabled."
    }
    catch {
        Write-Warning "Could not enable Windows sudo (may not be supported on this OS version): $_"
    }

    Set-PhaseComplete 'system_settings'
}
else { Write-BootstrapLog "System settings already applied. Skipping." }

# ─── Phase 5: Install Git ─────────────────────────────────────────────────────
Write-Step "Phase 5: Install Git"
if (-not (Test-PhaseComplete 'git_install')) {
    $installed = winget list --id Git.Git --exact 2>&1
    if ($LASTEXITCODE -eq 0 -and $installed -match 'Git.Git') {
        Write-BootstrapLog "Git already installed. Skipping."
    }
    else {
        Write-BootstrapLog "Installing Git via winget..."
        winget install --id Git.Git --exact --silent --accept-package-agreements --accept-source-agreements
    }
    Set-PhaseComplete 'git_install'
}
else { Write-BootstrapLog "Git install phase already done. Skipping." }

# ─── Phase 6: Install 1Password CLI ──────────────────────────────────────────
Write-Step "Phase 6: Install 1Password CLI"
if (-not (Test-PhaseComplete 'op_install')) {
    if (Test-Path (Join-Path $LibDir 'install-op.ps1')) {
        . (Join-Path $LibDir 'install-op.ps1')
    }
    else {
        Write-BootstrapLog "Fetching install-op.ps1 from GitHub..."
        $opTmp = Join-Path $env:TEMP 'dotfiles-install-op.ps1'
        (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/lib/install-op.ps1' -UseBasicParsing).Content | Set-Content $opTmp -Encoding UTF8
        . $opTmp
    }

    if (-not $CI) {
        Write-BootstrapLog "Adding 1Password account (follow prompts)..."
        if (Get-Command op -ErrorAction SilentlyContinue) {
            $accounts = & op account list 2>&1
            if (-not ($accounts -match '\S')) {
                op account add
            }
            else { Write-BootstrapLog "1Password account already configured." }
        }
    }
    Set-PhaseComplete 'op_install'
}
else { Write-BootstrapLog "1Password CLI already installed. Skipping." }

# ─── Phase 7: WSL (optional) ──────────────────────────────────────────────────
Write-Step "Phase 7: Install WSL (optional)"
if (-not (Test-PhaseComplete 'wsl_install')) {
    $installWSL = $false
    if ($CI) {
        Write-BootstrapLog "[CI] Skipping WSL install."
    }
    elseif (-not $DryRun) {
        $choice = Read-Host "Install WSL 2 with Ubuntu? [y/N]"
        $installWSL = ($choice -match '^[Yy]')
    }

    if ($installWSL) {
        Write-BootstrapLog "Installing WSL 2 with Ubuntu (requires restart)..."
        wsl --install --distribution Ubuntu

        # Register resume key and save phase
        Set-PhaseComplete 'wsl_install'
        if (Test-Path (Join-Path $LibDir 'state.ps1')) {
            Register-BootstrapResume -ScriptPath $ScriptPath
        }
        Write-BootstrapLog "Restart required for WSL. The bootstrap will resume automatically after login."
        if (-not $DryRun) {
            Restart-Computer -Force
            exit 0
        }
    }
    else {
        Write-BootstrapLog "Skipping WSL install."
        Set-PhaseComplete 'wsl_install'
    }
}
else { Write-BootstrapLog "WSL phase already done. Skipping." }

# ─── Phase 8: Install chezmoi ────────────────────────────────────────────────
Write-Step "Phase 8: Install chezmoi"
if (-not (Test-PhaseComplete 'chezmoi_install')) {
    if (Test-Path (Join-Path $LibDir 'install-chezmoi.ps1')) {
        . (Join-Path $LibDir 'install-chezmoi.ps1')
    }
    else {
        Write-BootstrapLog "Fetching install-chezmoi.ps1 from GitHub..."
        $chezTmp = Join-Path $env:TEMP 'dotfiles-install-chezmoi.ps1'
        (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/AlekseyLesnoy/dotfiles/main/bootstrap/lib/install-chezmoi.ps1' -UseBasicParsing).Content | Set-Content $chezTmp -Encoding UTF8
        . $chezTmp
    }
    Set-PhaseComplete 'chezmoi_install'
}
else { Write-BootstrapLog "chezmoi already installed. Skipping." }

# Refresh PATH
$env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('PATH', 'User')

# ─── Phase 9: chezmoi init --apply ───────────────────────────────────────────
Write-Step "Phase 9: chezmoi init --apply"
if ($DryRun) {
    Write-BootstrapLog "[dry-run] Would run: chezmoi init --apply --verbose $DOTFILES_REPO"
}
elseif (-not (Test-PhaseComplete 'chezmoi_apply')) {
    if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
        Write-BootstrapLog "Handing off to chezmoi..."
        chezmoi init --apply --verbose $DOTFILES_REPO
        Set-PhaseComplete 'chezmoi_apply'
    }
    else {
        throw "chezmoi not found. Cannot proceed."
    }
}
else {
    Write-BootstrapLog "chezmoi already applied. Running update..."
    chezmoi update --verbose
}

Write-Host "`n[bootstrap] Bootstrap complete! Open a new terminal to pick up all changes." -ForegroundColor Green
