Import-Module -Name Terminal-Icons
Import-Module z
if ($host.Name -eq 'ConsoleHost')
{
    Import-Module PSReadLine
}

# PSReadLine Settings
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView # Requires >Install-Module PSReadLine -AllowPrerelease -Force
Set-PSReadLineOption -EditMode Windows # Has to be set before we load oh-my-posh, otherwise transient prompt feateure doesn't work

oh-my-posh init pwsh --config C:\Users\aleksey.lesnoy\Dropbox\Other\Backups\PC\Windows\OhMyPosh\al-05-2022.omp.json | Invoke-Expression
#oh-my-posh init pwsh --config C:\Users\aleksey.lesnoy\Dropbox\Other\Backups\PC\Windows\OhMyPosh\zen.toml | Invoke-Expression
#op completion powershell | Out-String | Invoke-Expression

if ((Get-Location).Path -eq 'C:\Windows\System32')
{
    Set-Location ~
}

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
     param($commandName, $wordToComplete, $cursorPosition)
         dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
         }
}

# Function to relaunch as Admin
function Invoke-Admin { Start-Process -Verb RunAs (Get-Process -Id $PID).Path }

function Update-Profile {
    @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    ) | ForEach-Object {
        if(Test-Path $_){
            Write-Verbose "Running $_"
            . $_
        }
    }
}

# Create a new directory and enter it
function New-DirectoryAndSet([String] $path) { New-Item $path -ItemType Directory -ErrorAction SilentlyContinue; Set-Location $path}

function Find-BinaryPath([String] $binary) { Get-Command $binary | Select-Object -ExpandProperty Source }

function time { $Command = "$args"; Measure-Command { Invoke-Expression $Command 2>&1 | out-default} }

# Determine size of a file or total size of a directory
function Get-DiskUsage([string] $path=(Get-Location).Path) {
    Convert-ToDiskSize `
        ( `
            Get-ChildItem .\ -recurse -ErrorAction SilentlyContinue `
            | Measure-Object -property length -sum -ErrorAction SilentlyContinue
        ).Sum `
        1
}

function Convert-ToDiskSize {
    param ( $bytes, $precision='0' )
    foreach ($size in ("B","K","M","G","T")) {
        if (($bytes -lt 1000) -or ($size -eq "T")){
            $bytes = ($bytes).tostring("F0" + "$precision")
            return "${bytes}${size}"
        }
        else { $bytes /= 1KB }
    }
}

function Edit-Hosts {
    Invoke-Expression "sudo $(if($env:EDITOR -ne $null) {$env:EDITOR} else { 'notepad' }) $env:windir\system32\drivers\etc\hosts"
}

function Edit-Profile {
    Invoke-Expression "$(if($env:EDITOR -ne $null) {$env:EDITOR } else { 'notepad' }) $profile"
}

function sudo() {
    if ($args.Length -eq 1) {
        start-process $args[0] -verb "runAs"
    }
    if ($args.Length -gt 1) {
        start-process $args[0] -ArgumentList $args[1..$args.Length] -verb "runAs"
    }
}

# Easier Navigation: .., ..., ...., ....., and ~
${function:~} = { Set-Location ~ }
# Posh won't allow ${function:..} because of an invalid path error, so...
${function:Set-ParentLocation} = { Set-Location .. }; Set-Alias ".." Set-ParentLocation
${function:...} = { Set-Location ..\.. }
${function:....} = { Set-Location ..\..\.. }
${function:.....} = { Set-Location ..\..\..\.. }
${function:......} = { Set-Location ..\..\..\..\.. }

# Navigation Shortcuts
${function:dr} = { Set-Location ~\Dropbox }
${function:dt} = { Set-Location ~\Desktop }
${function:docs} = { Set-Location ~\Documents }
${function:dd} = { Set-Location C:\Projects\OneStore\tools\docker }
${function:p} = { Set-Location C:\Projects }
${function:pos} = { Set-Location C:\Projects\OneStore }
${function:d} = { Set-Location ~\Downloads }
# Copilot CLI
# function ?? {
#     param([string]$query)
#     gh copilot suggest "$query"
# }
# function gcs? {
#     param([string]$query)
#     gh copilot suggest "$query"
# }
# function gce? {
#     param([string]$query)
#     gh copilot explain "$query"
# }

# Correct PowerShell Aliases if tools are available (aliases win if set)
# WGet: Use `ls.exe` if available
if (Get-Command wget.exe -ErrorAction SilentlyContinue | Test-Path) {
  Remove-Item alias:wget
}

# Directory Listing: Use `ls.exe` if available
if (Get-Command ls.exe -ErrorAction SilentlyContinue | Test-Path) {
    Remove-Item alias:ls
    # Set `ls` to call `ls.exe` and always use --color
    ${function:ls} = { ls.exe --color @args }
    # List all files in long format
    ${function:l} = { ls -lF @args }
    # List all files in long format, including hidden files
    ${function:la} = { ls -laF @args }
    # List only directories
    ${function:lsd} = { Get-ChildItem -Directory -Force @args }
} else {
    # List all files, including hidden files
    ${function:la} = { ls -Force @args }
    # List only directories
    ${function:lsd} = { Get-ChildItem -Directory -Force @args }
}

# Missing Bash aliases
Set-Alias mkd New-DirectoryAndSet
Set-Alias g git
#Set-Alias reload Reload-Powershell
Set-Alias reload Update-Profile
Set-Alias admin Invoke-Admin
Set-Alias tf terraform
Set-Alias which Find-BinaryPath
Set-Alias hosts Edit-Hosts
Set-Alias profile Edit-Profile

$env:PYTHONIOENCODING="utf-8"
$env:THEFUCK_NO_COLORS="true"
$env:EDITOR="code"
#Invoke-Expression "$(thefuck --alias)"

# PSReadLine Macros
Set-PSReadLineKeyHandler -Key Ctrl+Shift+b `
                         -BriefDescription BuildCurrentDirectory `
                         -LongDescription "Build the current directory" `
                         -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet build")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# Requires > Install-Module -Name PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PsFzfOption -TabExpansion

. C:\Users\aleksey.lesnoy\Documents\PowerShell\gh-copilot.ps1
#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58
