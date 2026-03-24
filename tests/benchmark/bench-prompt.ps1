#Requires -Version 7.0
# tests/benchmark/bench-prompt.ps1
# Measures pwsh startup time and starship prompt render time in two scenarios:
# plain home directory vs. inside a git repository.
#
# Usage: bench-prompt.ps1 [-GitDir PATH] [-StarshipProfile minimal|al]
#   -GitDir           Path to a git repo for the git scenario (default: script directory)
#   -StarshipProfile  Starship profile to benchmark (default: minimal)
#
# Output: bench-results-windows-<profile>.json in current directory
# Requires: hyperfine, starship

param(
    [string]$GitDir          = (Resolve-Path "$PSScriptRoot/../..").Path,
    [ValidateSet('minimal','al')]
    [string]$StarshipProfile = 'minimal'
)

$ErrorActionPreference = 'Stop'
$PlainDir = $env:USERPROFILE
$Output   = "bench-results-windows-$StarshipProfile.json"

$StarshipConfigDir = "$HOME/.config/starship"
switch ($StarshipProfile) {
    'al'      { $env:STARSHIP_CONFIG = "$StarshipConfigDir/starship-al.toml" }
    'minimal' { Remove-Item Env:STARSHIP_CONFIG -ErrorAction SilentlyContinue }
}

function Write-Log { param([string]$Msg) Write-Host "[bench] $Msg" -ForegroundColor Cyan }
function Get-Mean  { param([string]$JsonPath)
    $r = (Get-Content $JsonPath | ConvertFrom-Json).results[0]
    return [math]::Round($r.mean * 1000, 1), [math]::Round($r.stddev * 1000, 1)
}

# ─── Dependency checks ────────────────────────────────────────────────────────
foreach ($cmd in 'hyperfine', 'starship') {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "ERROR: $cmd not found — install it first"; exit 1
    }
}

Write-Log "Platform:  Windows"
Write-Log "Profile:   $StarshipProfile"
Write-Log "Plain dir: $PlainDir"
Write-Log "Git dir:   $GitDir"

# ─── 1. pwsh startup — no profile ────────────────────────────────────────────
Write-Log "Measuring pwsh startup (no profile)..."
hyperfine --warmup 3 --runs 20 `
    --export-json "$env:TEMP\bench-startup-noprofile.json" `
    'pwsh -NoProfile -Command exit' 2>$null

# ─── 2. pwsh startup — with profile ──────────────────────────────────────────
Write-Log "Measuring pwsh startup (with profile)..."
hyperfine --warmup 3 --runs 20 `
    --export-json "$env:TEMP\bench-startup-profile.json" `
    'pwsh -Command exit' 2>$null

# ─── 3. Prompt render — plain dir ────────────────────────────────────────────
Write-Log "Measuring prompt render in plain dir..."
Set-Location $PlainDir
$plainSamples = 1..20 | ForEach-Object { (Measure-Command { starship prompt }).TotalMilliseconds }

# ─── 4. Prompt render — git dir ──────────────────────────────────────────────
Write-Log "Measuring prompt render in git dir..."
Set-Location $GitDir
$gitSamples = 1..20 | ForEach-Object { (Measure-Command { starship prompt }).TotalMilliseconds }

# ─── 5. starship module timings ──────────────────────────────────────────────
Write-Log "Capturing starship module timings..."
Set-Location $GitDir
$timings = (& starship timings 2>&1) | Out-String

# ─── 6. Parse and write results ──────────────────────────────────────────────
Write-Log "Writing results to $Output..."

$startupNoProfile = Get-Mean "$env:TEMP\bench-startup-noprofile.json"
$startupProfile   = Get-Mean "$env:TEMP\bench-startup-profile.json"

$plainAvg  = [math]::Round(($plainSamples | Measure-Object -Average).Average, 1)
$plainStd  = [math]::Round(($plainSamples | Measure-Object -StandardDeviation).StandardDeviation, 1)
$gitAvg    = [math]::Round(($gitSamples   | Measure-Object -Average).Average, 1)
$gitStd    = [math]::Round(($gitSamples   | Measure-Object -StandardDeviation).StandardDeviation, 1)

$pwshVer    = $PSVersionTable.PSVersion.ToString()
$starVer    = (& starship --version).Split()[1]

$result = [ordered]@{
    platform                    = "windows"
    profile                     = $StarshipProfile
    shell                       = "pwsh"
    pwsh_version                = $pwshVer
    starship_version            = $starVer
    startup_noprofile_ms        = $startupNoProfile[0]
    startup_noprofile_stddev_ms = $startupNoProfile[1]
    startup_ms                  = $startupProfile[0]
    startup_stddev_ms           = $startupProfile[1]
    prompt_plain_ms             = $plainAvg
    prompt_plain_stddev_ms      = $plainStd
    prompt_git_ms               = $gitAvg
    prompt_git_stddev_ms        = $gitStd
    git_overhead_ms             = [math]::Round($gitAvg - $plainAvg, 1)
    starship_timings            = $timings.Trim()
    thresholds                  = [ordered]@{
        startup_excellent_ms        = 400
        startup_slow_ms             = 1000
        prompt_render_excellent_ms  = 20
        prompt_render_slow_ms       = 100
    }
}

$result | ConvertTo-Json -Depth 5 | Set-Content $Output -Encoding UTF8

Write-Host ""
Write-Host ("─" * 52) -ForegroundColor DarkGray
Write-Host ("  Profile:                    $StarshipProfile")
Write-Host ("  pwsh startup (no profile): {0} ms  (±{1})" -f $startupNoProfile[0], $startupNoProfile[1])
Write-Host ("  pwsh startup (w/ profile): {0} ms  (±{1})" -f $startupProfile[0], $startupProfile[1])
Write-Host ("  prompt (plain dir):        {0} ms  (±{1})" -f $plainAvg, $plainStd)
Write-Host ("  prompt (git dir):          {0} ms  (±{1})" -f $gitAvg, $gitStd)
Write-Host ("  git overhead:              {0} ms"          -f ($gitAvg - $plainAvg))
Write-Host ("─" * 52) -ForegroundColor DarkGray
Write-Host ("  Results written to: $Output")
Write-Host ("─" * 52) -ForegroundColor DarkGray
Write-Host ""
