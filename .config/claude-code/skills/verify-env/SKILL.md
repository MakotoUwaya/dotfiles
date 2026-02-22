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

dotfiles のシンボリックリンクが正しく張られているか、リンク先が存在するかを検証する。
install スクリプト実行後の確認や、設定が反映されない問題の切り分けに使用する。

## OS 判定

Bash ツールで `uname -s` を実行し、OS を判定する。

- `Linux` → Linux/WSL 検証項目を実行
- それ以外（Windows 上の Claude Code）→ Windows 検証項目を実行

## Linux/WSL 検証項目

`install.sh` で定義されているシンボリックリンクを検証する。
`DOTDIR` は dotfiles リポジトリのルートディレクトリ。

### ホームディレクトリ直下

| リンクパス | リンク先 |
|---|---|
| `~/.bashrc` | `$DOTDIR/.bashrc` |
| `~/.bash_aliases` | `$DOTDIR/.bash_aliases` |
| `~/.bash_logout` | `$DOTDIR/.bash_logout` |
| `~/.profile` | `$DOTDIR/.profile` |
| `~/.gitconfig` | `$DOTDIR/.gitconfig` |
| `~/.ripgreprc` | `$DOTDIR/.ripgreprc` |
| `~/.tmux.conf` | `$DOTDIR/.tmux.conf` |

### `~/.config/` 配下

`~/.config` 自体が `$DOTDIR/.config` へのシンボリックリンクになっている場合、
個別のシンボリックリンクは不要（install.sh が作成する個別リンクは `~/.config` が通常ディレクトリの場合のみ有効）。

**検証順序:**
1. まず `~/.config` 自体がシンボリックリンクかを確認
2. シンボリックリンクの場合 → リンク先が `$DOTDIR/.config` であり、配下のファイルにアクセスできれば OK
3. 通常ディレクトリの場合 → 以下の個別リンクを検証

| リンクパス | リンク先 |
|---|---|
| `~/.config/starship.toml` | `$DOTDIR/.config/starship.toml` |
| `~/.config/lazygit` | `$DOTDIR/.config/lazygit` |
| `~/.config/mise` | `$DOTDIR/.config/mise` |
| `~/.config/nvim` | `$DOTDIR/.config/nvim` |

### `~/.claude/` 配下

| リンクパス | リンク先 |
|---|---|
| `~/.claude/settings.json` | `$DOTDIR/.config/claude-code/settings.json` |
| `~/.claude/rules` | `$DOTDIR/.config/claude-code/rules` |
| `~/.claude/skills` | `$DOTDIR/.config/claude-code/skills` |

### その他

| リンクパス | リンク先 |
|---|---|
| `~/.bin` | `$DOTDIR/.bin` |

## Windows 検証項目

`install.ps1` で定義されているシンボリックリンクを検証する。
`$dotdir` は dotfiles リポジトリのルートディレクトリ。

| リンクパス | リンク先 |
|---|---|
| `$HOME\Documents\PowerShell` | `$dotdir\PowerShell` |
| `$LOCALAPPDATA\nvim` | `$dotdir\.config\nvim` |
| `$HOME\.config\mise` | `$dotdir\.config\mise` |
| `$HOME\.ripgreprc` | `$dotdir\.ripgreprc` |
| `$HOME\.claude\settings.json` | `$dotdir\.config\claude-code\settings.json` |
| `$HOME\.claude\rules` | `$dotdir\.config\claude-code\rules` |
| `$HOME\.claude\skills` | `$dotdir\.config\claude-code\skills` |
| `$HOME\.bin` | `$dotdir\.bin` |
| `$LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` | `$dotdir\WindowsTerminal\settings.json` |

## 検証ロジック

各リンクについて、以下の 3 点を検証する。

### Linux/WSL の場合

Bash ツールで以下のスクリプトを実行する（`$LINK` はリンクパス、`$EXPECTED_TARGET` は期待されるリンク先）:

```bash
# 1. シンボリックリンクであること
[ -L "$LINK" ]

# 2. リンク先が期待するパスであること
readlink -f "$LINK"

# 3. リンク先が実際に存在すること (dangling symlink でないこと)
[ -e "$LINK" ]
```

### Windows の場合

Bash ツール経由で PowerShell コマンドを実行する:

```powershell
# 1. シンボリックリンク (ReparsePoint) であること
(Get-Item $Link -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint

# 2. リンク先が期待するパスであること
(Get-Item $Link -Force).Target

# 3. リンク先が実際に存在すること
Test-Path (Get-Item $Link -Force).Target
```

## 結果報告フォーマット

検証結果を以下の形式で報告する。

```
## 検証結果

| # | リンクパス | 状態 | 詳細 |
|---|---|---|---|
| 1 | ~/.bashrc | OK | -> ~/ghq/.../dotfiles/.bashrc |
| 2 | ~/.config/nvim | NG | シンボリックリンクではなく通常ディレクトリ |
| 3 | ~/.claude/skills | NG | シンボリックリンクが存在しない |

**合計: 15 件中 13 件 OK / 2 件 NG**
```

NG の種類:
- **not_symlink** - パスは存在するがシンボリックリンクではない（通常ファイル/ディレクトリ）
- **wrong_target** - シンボリックリンクだがリンク先が期待と異なる
- **dangling** - シンボリックリンクだがリンク先が存在しない
- **missing** - パス自体が存在しない

## 修復手順

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
