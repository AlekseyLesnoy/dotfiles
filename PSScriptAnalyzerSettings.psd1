@{
    ExcludeRules = @(
        # Bootstrap scripts use Write-Host intentionally for colored interactive terminal output.
        'PSAvoidUsingWriteHost',

        # Internal bootstrap helpers are not public API — ShouldProcess adds noise with no benefit.
        'PSUseShouldProcessForStateChangingFunctions',

        # UTF-8 without BOM is the cross-platform standard. BOM causes issues on Linux/macOS.
        'PSUseBOMForUnicodeEncodedFile'
    )
}
