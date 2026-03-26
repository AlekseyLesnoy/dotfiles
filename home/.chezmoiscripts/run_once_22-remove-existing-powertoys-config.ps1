#Requires -Version 7.0
# home/.chezmoiscripts/run_once_22-remove-existing-powertoys-config.ps1
# chezmoi run_once_ script: remove existing PowerToys config so chezmoi can lay down the baseline.
# Runs exactly once per machine. The backup script (run_once_00) has already backed them up.

$ErrorActionPreference = 'Stop'

function Write-Log { param([string]$Msg) Write-Host "[powertoys-config] $Msg" }

$base = "$env:LOCALAPPDATA\Microsoft\PowerToys"

if (-not (Test-Path $base)) {
    Write-Log "SKIP: PowerToys settings dir not found ($base) - PowerToys not yet installed"
    exit 0
}

# Stop PowerToys so it doesn't overwrite files on exit
Stop-Process -Name PowerToys -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$filesToRemove = @(
    "settings.json",
    "AdvancedPaste\settings.json",
    "AlwaysOnTop\settings.json",
    "FancyZones\settings.json",
    "FancyZones\custom-layouts.json",
    "FancyZones\layout-hotkeys.json",
    "FancyZones\layout-templates.json",
    "Peek\settings.json",
    "PowerToys Run\settings.json",
    "QuickAccent\settings.json"
)

foreach ($f in $filesToRemove) {
    $path = Join-Path $base $f
    if (Test-Path $path) {
        Remove-Item $path -Force
        Write-Log "Removed: $path"
    } else {
        Write-Log "SKIP: $path (not found)"
    }
}

# CmdPal is an MSIX app - its settings live under the Packages directory
$cmdPalSettings = "$env:LOCALAPPDATA\Packages\Microsoft.CommandPalette_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $cmdPalSettings) {
    Stop-Process -Name CmdPal -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Remove-Item $cmdPalSettings -Force
    Write-Log "Removed: $cmdPalSettings"
} else {
    Write-Log "SKIP: $cmdPalSettings (not found)"
}
