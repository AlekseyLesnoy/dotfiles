# bootstrap/lib/state.ps1 — State file + registry run-key helpers (Windows)
# Requires -Version 7.0

$StateFile = Join-Path $env:USERPROFILE '.dotfile-bootstrap-state.ini'

function Set-BootstrapState {
    param(
        [string]$Key,
        [string]$Value
    )
    $lines = @()
    if (Test-Path $StateFile) {
        $lines = Get-Content $StateFile | Where-Object { $_ -notmatch "^${Key}=" }
    }
    $lines += "${Key}=${Value}"
    $lines | Set-Content $StateFile -Encoding UTF8
}

function Get-BootstrapState {
    param([string]$Key)
    if (Test-Path $StateFile) {
        $line = Get-Content $StateFile | Where-Object { $_ -match "^${Key}=" } | Select-Object -First 1
        if ($line) {
            return $line.Split('=', 2)[1]
        }
    }
    return $null
}

function Clear-BootstrapState {
    if (Test-Path $StateFile) {
        Remove-Item $StateFile -Force
    }
}

function Set-PhaseComplete {
    param([string]$Phase)
    Set-BootstrapState -Key "phase_${Phase}" -Value 'done'
}

function Test-PhaseComplete {
    param([string]$Phase)
    return (Get-BootstrapState -Key "phase_${Phase}") -eq 'done'
}

# ─── Registry run-key helpers ─────────────────────────────────────────────────

$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RunKeyName = 'DotfileBootstrapResume'

function Register-BootstrapResume {
    param([string]$ScriptPath)
    $cmd = "pwsh -NoProfile -ExecutionPolicy Bypass -File `"${ScriptPath}`" -Resume"
    Set-ItemProperty -Path $RunKeyPath -Name $RunKeyName -Value $cmd -Type String
    Write-Host "[state] Registered resume key: $cmd"
}

function Unregister-BootstrapResume {
    if (Get-ItemProperty -Path $RunKeyPath -Name $RunKeyName -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $RunKeyPath -Name $RunKeyName
        Write-Host "[state] Removed resume registry key."
    }
}
