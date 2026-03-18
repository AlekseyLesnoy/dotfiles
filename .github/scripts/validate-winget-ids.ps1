# .github/scripts/validate-winget-ids.ps1
# Validates all winget package IDs in packages/*.yaml
#Requires -Version 7.0

$ErrorActionPreference = 'Continue'
$Failed = @()

$YamlFiles = Get-ChildItem -Path "packages" -Filter "*.yaml"

foreach ($file in $YamlFiles) {
    Write-Host "`nChecking $($file.Name)..."
    $ids = yq e '.winget.packages[].id' $file.FullName 2>$null
    foreach ($id in $ids) {
        if ([string]::IsNullOrWhiteSpace($id)) { continue }
        $result = winget show --id $id --exact 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  OK: $id"
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

Write-Host "`nAll winget IDs validated successfully."
