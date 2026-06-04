<#
.SYNOPSIS
  ストレージ整理の調査（削除しない）。Claude 旧バージョン・RDP トレース・
  インストーラ残骸・Updater 残骸・古い一時ファイル・未分類の大物を一覧する。
.NOTES
  storage-cleanup skill / scan phase. 削除は clean.ps1 で行う。
#>
[CmdletBinding()]
param(
  [int]$TmpOlderThanDays = 1,
  [int]$TopN = 15
)

$ErrorActionPreference = 'SilentlyContinue'

function Get-Size([string]$path) {
  if (-not (Test-Path $path)) { return $null }
  $item = Get-Item $path -Force
  if ($item.PSIsContainer) {
    $s = (Get-ChildItem $path -Recurse -Force -File | Measure-Object -Sum Length).Sum
  } else { $s = $item.Length }
  if ($null -eq $s) { 0 } else { $s }
}
function MB([double]$bytes) { [math]::Round($bytes / 1MB, 1) }

$temp = $env:TEMP
$versionsDir = "$env:USERPROFILE\.local\share\claude\versions"

# 現行 Claude バージョン
$current = $null
$ver = (& claude --version) 2>$null
if ($ver -match '(\d+\.\d+\.\d+)') { $current = $Matches[1] }

$report = [ordered]@{}

Write-Output "================ Storage Cleanup : SCAN ================"
Write-Output ("現行 Claude バージョン : {0}" -f ($current ?? '(検出不可)'))

# --- 1) Claude 旧バージョン ---
Write-Output "`n[1] Claude 旧バージョン  ($versionsDir)"
$verReclaim = 0
if (Test-Path $versionsDir) {
  # Windows は versions/<ver> が exe ファイル、Linux はディレクトリ。両対応で列挙。
  Get-ChildItem $versionsDir -Force | ForEach-Object {
    $sz = Get-Size $_.FullName
    $isCurrent = ($_.Name -eq $current)
    if (-not $isCurrent) { $verReclaim += $sz }
    $tag = if ($isCurrent) { '<= 現行(保持)' } else { '削除候補' }
    Write-Output ("  {0,-12} {1,8} MB  {2}" -f $_.Name, (MB $sz), $tag)
  }
} else { Write-Output "  (versions ディレクトリなし)" }
$report['versions'] = $verReclaim

# --- 2) RDP トレースログ ---
$rdp = "$temp\DiagOutputDir"
$rdpSz = if (Test-Path $rdp) { Get-Size $rdp } else { 0 }
$report['rdp-trace'] = $rdpSz

# --- 3) インストーラ自己展開残骸 (xxxxxxxx.xxx 形式 DIR) ---
$instDirs = Get-ChildItem $temp -Directory -Force | Where-Object { $_.Name -match '^[a-z0-9]{8}\.[a-z0-9]{3}$' }
$instSz = ($instDirs | ForEach-Object { Get-Size $_.FullName } | Measure-Object -Sum).Sum
$report['installer-cache'] = ($instSz ?? 0)

# --- 4) Updater 残骸 ---
$updTargets = @()
foreach ($n in @('WinGet','vscode-stable-user-x64')) {
  if (Test-Path "$temp\$n") { $updTargets += (Get-Item "$temp\$n") }
}
$updTargets += Get-ChildItem $temp -Force | Where-Object { $_.Name -match '(?i)updater|^vscode-inno-updater-.*\.log$' }
$updSz = ($updTargets | ForEach-Object { Get-Size $_.FullName } | Measure-Object -Sum).Sum
$report['updater'] = ($updSz ?? 0)

# --- 5) 古い一時ファイル (*.tmp, N日より前) ---
$cut = (Get-Date).Date.AddDays(-([math]::Max(0,$TmpOlderThanDays-1)))
$oldTmp = Get-ChildItem $temp -File -Force | Where-Object { $_.Name -match '\.tmp$' -and $_.LastWriteTime -lt $cut }
$tmpSz = ($oldTmp | Measure-Object -Sum Length).Sum
$report['old-tmp'] = ($tmpSz ?? 0)

# --- 6) Claude 一時キャッシュ (今日 0:00 より前) ---
$today0 = (Get-Date).Date
$claudeTmp = Get-ChildItem "$temp\claude" -Force | Where-Object { $_.LastWriteTime -lt $today0 }
$ctSz = ($claudeTmp | ForEach-Object { Get-Size $_.FullName } | Measure-Object -Sum).Sum
$report['claude-temp'] = ($ctSz ?? 0)

# --- 7) Claude Desktop vm_bundles (claudevm のローカル VM イメージ / Windows 専用) ---
# ローカルコード実行サンドボックスの .vhdx 等。再蓄積し十数GB規模に膨らむ。削除は clean.ps1 -Targets vm_bundles で明示指定時のみ。
$vmb = "$env:APPDATA\Claude\vm_bundles"
$vmbSz = if (Test-Path $vmb) { Get-Size $vmb } else { 0 }
$report['vm_bundles'] = $vmbSz

Write-Output "`n[2] カテゴリ別 回収見込み"
$total = 0
foreach ($k in $report.Keys) {
  $total += $report[$k]
  "  {0,-18} {1,8} MB" -f $k, (MB $report[$k])
}
"  {0,-18} {1,8} MB  <= 合計" -f '(TOTAL)', (MB $total)

# --- 未分類の大物 TOP ---
Write-Output "`n[3] %TEMP% 大物 TOP$TopN（未分類含む・手動判断用）"
Get-ChildItem $temp -Force |
  Select-Object Name,
    @{n='MB';e={ MB (Get-Size $_.FullName) }},
    LastWriteTime,
    @{n='Type';e={ if ($_.PSIsContainer) { 'DIR' } else { 'FILE' } }} |
  Sort-Object MB -Descending | Select-Object -First $TopN | Format-Table -AutoSize | Out-String | Write-Output

# --- ディスク空き ---
$c = Get-PSDrive C
Write-Output ("C: 空き {0} GB / 全 {1} GB" -f [math]::Round($c.Free/1GB,1), [math]::Round(($c.Used+$c.Free)/1GB,1))
Write-Output "========================================================"
Write-Output "削除は clean.ps1 -Targets <カテゴリ> で実行（-WhatIf で事前確認）"
