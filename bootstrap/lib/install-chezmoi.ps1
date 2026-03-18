# bootstrap/lib/install-chezmoi.ps1 — Install chezmoi on Windows via winget
# Idempotent: skips if chezmoi.exe already available
#Requires -Version 7.0

function Install-Chezmoi {
    if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
        $ver = & chezmoi --version 2>&1 | Select-Object -First 1
        Write-Host "[chezmoi] Already installed ($ver). Skipping."
        return
    }

    Write-Host "[chezmoi] Installing chezmoi via winget..."
    winget install --id twpayne.chezmoi --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        throw "[chezmoi] winget install failed with exit code $LASTEXITCODE"
    }

    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'User')

    if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
        $ver = & chezmoi --version 2>&1 | Select-Object -First 1
        Write-Host "[chezmoi] Installed successfully ($ver)."
    }
    else {
        Write-Warning "[chezmoi] Installed but 'chezmoi' not yet in PATH. A new terminal session may be required."
    }
}

Install-Chezmoi
