#Requires -Version 7.0
# home/.chezmoiscripts/run_once_00-backup-settings.ps1
# chezmoi run_once_ script: back up original Windows settings before any changes
# Runs exactly once (per machine), before system-settings apply.

$ErrorActionPreference = 'Stop'

# ─── Self-elevate if not running as Administrator ─────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process pwsh -Verb RunAs -ArgumentList $argList -Wait
    exit 0
}

function Write-Log { param([string]$Msg) Write-Host "[backup-settings] $Msg" }

$BackupDir = Join-Path $env:USERPROFILE ".dotfiles-backups"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupFile = Join-Path $BackupDir "settings-backup-$Timestamp.json"

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
Write-Log "Backing up original settings to $BackupFile"

$backup = @{}

# ─── Registry snapshots ──────────────────────────────────────────────────────
function Get-RegValueSafe {
    param([string]$Path, [string]$Name)
    try { (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name }
    catch { $null }
}

$explorerPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$backup['explorer'] = @{
    Hidden                     = Get-RegValueSafe $explorerPath 'Hidden'
    HideFileExt                = Get-RegValueSafe $explorerPath 'HideFileExt'
    ShowSuperHidden            = Get-RegValueSafe $explorerPath 'ShowSuperHidden'
    LaunchTo                   = Get-RegValueSafe $explorerPath 'LaunchTo'
    NavPaneExpandToCurrentFolder = Get-RegValueSafe $explorerPath 'NavPaneExpandToCurrentFolder'
    TaskbarMn                  = Get-RegValueSafe $explorerPath 'TaskbarMn'
    ShowTaskViewButton         = Get-RegValueSafe $explorerPath 'ShowTaskViewButton'
}

$devPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
$backup['developerMode'] = @{
    AllowDevelopmentWithoutDevLicense = Get-RegValueSafe $devPath 'AllowDevelopmentWithoutDevLicense'
    AllowAllTrustedApps               = Get-RegValueSafe $devPath 'AllowAllTrustedApps'
}

$sudoPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo'
$backup['sudo'] = @{
    Enabled = Get-RegValueSafe $sudoPath 'Enabled'
}

$telemetryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
$backup['telemetry'] = @{
    AllowTelemetry = Get-RegValueSafe $telemetryPath 'AllowTelemetry'
}

$adPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
$backup['advertising'] = @{
    Enabled = Get-RegValueSafe $adPath 'Enabled'
}

# ─── Power settings ───────────────────────────────────────────────────────────
try {
    $powerOutput = powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 2>$null
    $acLine = $powerOutput | Select-String 'Current AC Power Setting Index'
    $dcLine = $powerOutput | Select-String 'Current DC Power Setting Index'
    $backup['power'] = @{
        StandbyTimeoutAC = if ($acLine) { $acLine.Line.Trim() } else { 'unknown' }
        StandbyTimeoutDC = if ($dcLine) { $dcLine.Line.Trim() } else { 'unknown' }
    }
} catch {
    $backup['power'] = @{ error = $_.ToString() }
}

# ─── Hibernate status ─────────────────────────────────────────────────────────
try {
    $hibOutput = powercfg /a 2>$null
    $backup['hibernate'] = @{
        Status = ($hibOutput | Select-String 'Hibernate' | Select-Object -First 1)?.Line?.Trim() ?? 'unknown'
    }
} catch {
    $backup['hibernate'] = @{ error = $_.ToString() }
}

# ─── Save registry backup to file ────────────────────────────────────────────
$backup | ConvertTo-Json -Depth 5 | Set-Content -Path $BackupFile -Encoding UTF8

# ─── Back up managed config files ────────────────────────────────────────────
$FilesBackupDir = Join-Path $BackupDir "files-$Timestamp"
New-Item -ItemType Directory -Path $FilesBackupDir -Force | Out-Null

$filesToBackup = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:APPDATA\Code\User\settings.json",
    "$env:USERPROFILE\.gitconfig",
    "$env:USERPROFILE\.config\starship.toml",
    "$env:APPDATA\GHISLER\wincmd.ini",
    "$env:APPDATA\GHISLER\DEFAULT.BAR",
    "$env:APPDATA\GHISLER\lsplugin.ini"
)

foreach ($file in $filesToBackup) {
    if (Test-Path $file) {
        $rel = $file -replace [regex]::Escape($env:USERPROFILE), '' -replace '^\\', ''
        $dest = Join-Path $FilesBackupDir ($rel -replace '\\', '_')
        Copy-Item $file $dest -Force
        Write-Log "Backed up: $file"
    }
}

Write-Log "Backup complete: $BackupFile"
Write-Log "File backups: $FilesBackupDir"
Write-Log "To restore, manually re-apply the registry values or copy files back."
