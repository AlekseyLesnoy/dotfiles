# home/.chezmoiscripts/run_always_25-install-totalcmd-plugins.ps1
# chezmoi run_always_ script: install/upgrade Total Commander plugins to latest versions
# Runs on every chezmoi apply; skips silently if TC is not installed yet.
#Requires -Version 7.0

$ErrorActionPreference = 'Stop'

# ─── Self-elevate if not running as Administrator ─────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process pwsh -Verb RunAs -ArgumentList $argList -Wait
    exit 0
}

function Write-Log { param([string]$Msg) Write-Host "[totalcmd-plugins] $Msg" }

# ─── Guard: Total Commander must be installed first ───────────────────────────
$tcDir = 'C:\Program Files\totalcmd'
if (-not (Test-Path $tcDir)) {
    Write-Log "SKIP: Total Commander not found at $tcDir — run chezmoi apply again after TC is installed"
    exit 0
}

# ─── CudaLister ───────────────────────────────────────────────────────────────
$cudaInstallDir = "$tcDir\plugins\wlx\CudaLister"
$cudaMarker     = Join-Path $cudaInstallDir '.installed-version'

Write-Log "Checking latest CudaLister release..."
try {
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Alexey-T/CudaLister/releases/latest' -Headers @{ 'User-Agent' = 'chezmoi-dotfiles' }
    $latest  = $release.tag_name
    $asset   = $release.assets | Where-Object { $_.name -like 'wlx_cudalister_*.zip' } | Select-Object -First 1
} catch {
    Write-Warning "Could not fetch CudaLister release info: $_"
    exit 0
}

$installed = if (Test-Path $cudaMarker) { (Get-Content $cudaMarker -Raw).Trim() } else { '' }

if ($installed -eq $latest) {
    Write-Log "SKIP: CudaLister $latest already installed"
} else {
    Write-Log "Installing CudaLister $latest (was: $(if ($installed) { $installed } else { 'none' }))..."
    $tmp = Join-Path $env:TEMP $asset.name
    try {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tmp -UseBasicParsing
        New-Item -ItemType Directory -Path "$tcDir\plugins\wlx" -Force | Out-Null
        Expand-Archive -Path $tmp -DestinationPath "$tcDir\plugins\wlx" -Force
        New-Item -ItemType Directory -Path $cudaInstallDir -Force | Out-Null
        Set-Content -Path $cudaMarker -Value $latest -Encoding UTF8
        Write-Log "CudaLister $latest installed to $cudaInstallDir"
    } finally {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
    }
}
