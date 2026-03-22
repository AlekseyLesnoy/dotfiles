@{
    ExcludeRules = @(
        # Bootstrap scripts use Write-Host intentionally for colored interactive terminal output.
        'PSAvoidUsingWriteHost',

        # Internal bootstrap helpers are not public API — ShouldProcess adds noise with no benefit.
        'PSUseShouldProcessForStateChangingFunctions',

        # UTF-8 without BOM is the cross-platform standard. BOM causes issues on Linux/macOS.
        'PSUseBOMForUnicodeEncodedFile',

        # Write-Log is used as a local logging helper across all scripts. PSScriptAnalyzer flags it
        # as overwriting a built-in cmdlet, but that cmdlet writes to Windows event logs — not stdout.
        # Plain .tmpl files are not linted so this only surfaces on plain .ps1 scripts.
        'PSAvoidOverwritingBuiltInCmdlets'
    )
}
