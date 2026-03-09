# GitHub Copilot Instructions

すべての出力（回答・計画・説明・コードコメント等）は **日本語** で記述してください。

## プロジェクト概要

WSL2 Ubuntu + Windows 向けの個人用 dotfiles リポジトリ。`mise` を中心としたツールバージョン管理と、シンボリックリンクを使ったファイル配置管理を行っています。

## インストールスクリプト

### WSL2 / Linux

```sh
~/.bin/install.sh          # 通常実行
~/.bin/install.sh --debug  # デバッグモード（set -uex で詳細出力）
```

### Windows（管理者権限 PowerShell）

```powershell
~\.bin\install.ps1          # 通常実行
~\.bin\install.ps1 -Debug   # デバッグモード
```

スクリプトは既存ファイルを `~/.dotbackup` にバックアップしてからシンボリックリンクを作成します。

## アーキテクチャ

### シンボリックリンク構成

リポジトリのファイルをホームディレクトリへシンボリックリンクで配置します。

| リポジトリ内パス | リンク先（WSL2） | リンク先（Windows） |
|---|---|---|
| `.config/mise/` | `~/.config/mise` | `~\.config\mise` |
| `.config/nvim/` | `~/.config/nvim` | `%LOCALAPPDATA%\nvim` |
| `.config/claude-code/` | `~/.claude/` (各ファイル) | `~\.claude\` (各ファイル) |
| `PowerShell/` | — | `~/Documents/PowerShell` |
| `.bin/` | `~/.bin` | `~\.bin` |

### シェル初期化チェーン（WSL2）

```
.profile → .bashrc → .bash_aliases
```

`.bashrc` で `mise`, `keychain`, `cargo`, `fzf`, `direnv`, `starship` を順に初期化します。

### Neovim 設定構成

```
init.lua → lua/config/lazy.lua (lazy.nvim ブートストラップ) → lua/plugins/*.lua
```

各プラグインは `lua/plugins/` 以下に独立したファイルで定義されています。

### ツール管理の階層

1. **mise** — 主要ツールマネージャ（`.config/mise/config.toml` で管理）
2. **apt** — システムパッケージ（`.bin/apt-installed.list` で管理）
3. **cargo / rustup** — Rust ツールチェーン
4. **winget** — Windows アプリケーション（`winget/settings.json`）

## コミットコンベンション

Gitmoji スタイルを使用します（`gitmoji -c` コマンド推奨）。

| 絵文字 | 用途 |
|---|---|
| ✨ | 新機能・ツールの追加 |
| 🔧 | 設定の修正 |
| 📦️ | パッケージ・依存関係の更新 |
| ♻️ | リファクタリング |
| 🔥 | 不要な設定の削除 |

## 主要な規約

### Git コマンド

- CWD 内のリポジトリ操作では `git -C <path>` を使わない（`git status` で十分）
- `git add` と `git commit` は別々のコマンドとして実行する（`&&` で繋げない）

### Claude Code スクリプト管理

- 繰り返し使うスクリプトは `.config/claude-code/skills/<skill-name>/` に静的ファイルとして配置する
- 一度きりの処理はインライン実行でよい

### 設定変更時の注意

- Neovim プラグインの変更は既存の `lazy.nvim` 構成を尊重する
- 新しいツールの追加は `.config/mise/config.toml` への反映を検討する
- 複雑なシェルスクリプトの変更後は `--debug` モードで動作確認する
