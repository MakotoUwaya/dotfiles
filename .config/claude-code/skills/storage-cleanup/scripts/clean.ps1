<#
.SYNOPSIS
  ストレージ整理の削除実行。scan.ps1 のカテゴリ単位で削除する。
.PARAMETER Targets
  削除カテゴリ: versions, rdp-trace, installer-cache, updater, old-tmp, claude-temp, all
  vm_bundles (Claude Desktop の claudevm VM イメージ) は大物かつ再DLコストがあるため all に含めず、明示指定時のみ削除する。
.PARAMETER TmpOlderThanDays
  old-tmp で削除対象とする「N日より前」の閾値（既定 1 = 今日 0:00 より前）。
.PARAMETER WhatIf
  指定時は削除せず対象と回収見込みのみ表示。
.EXAMPLE
  clean.ps1 -Targets versions,rdp-trace,updater
  clean.ps1 -Targets all -WhatIf
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string[]]$Targets,
  [int]$TmpOlderThanDays = 1,
  [switch]$WhatIf
)

$ErrorActionPreference = 'SilentlyContinue'
$temp = $env:TEMP
$known = @('versions','rdp-trace','installer-cache','updater','old-tmp','claude-temp')
if ($Targets -contains 'all') { $Targets = $known }

function Get-Size([string]$p) {
  if (-not (Test-Path $p)) { return 0 }
  $i = Get-Item $p -Force
  $s = if ($i.PSIsContainer) { (Get-ChildItem $p -Recurse -Force -File | Measure-Object -Sum Length).Sum } else { $i.Length }
  if ($null -eq $s) { 0 } else { $s }
}
function MB([double]$b) { [math]::Round($b / 1MB, 1) }

# 削除対象パスを集める（実削除はまとめて最後に）
$paths = [System.Collections.Generic.List[string]]::new()

if ($Targets -contains 'versions') {
  $vdir = "$env:USERPROFILE\.local\share\claude\versions"
  $current = $null
  $ver = (& claude --version) 2>$null
  if ($ver -match '(\d+\.\d+\.\d+)') { $current = $Matches[1] }
  # Windows は exe ファイル、Linux はディレクトリ。両対応で現行以外を対象化。
  if (Test-Path $vdir) {
    Get-ChildItem $vdir -Force | Where-Object { $_.Name -ne $current } |
      ForEach-Object { $paths.Add($_.FullName) }
  }
  Write-Output ("[versions] 現行 {0} を保持、それ以外を削除" -f ($current ?? '?'))
}

if ($Targets -contains 'rdp-trace') {
  if (Test-Path "$temp\DiagOutputDir") { $paths.Add("$temp\DiagOutputDir") }
}

if ($Targets -contains 'installer-cache') {
  Get-ChildItem $temp -Directory -Force |
    Where-Object { $_.Name -match '^[a-z0-9]{8}\.[a-z0-9]{3}$' } |
    ForEach-Object { $paths.Add($_.FullName) }
}

if ($Targets -contains 'updater') {
  foreach ($n in @('WinGet','vscode-stable-user-x64')) {
    if (Test-Path "$temp\$n") { $paths.Add("$temp\$n") }
  }
  Get-ChildItem $temp -Force |
    Where-Object { $_.Name -match '(?i)updater|^vscode-inno-updater-.*\.log$' } |
    ForEach-Object { $paths.Add($_.FullName) }
}

if ($Targets -contains 'old-tmp') {
  $cut = (Get-Date).Date.AddDays(-([math]::Max(0, $TmpOlderThanDays - 1)))
  Get-ChildItem $temp -File -Force |
    Where-Object { $_.Name -match '\.tmp$' -and $_.LastWriteTime -lt $cut } |
    ForEach-Object { $paths.Add($_.FullName) }
}

if ($Targets -contains 'claude-temp') {
  # 今日 0:00 より前のものだけ（現セッション分を保護）
  $today0 = (Get-Date).Date
  Get-ChildItem "$temp\claude" -Force |
    Where-Object { $_.LastWriteTime -lt $today0 } |
    ForEach-Object { $paths.Add($_.FullName) }
}

if ($Targets -contains 'vm_bundles') {
  # Claude Desktop の claudevm ローカル VM イメージ。大物かつ再DLコストがあるため all には含めず、明示指定時のみ。
  $vmb = "$env:APPDATA\Claude\vm_bundles"
  if (Test-Path $vmb) {
    # vhdx がロック中 = claudevm VM 起動中。Desktop 完全終了が必要だが、本スクリプトを
    # Desktop 内蔵 Claude Code から実行していると Desktop 終了は自セッションを巻き込むため、
    # ロック検出時は削除せず警告のみとする。
    $locked = $false
    Get-ChildItem $vmb -Recurse -File -Force -Filter *.vhdx | ForEach-Object {
      try { $fs = [System.IO.File]::Open($_.FullName, 'Open', 'ReadWrite', 'None'); $fs.Close() }
      catch { $locked = $true }
    }
    if ($locked) {
      Write-Output "[vm_bundles] vhdx ロック中(claudevm VM 起動中)。Claude Desktop を完全終了してから再実行してください。今回はスキップ。"
    } else {
      $paths.Add($vmb)
      Write-Output "[vm_bundles] claudevm VM イメージを削除（UNLOCKED 確認済み・再蓄積するキャッシュ）"
    }
  }
}

# 集計
$before = (Get-ChildItem $temp -Recurse -Force -File | Measure-Object -Sum Length).Sum
$freeBefore = (Get-PSDrive C).Free
$plan = ($paths | ForEach-Object { Get-Size $_ } | Measure-Object -Sum).Sum

Write-Output ("`n削除対象 {0} 件 / 回収見込み {1} MB" -f $paths.Count, (MB $plan))
if ($WhatIf) {
  $paths | ForEach-Object { "  [WhatIf] {0,8} MB  {1}" -f (MB (Get-Size $_)), $_ }
  Write-Output "`n-WhatIf 指定のため削除しませんでした。"
  return
}

$deleted = 0
foreach ($p in $paths) {
  Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
  if (-not (Test-Path $p)) { $deleted++ } else { Write-Output ("  スキップ(使用中): {0}" -f $p) }
}

$after = (Get-ChildItem $temp -Recurse -Force -File | Measure-Object -Sum Length).Sum
$freeAfter = (Get-PSDrive C).Free
Write-Output ("`n削除 {0}/{1} 件" -f $deleted, $paths.Count)
Write-Output ("Temp 回収    : {0} MB" -f (MB ($before - $after)))
Write-Output ("C: 空き 変化 : {0} GB -> {1} GB" -f [math]::Round($freeBefore/1GB,1), [math]::Round($freeAfter/1GB,1))
