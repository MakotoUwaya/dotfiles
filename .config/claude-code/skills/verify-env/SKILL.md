---
name: verify-env
description: >-
  dotfiles の install 実行後や、シンボリックリンク・環境設定に起因する問題
  （設定が反映されない、ファイルが見つからない、パスが通らない等）が
  発生した際に自動適用される。
  シンボリックリンクの整合性と設定ファイルの状態を OS に応じて検証する。
user-invocable: false
---

# 環境設定検証

## Overview

dotfiles のシンボリックリンクが正しく張られているか、リンク先が存在するかを検証する。
install スクリプト実行後の確認や、設定が反映されない問題の切り分けに使用する。

## When to Use

- dotfiles の install スクリプト実行後の動作確認
- シンボリックリンクに起因する問題（設定が反映されない、ファイルが見つからない等）の切り分け
- 環境セットアップの健全性チェック

## Instructions

### OS 判定

Bash ツールで `uname -s` を実行し、OS を判定する。

- `Linux` → Linux/WSL 検証項目を実行
- それ以外（Windows 上の Claude Code）→ Windows 検証項目を実行

### 検証対象の取得（重要）

**install スクリプトを唯一の正（Single Source of Truth）とする。** SKILL.md に静的リストを持たない。

#### Linux/WSL の場合

`$DOTDIR/.bin/install.sh` から `make_symlink` 呼び出しを抽出する。

```bash
grep 'make_symlink ' "$DOTDIR/.bin/install.sh" | sed 's/.*make_symlink //' | tr -d '"'
```

各行は `<link_path> <target_path>` の形式。`$HOME` と `$DOTDIR` を実際のパスに展開して使用する。

#### Windows の場合

`$DOTDIR/.bin/install.ps1` から `New-SymLink -LinkPath ... -TargetPath ...` 呼び出しを抽出する。
PowerShell の `Join-Path` や行継続（バッククォート）を考慮してパースする。

**注意:** `install.ps1` にはシンボリックリンク以外の処理（`Copy-Item` 等）も含まれる。`New-SymLink` 呼び出しのみを検証対象とすること。

### `~/.config/` 配下の特殊処理（Linux/WSL のみ）

`~/.config` 自体が `$DOTDIR/.config` へのシンボリックリンクになっている場合、
`~/.config/` 配下の個別リンクは実質的に同一パスを指すため `make_symlink` 側で skip される。

**検証順序:**
1. まず `~/.config` 自体がシンボリックリンクかを確認
2. シンボリックリンクの場合 → リンク先が `$DOTDIR/.config` であり、配下のファイルにアクセスできれば OK。個別リンクは「Skipped (same path)」として報告
3. 通常ディレクトリの場合 → install.sh から抽出した個別リンクを検証

### 検証ロジック

各リンクについて、以下の 3 点を検証する。

#### Linux/WSL の場合

```bash
# 1. シンボリックリンクであること
[ -L "$LINK" ]

# 2. リンク先が期待するパスであること
readlink -f "$LINK"

# 3. リンク先が実際に存在すること (dangling symlink でないこと)
[ -e "$LINK" ]
```

#### Windows の場合

```powershell
# 1. シンボリックリンク (ReparsePoint) であること
(Get-Item $Link -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint

# 2. リンク先が期待するパスであること
(Get-Item $Link -Force).Target

# 3. リンク先が実際に存在すること
Test-Path (Get-Item $Link -Force).Target
```

## Examples

検証結果を以下の形式で報告する。

```
## 検証結果

| # | リンクパス | 状態 | 詳細 |
|---|---|---|---|
| 1 | ~/.bashrc | OK | -> ~/ghq/.../dotfiles/.bashrc |
| 2 | ~/.config/nvim | Skipped | ~/.config 自体がシンボリックリンクのため個別リンク不要 |
| 3 | ~/.claude/CLAUDE.md | NG | missing: パス自体が存在しない |

**合計: 15 件中 13 件 OK / 1 件 Skipped / 1 件 NG**
```

NG の種類:
- **not_symlink** - パスは存在するがシンボリックリンクではない（通常ファイル/ディレクトリ）
- **wrong_target** - シンボリックリンクだがリンク先が期待と異なる
- **dangling** - シンボリックリンクだがリンク先が存在しない
- **missing** - パス自体が存在しない

## Guidelines

NG が検出された場合、以下の手順を提示する。

### 一括修復（推奨）

install スクリプトの再実行を案内する。既存のファイル/ディレクトリはバックアップ後にシンボリックリンクで置き換えられる。

- **Linux/WSL**: `~/.bin/install.sh` （dotfiles リポジトリ内の `.bin/install.sh`）
- **Windows**: 管理者権限の PowerShell で `.bin\install.ps1` を実行

### 個別修復

特定のリンクのみ修復する場合のコマンドを生成する。

**Linux/WSL:**
```bash
# 既存ファイルのバックアップ (通常ファイルの場合)
mv ~/.config/nvim ~/.dotbackup/nvim

# シンボリックリンク作成
ln -snf ~/ghq/github.com/MakotoUwaya/dotfiles/.config/nvim ~/.config/nvim
```

**Windows (管理者権限の PowerShell):**
```powershell
# 既存ファイルのバックアップ (通常ファイルの場合)
Move-Item $HOME\.config\nvim $HOME\.dotbackup\nvim -Force

# シンボリックリンク作成
New-Item -ItemType SymbolicLink -Path $HOME\.config\nvim -Target $dotdir\.config\nvim -Force
```
