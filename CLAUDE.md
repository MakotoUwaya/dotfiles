# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language Settings

すべての出力は **日本語** で記述すること。コードコメントも日本語で書く。

## Repository Overview

WSL2 Ubuntu + Windows 向けの個人用 dotfiles リポジトリ。mise でツールバージョンを管理し、カスタム install スクリプトでシンボリックリンクを配置する。

## Installation

```sh
# dotfiles のクローン
mise use -g ghq
ghq clone https://github.com/MakotoUwaya/dotfiles.git

# シンボリックリンク作成（既存ファイルは ~/.dotbackup にバックアップ）
~/.bin/install.sh

# デバッグモード
~/.bin/install.sh --debug
```

install.sh は dotdir 配下の `.??*`（`.git` 除く）を `$HOME` にシンボリックリンクし、tmux plugin manager をクローンし、gitconfig の include を設定する。

## Architecture

### ディレクトリ構成

- `.config/nvim/` - Neovim 設定（Lua, lazy.nvim ベース）
- `.config/mise/config.toml` - ツールバージョン管理（node, pnpm, fzf, bat, lazygit, delta 等）
- `.config/starship.toml` - プロンプトテーマ
- `.config/lazygit/` - lazygit TUI 設定
- `.bin/` - インストールスクリプト、apt パッケージリスト
- `etc/apt/` - APT ソースリスト・鍵ファイル
- `PowerShell/` - Windows PowerShell プロファイル
- `winget/` - Windows パッケージリスト

### Shell 初期化チェーン

`.profile` → `.bashrc` → `.bash_aliases`

`.bashrc` で mise, keychain, cargo, fzf, direnv, starship を順に初期化する。

### Neovim プラグイン構成

`init.lua` → `lua/config/lazy.lua`（lazy.nvim ブートストラップ）→ `lua/plugins/*.lua`

主なプラグイン: nvim-lspconfig (Mason), nvim-cmp, conform.nvim, telescope, treesitter, neo-tree, barbar, lualine, gitsigns, which-key, noice

### ツール管理の階層

1. **mise** - 主要ツールマネージャ（node, pnpm, ghq, fzf, bat, lazygit, delta, starship, glab, gemini-cli）
2. **apt** - システムパッケージ（`.bin/apt-installed.list` で管理）
3. **cargo/rustup** - Rust ツールチェーン
4. **npm** - gitmoji-cli, neovim
5. **winget** - Windows アプリケーション

## Commit Convention

**gitmoji スタイル**を使用する。例:
- `🔧 Fix lazygit width settings`
- `📦️ Update lazy-lock.json`
- `➕ Add direnv`
- `🔥 Remove unused config`

gitmoji-cli (`mise` 経由でインストール済み) でコミットメッセージを生成する運用。
