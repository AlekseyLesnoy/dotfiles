# .github/scripts/validate-winget-ids.ps1
# Validates all winget package IDs in packages/*.yaml
#Requires -Version 7.0

$ErrorActionPreference = 'Continue'
$Failed = @()

$YamlFiles = Get-ChildItem -Path "packages" -Filter "*.yaml"

foreach ($file in $YamlFiles) {
    Write-Output "`nChecking $($file.Name)..."
    $ids = yq e '.winget.packages[].id' $file.FullName 2>$null
    foreach ($id in $ids) {
        if ([string]::IsNullOrWhiteSpace($id)) { continue }
        winget show --id $id --exact 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "  OK: $id"
        }
        else {
            Write-Warning "  FAIL: $id — not found in winget"
            $Failed += $id
        }
    }
}

if ($Failed.Count -gt 0) {
    Write-Error "The following winget IDs are invalid or unavailable:`n$($Failed -join "`n")"
    exit 1
}

Write-Output "`nAll winget IDs validated successfully."
