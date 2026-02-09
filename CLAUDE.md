# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code).

## 共通ガイドライン
プロジェクトのルール、アーキテクチャ、コミットコンベンションについては **[RULES.md](./RULES.md)** を参照してください。

## Claude 特定ルール
- コードの修正やリファクタリングを行う際は、既存の `lazy.nvim` 構成や `mise` による管理方針を尊重してください。
- 複雑なシェルスクリプトの変更を行う際は、`--debug` モードでの動作確認を考慮してください。