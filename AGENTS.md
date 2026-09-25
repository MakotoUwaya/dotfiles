# AGENTS.md

AI エージェント共通のガイドライン、プロジェクト概要、アーキテクチャ定義です。

## 言語設定
- **第一言語**: すべての出力（回答、計画、説明、コードコメント等）は **日本語** で記述してください。

## プロジェクト概要
- **WSL2 (Ubuntu) + Windows** 向け dotfiles。
- `mise` を中心としたツールバージョン管理と、自作スクリプトによる構成管理。

## アーキテクチャ

### 主要ディレクトリ
- `.config/nvim/`: Neovim 設定（Lua, lazy.nvim: `init.lua` → `lua/config/lazy.lua` → `lua/plugins/*.lua`）
- `.config/mise/config.toml`: ツールバージョン管理（node, pnpm, fzf, bat, lazygit, delta 等）
- `.config/starship.toml`: プロンプトテーマ
- `.config/claude-code/`: Claude Code 設定（settings.json, rules/, skills/）
- `.config/nushell/`: Nushell 設定（`env.nu` → `vendor/autoload/*.nu` → `config.nu`）
- `.config/lazygit/`: lazygit 設定
- `.bin/`: インストールスクリプト、`apt-installed.list`
- `etc/apt/`: APT ソースリスト・鍵ファイル
- `PowerShell/`: Windows PowerShell プロファイル
- `winget/`: Windows パッケージリスト
- `.bashrc`, `.profile`, `.bash_aliases`: bash 初期化（mise, keychain, cargo, fzf, direnv, starship 順）

### ツール管理の階層
1. **mise**: 主要ツールマネージャ（最優先）
2. **apt**: システムパッケージ（`.bin/apt-installed.list`）
3. **cargo/rustup**: Rust ツールチェーン
4. **winget**: Windows アプリケーション

## 設定追加手順（.gitignore ホワイトリスト対応）
`.gitignore` はホワイトリスト方式（`/*` で全除外）のため、新しい設定（例: `.config/xxx`）を追加する際は以下をセットで実施すること:
1. `.gitignore` に除外例外（`!/.config/xxx/` 等）を追記（既存行との重複に注意）
2. インストールスクリプト（`.bin/install.sh` / `.bin/install.ps1`）にシンボリックリンク作成処理を追加
3. `git check-ignore -v <file>` で追跡対象となったことを確認

## コミットコンベンション
Gitmoji スタイルを使用（`gitmoji-cli` 推奨）:
- `✨ Add ...`: 新機能・ツールの追加
- `🔧 Fix ...`: 設定の修正
- `📦️ Update ...`: パッケージ・依存関係の更新
- `♻️ Refactor ...`: コードのリファクタリング
- `🔥 Remove ...`: 不要な設定の削除

## 共通注意事項
- **事実に基づく最小変更**: 現状の診断と事実（環境変数やステータス）を優先し、根拠の不明瞭な設定追加は避けること。
- **環境の明確な区別**: PowerShell (Windows) と bash (WSL2 Ubuntu) のコマンドを明確に区別して提案すること。
- **既存方針の尊重**: `lazy.nvim` 構成や `mise` による管理方針を維持し、新ツール追加時は `.config/mise/config.toml` への反映を検討すること。
- **動作確認**: 複雑なシェルスクリプト変更時は `--debug` モードでの動作確認を考慮すること。

## 主要コマンド
- **WSL2 / Linux リンク作成**: `~/.bin/install.sh`
- **Windows リンク作成**: 管理者権限 PowerShell で `~\.bin\install.ps1`
- **Git 除外ルール確認**: `git check-ignore -v <file>`
