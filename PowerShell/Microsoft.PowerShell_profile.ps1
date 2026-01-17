# Alias
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name touch -Value New-Item
Set-Alias -Name vim -Value nvim
Set-Alias -Name gg -Value lazygit

# mise
$miseInit = (mise activate pwsh | Out-String)
if (-not [string]::IsNullOrWhiteSpace($miseInit)) {
    Invoke-Expression $miseInit
}

# Starship
function Invoke-Starship-PreCommand {
  $loc = $executionContext.SessionState.Path.CurrentLocation;
  $prompt = "$([char]27)]9;12$([char]7)"
  if ($loc.Provider.Name -eq "FileSystem")
  {
    $prompt += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
  }
  $host.ui.Write($prompt)
}
Invoke-Expression (&starship init powershell)

# base64
function base64(){
    Param([switch]$e=$true, [switch]$d=$false, [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$input)
    Begin{}
    Process{
        if($d){
            $byte = [System.Convert]::FromBase64String($input)
            $txt = [System.Text.Encoding]::Default.GetString($byte)
            echo $txt
        }
        elseif($e){
            $byte = ([System.Text.Encoding]::Default).GetBytes($input)
            $b64enc = [Convert]::ToBase64String($byte)
            echo $b64enc
        }
    }
    End{}
}

# Safe-chain PowerShell initialization script
. "$HOME\.safe-chain\scripts\init-pwsh.ps1"

# fzf
$env:FZF_PREVIEW_SCRIPT_PATH = "$env:USERPROFILE\Documents\PowerShell\fzf-preview.ps1".Replace('\', '/')
$env:FZF_DEFAULT_OPTS="--prompt='QUERY> ' --height 60% --layout reverse --border=rounded --style full"
$env:FZF_CTRL_T_OPTS="--height 100% --preview ""pwsh -NoProfile -File \""$env:FZF_PREVIEW_SCRIPT_PATH\"" {}"" --bind 'focus:transform-header:file --brief {}'"
$env:FZF_ALT_C_OPTS="--height 100% --preview ""pwsh -NoProfile -File \""$env:FZF_PREVIEW_SCRIPT_PATH\"" {}"" --bind 'focus:transform-header:file --brief {}'"

# ghq
function Set-GhqLocation {
    $ghqRoot = ghq root
    $selectedRelDir = ghq list | fzf -e
    if (-not [string]::IsNullOrWhiteSpace($selectedRelDir)) {
        $fullPath = Join-Path -Path $ghqRoot -ChildPath $selectedRelDir
        if (Test-Path $fullPath) {
            Set-Location -Path $fullPath
        }
    }
}
Set-Alias gitdir Set-GhqLocation

# File edit 
function Select-EditFile {
    $selectedFile = fd --type f --strip-cwd-prefix | fzf --height 100% -e --preview "pwsh -NoProfile -File ""$env:FZF_PREVIEW_SCRIPT_PATH"" {}" --bind 'focus:transform-header:file --brief {}'
    if (-not [string]::IsNullOrWhiteSpace($selectedFile)) {
        if (Test-Path $selectedFile) {
            nvim $selectedFile
        }
    }
}
Set-Alias sef Select-EditFile

# KeyBinding
## PSReadline
## https://zenn.dev/microsoft/articles/powershell-linux-key-bindings
Import-Module PSReadline
Set-PSReadLineOption -EditMode Emacs

## コマンド履歴の除外条件設定
Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$line)
    if ($line -match '^\s') { return $false }
    return $true
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+g' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(" gitdir")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

## Grep検索
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

    if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
        Write-Warning "Error: 'rg' command not found."
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        return
    }

    $rgCmd = "rg --column --line-number --no-heading --color=always --smart-case --hidden --invert-match '^\s*$' ."
    $fzfCmd = "fzf --ansi --delimiter : --height 100% --layout reverse --border rounded"

    try {
        $result = Invoke-Expression "$rgCmd | $fzfCmd"
        if (-not [string]::IsNullOrWhiteSpace($result)) {
            if ($result -match '^(.+?):(\d+):') {
                $file = $Matches[1]
                $line = $Matches[2]
                
                $editorCommand = " nvim '$file' +$line"
                
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($editorCommand)
                [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
            }
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        }
    }
    catch {
        Write-Error $_
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}

## PSFzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'

Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
    $command = "fd --type d --color=never"

    $currentOpts = $env:FZF_DEFAULT_OPTS
    $env:FZF_DEFAULT_OPTS = $currentOpts + " " + $env:FZF_ALT_C_OPTS

    $dir = $null
    try {
        $dir = Invoke-Expression $command | fzf
    } finally {
        $env:FZF_DEFAULT_OPTS = $currentOpts
    }

    if ($dir) {
        Set-Location $dir
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}

# Podman
# function Start-PodmanMachine {
#     if (!(Get-Command podman -ErrorAction SilentlyContinue)) { return }
#     try {
#         $m = podman machine list --format json | ConvertFrom-Json
#         if ($m -and !($m | Where-Object { $_.Default -eq $true }).Running) {
#             podman machine start
#         }
#     } catch {
#         Write-Host "Error: Failed to start Podman machine." -ForegroundColor Red
#     }
# }
# Start-PodmanMachine

