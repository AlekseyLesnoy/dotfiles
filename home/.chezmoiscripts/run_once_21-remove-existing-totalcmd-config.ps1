#Requires -Version 7.0
# home/.chezmoiscripts/run_once_01-remove-existing-totalcmd-config.ps1
# chezmoi run_once_ script: remove existing TC config so chezmoi can lay down the baseline.
# Runs exactly once per machine. The backup script (run_once_00) has already backed them up.

$ErrorActionPreference = 'Stop'

function Write-Log { param([string]$Msg) Write-Host "[totalcmd-config] $Msg" }

$filesToRemove = @(
    "$env:APPDATA\GHISLER\wincmd.ini",
    "$env:APPDATA\GHISLER\DEFAULT.BAR",
    "$env:APPDATA\GHISLER\lsplugin.ini"
)

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Log "Removed: $file"
    } else {
        Write-Log "SKIP: $file (not found)"
    }
}
