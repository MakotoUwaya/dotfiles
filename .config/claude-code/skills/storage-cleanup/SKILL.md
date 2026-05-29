---
name: storage-cleanup
description: ディスク空き容量を回収するためのストレージ整理。Claude Code の旧バージョン溜まり（.local/share/claude/versions）、RDP トレースログ、インストーラ/Updater 残骸、古い一時ファイルを安全に点検・削除する。Windows ネイティブと WSL2 の両方に対応。「ストレージ整理」「容量」「ディスク空き」「Claude 旧バージョン」「Temp 掃除」「Updater ゴミ」で使用。
---

# Storage Cleanup

## Overview

ディスクの空き容量が逼迫したときに、不要ファイルを点検・削除して容量を回収する。
特に **Claude Code の自動アップデートで旧バージョンの実体が消えずに溜まる**問題
（`~/.local/share/claude/versions/` に各 ~225MB ずつ蓄積）と、
OS が貯め込む一時ファイル・Updater 残骸を対象とする。

破壊的操作なので、**必ず scan（調査）→ ユーザー確認 → clean（削除）の順**で進める。

## When to Use

- 「ストレージ整理」「容量が足りない」「ディスク空きを増やしたい」
- 「Claude Code の古いバージョンが残っていないか点検して」
- 「Updater のゴミ・一時ファイルを消したい」

## Shell 別実行ガイド

| 環境 | scan | clean |
|------|------|-------|
| Windows ネイティブ (PowerShell) | `scripts/scan.ps1` | `scripts/clean.ps1` |
| WSL2 / Linux (bash) | `scripts/scan.sh` | `scripts/clean.sh` |

> このマシンの主環境は Windows ネイティブ（`claude.exe`）。WSL2 にも Claude Code を入れている場合は WSL 側でも `scan.sh` を実行して `versions/` 溜まりを点検する。

## Instructions

### 1. scan（調査・削除しない）

対象環境のスクリプトを実行し、回収見込みを把握する。

```powershell
# Windows
pwsh -NoProfile -File "$env:USERPROFILE\.claude\skills\storage-cleanup\scripts\scan.ps1"
```

```bash
# WSL2 / Linux
bash ~/.claude/skills/storage-cleanup/scripts/scan.sh
```

scan は以下を表示する（削除は一切しない）:

- **Claude 旧バージョン**: `versions/` 配下のうち現行（`claude --version`）以外
- **RDP トレースログ** (Windows): `%TEMP%\DiagOutputDir\RdClientAutoTrace` の `.etl`
- **インストーラ自己展開残骸** (Windows): `%TEMP%` 直下の `xxxxxxxx.xxx` 形式 DIR
- **Updater 残骸**: WinGet / VSCode updater / inno ログ など
- **古い一時ファイル**: 指定日数より前の `*.tmp`
- **未分類の大物 TOP**: 上記に当てはまらない大きい DIR/FILE（手動判断用）
- 各カテゴリの回収見込み MB とディスク空き容量

### 2. ユーザー確認

scan 結果を提示し、**どのカテゴリを削除するか** `AskUserQuestion`（multiSelect）で選ばせる。
「未分類の大物」は scan で出た実体を確認してから個別に判断する（clean では自動削除しない）。

### 3. clean（削除実行）

選ばれたカテゴリだけを `-Targets` で渡して削除する。`-WhatIf` で事前確認も可能。

```powershell
# Windows: 例) 旧バージョン + RDPトレース + Updater残骸を削除
pwsh -NoProfile -File "$env:USERPROFILE\.claude\skills\storage-cleanup\scripts\clean.ps1" `
  -Targets versions,rdp-trace,installer-cache,updater,old-tmp,claude-temp -TmpOlderThanDays 1
```

```bash
# WSL2 / Linux: 例) 旧バージョンを削除
bash ~/.claude/skills/storage-cleanup/scripts/clean.sh --versions
```

clean は削除前後でサイズを比較し、回収量とディスク空きの変化を出力する。

## Examples

### scan（Windows）の出力例

```
================ Storage Cleanup : SCAN ================
現行 Claude バージョン : 2.1.156

[1] Claude 旧バージョン  (C:\Users\...\.local\share\claude\versions)
  2.1.156         225.1 MB  <= 現行(保持)
  2.1.153         224.7 MB  削除候補
  2.1.152         224.4 MB  削除候補

[2] カテゴリ別 回収見込み
  versions              448.9 MB
  rdp-trace            2058.5 MB
  installer-cache      1006.4 MB
  ...
  (TOTAL)              3982.9 MB  <= 合計

C: 空き 58.4 GB / 全 473.9 GB
```

### clean（Windows）の出力例

```
> clean.ps1 -Targets versions,rdp-trace,installer-cache,updater,old-tmp,claude-temp

[versions] 現行 2.1.156 を保持、それ以外を削除
削除対象 19 件 / 回収見込み 3982.9 MB
削除 19/19 件
Temp 回収    : 3982.9 MB
C: 空き 変化 : 58.9 GB -> 62.8 GB
```

### WSL2 で旧バージョンだけ dry-run 確認 → 削除

```
$ bash clean.sh --versions --dry-run
[versions] 現行 2.1.156 を保持、それ以外を削除
  [dry-run] rm -rf /home/user/.local/share/claude/versions/2.1.153
$ bash clean.sh --versions
  削除: /home/user/.local/share/claude/versions/2.1.153
空き変化: 40 GB -> 41 GB (+896 MB)
```

## Guidelines

- **現行バージョンは絶対に残す**: clean は `claude --version` を検出し、それ以外の `versions/` のみ削除する。
- **現セッション・使用中ファイルは除外**: Claude の一時キャッシュは「今日 0:00 以降に更新されたもの」を残す。Outlook など起動中アプリのログは対象カテゴリに含めない。使用中でロックされたファイルは自動スキップ（`-ErrorAction SilentlyContinue` / `2>/dev/null`）。
- **未分類の大物は自動削除しない**: scan で提示し、中身を確認してからユーザー判断で個別削除する。
- **削除は冪等・安全側**: 既に無いパスはスキップ。`-WhatIf`（PowerShell）/ `--dry-run`（bash）で必ず事前確認できる。
- 定期メンテとして、RDP トレースログ（使うたびに増える）と Claude 旧バージョンは再蓄積するため、繰り返し実行する想定。

## Notes

- 既知の容量食いランキング（実測例 2026-05）: RDP トレース 2GB > インストーラ残骸15個 1GB > Claude旧バージョン 0.45GB > VS拡張一時 0.3GB。
- Claude Code の旧バージョンは Windows では `~/.local/share/claude/versions/`、`claude.exe` 本体は `~/.local/bin/`。WSL/Linux も `~/.local/share/claude/versions/`。
