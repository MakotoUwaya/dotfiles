#Requires -RunAsAdministrator
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$binDir = Get-Item (Split-Path -Parent $MyInvocation.MyCommand.Path)
$realBinPath = $binDir.LinkTarget ?? $binDir.FullName
$dotdir = Split-Path -Parent $realBinPath
$backupDir = Join-Path $HOME '.dotbackup'

function Write-Step {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Backup-Item {
    param([string]$Path)
    if (-not (Test-Path $backupDir)) {
        Write-Debug "$backupDir not found. Auto Make it"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    $name = Split-Path -Leaf $Path
    $dest = Join-Path $backupDir $name
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
    }
    Move-Item -Path $Path -Destination $backupDir -Force
    Write-Debug "Backed up: $Path -> $backupDir"
}

function New-SymLink {
    param(
        [string]$LinkPath,
        [string]$TargetPath,
        [switch]$IsDirectory
    )

    # Guard: skip if LinkPath and TargetPath resolve to the same path
    $resolvedLink = Join-Path (Resolve-Path (Split-Path -Parent $LinkPath)).Path (Split-Path -Leaf $LinkPath)
    $resolvedTarget = (Resolve-Path $TargetPath -ErrorAction SilentlyContinue).Path
    if ($resolvedTarget -and ($resolvedLink -eq $resolvedTarget)) {
        Write-Step "  Skipping (same path): $LinkPath"
        return
    }

    $parentDir = Split-Path -Parent $LinkPath
    if (-not (Test-Path $parentDir)) {
        Write-Debug "Creating parent directory: $parentDir"
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if (Test-Path $LinkPath) {
        $item = Get-Item $LinkPath -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Debug "Removing existing symlink: $LinkPath"
            $item.Delete()
        } else {
            Write-Debug "Backing up existing item: $LinkPath"
            Backup-Item $LinkPath
        }
    }

    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath -Force | Out-Null
    Write-Debug "Linked: $LinkPath -> $TargetPath"
    Write-Step "  $LinkPath -> $TargetPath"
}

# --- Main ---
Write-Step 'Starting Windows dotfiles installation...'
Write-Step "Dotfiles directory: $dotdir"

# Symlink: PowerShell profile
Write-Step 'Creating symlinks...'
New-SymLink -LinkPath (Join-Path $HOME 'Documents\PowerShell') `
            -TargetPath (Join-Path $dotdir 'PowerShell') `
            -IsDirectory

# Symlink: Neovim config
New-SymLink -LinkPath (Join-Path $env:LOCALAPPDATA 'nvim') `
            -TargetPath (Join-Path $dotdir '.config\nvim') `
            -IsDirectory

# Symlink: Nushell config
New-SymLink -LinkPath (Join-Path $env:APPDATA 'nushell') `
            -TargetPath (Join-Path $dotdir '.config\nushell') `
            -IsDirectory

# Symlink: mise config
New-SymLink -LinkPath (Join-Path $HOME '.config\mise') `
            -TargetPath (Join-Path $dotdir '.config\mise') `
            -IsDirectory

# Symlink: bunfig.toml (bun cooldown)
New-SymLink -LinkPath (Join-Path $HOME '.bunfig.toml') `
            -TargetPath (Join-Path $dotdir '.bunfig.toml')

# Symlink: ripgreprc
New-SymLink -LinkPath (Join-Path $HOME '.ripgreprc') `
            -TargetPath (Join-Path $dotdir '.ripgreprc')

# Symlink: AWS CLI config (SSO profiles). ~/.aws/sso, ~/.aws/cli はローカルのまま残す
New-SymLink -LinkPath (Join-Path $HOME '.aws\config') `
            -TargetPath (Join-Path $dotdir '.aws\config')

# Symlink: Claude Code CLAUDE.md (global)
New-SymLink -LinkPath (Join-Path $HOME '.claude\CLAUDE.md') `
            -TargetPath (Join-Path $dotdir '.config\claude-code\CLAUDE.md')

# Symlink: Claude Code settings
New-SymLink -LinkPath (Join-Path $HOME '.claude\settings.json') `
            -TargetPath (Join-Path $dotdir '.config\claude-code\settings.json')

# Symlink: Claude Code rules
New-SymLink -LinkPath (Join-Path $HOME '.claude\rules') `
            -TargetPath (Join-Path $dotdir '.config\claude-code\rules') `
            -IsDirectory

# Symlink: Claude Code skills
New-SymLink -LinkPath (Join-Path $HOME '.claude\skills') `
            -TargetPath (Join-Path $dotdir '.config\claude-code\skills') `
            -IsDirectory

# Symlink: .bin
New-SymLink -LinkPath (Join-Path $HOME '.bin') `
            -TargetPath (Join-Path $dotdir '.bin') `
            -IsDirectory

# Symlink: .wslconfig (WSL2 resource settings)
New-SymLink -LinkPath (Join-Path $HOME '.wslconfig') `
            -TargetPath (Join-Path $dotdir '.wslconfig')

# Symlink: Herdr config
New-SymLink -LinkPath (Join-Path $env:APPDATA 'herdr\config.toml') `
            -TargetPath (Join-Path $dotdir 'herdr\config.toml')

# Symlink: Warp keybindings
New-SymLink -LinkPath (Join-Path $env:LOCALAPPDATA 'warp\Warp\config\keybindings.yaml') `
            -TargetPath (Join-Path $dotdir 'warp\keybindings.yaml')

# Symlink: Warp workflows
New-SymLink -LinkPath (Join-Path $env:APPDATA 'warp\Warp\data\workflows') `
            -TargetPath (Join-Path $dotdir 'warp\workflows') `
            -IsDirectory

# winget import
Write-Step 'Importing winget packages...'
$wingetFile = Join-Path $dotdir 'winget\settings.json'
if (Test-Path $wingetFile) {
    winget import $wingetFile
} else {
    Write-Warning "winget settings not found: $wingetFile"
}

Write-Host ''
Write-Host ' Install completed!!!! ' -ForegroundColor Cyan
