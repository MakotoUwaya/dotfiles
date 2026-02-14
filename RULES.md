# 共通ルール (RULES.md)

このプロジェクトにおける AI エージェント共通のガイドライン、プロジェクト概要、およびアーキテクチャの定義です。

## 言語設定
- **第一言語**: すべての出力（回答、計画、説明、コードコメント等）は **日本語** で記述してください。

## プロジェクト概要
- **WSL2 Ubuntu + Windows** 向けの個人用 dotfiles リポジトリ。
- `mise` を中心としたツールバージョン管理と、独自のインストールスクリプトによる構成管理を行っています。

## アーキテクチャ

### ディレクトリ構成
- `.config/nvim/`: Neovim 設定（Lua, lazy.nvim ベース）
- `.config/mise/config.toml`: ツールバージョン管理（node, pnpm, fzf, bat, lazygit, delta 等）
- `.config/starship.toml`: プロンプトテーマ
- `.config/lazygit/`: lazygit TUI 設定
- `.bin/`: インストールスクリプト、apt パッケージリスト
- `etc/apt/`: APT ソースリスト・鍵ファイル
- `PowerShell/`: Windows PowerShell プロファイル
- `winget/`: Windows パッケージリスト
- `.bashrc`, `.zshrc` 等: シェル初期化ファイル

### シェル初期化チェーン
`.profile` → `.bashrc` → `.bash_aliases`
`.bashrc` で `mise`, `keychain`, `cargo`, `fzf`, `direnv`, `starship` を順に初期化します。

### Neovim プラグイン構成
`init.lua` → `lua/config/lazy.lua`（lazy.nvim ブートストラップ）→ `lua/plugins/*.lua`

### ツール管理の階層
1. **mise**: 主要ツールマネージャ
2. **apt**: システムパッケージ（`.bin/apt-installed.list` で管理）
3. **cargo/rustup**: Rust ツールチェーン
4. **winget**: Windows アプリケーション

## コミットコンベンション
- **Gitmoji スタイル**を使用します。`gitmoji-cli` (`gitmoji -c`) を推奨。
- `✨ Add ...`: 新機能・ツールの追加
- `🔧 Fix ...`: 設定の修正
- `📦️ Update ...`: パッケージ・依存関係の更新
- `🔥 Remove ...`: 不要な設定の削除

## インストール手順
1. `mise use -g ghq`
2. `ghq clone https://github.com/MakotoUwaya/dotfiles.git`
3. OS に応じたインストールスクリプトを実行:
   - **WSL2 / Linux**: `~/.bin/install.sh`（シンボリックリンク作成。既存ファイルは `~/.dotbackup` に移動）
   - **Windows**: 管理者権限 PowerShell で `~\.bin\install.ps1`（シンボリックリンク作成 + winget パッケージインポート。既存ファイルは `~\.dotbackup` に移動）