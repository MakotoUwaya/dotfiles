# AGENTS.md

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
- `.config/claude-code/`: Claude Code グローバル設定（settings.json, rules/, skills/）
- `.config/nushell/`: Nushell シェル設定（env.nu, config.nu）
- `.config/lazygit/`: lazygit TUI 設定
- `.bin/`: インストールスクリプト、apt パッケージリスト
- `etc/apt/`: APT ソースリスト・鍵ファイル
- `PowerShell/`: Windows PowerShell プロファイル
- `winget/`: Windows パッケージリスト
- `.bashrc`, `.zshrc` 等: シェル初期化ファイル

### シェル初期化チェーン
**bash**: `.profile` → `.bashrc` → `.bash_aliases`
`.bashrc` で `mise`, `keychain`, `cargo`, `fzf`, `direnv`, `starship` を順に初期化します。

**Nushell**: `env.nu`（環境変数・PATH・starship/mise 生成）→ `vendor/autoload/*.nu`（自動読込）→ `config.nu`（エイリアス・コマンド・キーバインド）

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
- `♻️ Refactor ...`: コードのリファクタリング
- `🔥 Remove ...`: 不要な設定の削除

## 共通注意事項
- コードの修正やリファクタリングを行う際は、既存の `lazy.nvim` 構成や `mise` による管理方針を尊重してください。
- 複雑なシェルスクリプトの変更を行う際は、`--debug` モードでの動作確認を考慮してください。
- 新しいツールの追加や設定変更の際は、`.config/mise/config.toml` への反映を検討してください。
- `.gitignore` はホワイトリスト方式（`/*` で全除外 → `!` で個別許可）。新ファイル追加時は除外例外の設定が必要（詳細は `.claude/rules/dotfiles-add-config.md`）
- OS 分岐がある箇所（install.sh, Neovim build 関数等）では WSL2 Ubuntu と Windows 両方を考慮すること
- PowerShell コマンドと WSL2 (Ubuntu) 上のコマンドを明確に区別して提案してください。
- 設定の追加や修正を行う際は、根拠の不明瞭な記述（便宜的な慣習設定）を避け、現状の診断と事実に基づいた最小限の変更を優先してください。問題発生時は、まず現在のステータスや環境変数を確認し、必要性が客観的に証明された場合のみ設定の変更を提案してください。

## よく使うコマンド
- `~/.bin/install.sh` — シンボリックリンク作成（WSL2/Linux）
- `git check-ignore -v <file>` — .gitignore ルールの確認

## インストール手順
1. `mise use -g ghq`
2. `ghq clone https://github.com/MakotoUwaya/dotfiles.git`
3. OS に応じたインストールスクリプトを実行:
   - **WSL2 / Linux**: `~/.bin/install.sh`（シンボリックリンク作成。既存ファイルは `~/.dotbackup` に移動）
   - **Windows**: 管理者権限 PowerShell で `~\.bin\install.ps1`（シンボリックリンク作成 + winget パッケージインポート。既存ファイルは `~\.dotbackup` に移動）
