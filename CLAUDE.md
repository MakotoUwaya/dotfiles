# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code).

## 共通ガイドライン
プロジェクトのルール、アーキテクチャ、コミットコンベンションについては **[RULES.md](./RULES.md)** を参照してください。

## Claude 特定ルール
- コードの修正やリファクタリングを行う際は、既存の `lazy.nvim` 構成や `mise` による管理方針を尊重してください。
- 複雑なシェルスクリプトの変更を行う際は、`--debug` モードでの動作確認を考慮してください。

## よく使うコマンド
- `~/.bin/install.sh` — シンボリックリンク作成（WSL2/Linux）
- `git check-ignore -v <file>` — .gitignore ルールの確認

## 注意点
- `.gitignore` はホワイトリスト方式（`/*` で全除外 → `!` で個別許可）。新ファイル追加時は除外例外の設定が必要（詳細は `.claude/rules/dotfiles-add-config.md`）
- OS 分岐がある箇所（install.sh, Neovim build 関数等）では WSL2 Ubuntu と Windows 両方を考慮すること