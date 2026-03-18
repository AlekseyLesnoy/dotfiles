# bootstrap/lib/install-op.ps1 — Install 1Password CLI on Windows via winget
# Idempotent: skips if op.exe already available
#Requires -Version 7.0

function Install-Op {
    if (Get-Command op -ErrorAction SilentlyContinue) {
        $ver = & op --version 2>&1
        Write-Host "[op] Already installed ($ver). Skipping."
        return
    }

    Write-Host "[op] Installing 1Password CLI via winget..."
    winget install --id AgileBits.1Password.CLI --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        # -1978335189 = APPINSTALLER_ERROR_ALREADY_INSTALLED (winget code)
        throw "[op] winget install failed with exit code $LASTEXITCODE"
    }

    # Refresh PATH so op.exe is found in this session
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'User')

    if (Get-Command op -ErrorAction SilentlyContinue) {
        $ver = & op --version 2>&1
        Write-Host "[op] Installed successfully ($ver)."
    }
    else {
        Write-Warning "[op] Installed but 'op' not yet in PATH. A new terminal session may be required."
    }
}

Install-Op
