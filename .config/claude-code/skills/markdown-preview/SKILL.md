---
name: markdown-preview
description: 作業リポジトリの Markdown ファイルを mo でライブプレビューする。「/markdown-preview」で使用。
---

# Markdown Preview

## Overview

作業リポジトリ内の `.md` ファイルを mo (k1LoW/mo) でブラウザプレビューする。
既存セッションがあればリセットし、クリーンな状態で起動する。

## Instructions

以下の手順を **順番に** 実行する。

### 1. ステータス確認

```bash
mo --status --json
```

JSON 出力の `status` フィールドを確認する。

### 2. セッションのリセット

- **stopped 以外** の場合: まず `mo --shutdown` を実行してから `mo --clear` を実行する
- **stopped** の場合: `mo --clear` を実行する

`mo --clear` は対話的に確認を求めるため、`yes | mo --clear` でパイプする。
セッションが存在しない場合 (`no saved session`) はそのまま次へ進む。

### 3. 監視開始

Claude Code の **現在の作業ディレクトリ（CWD）** 配下の `.md` ファイルを対象にする。

```bash
cd <CWD> && mo -w '**/*.md'
```

- `<CWD>` は Claude Code セッションの primary working directory に置き換える
- `node_modules` などを除外したい場合は `-w` を複数指定して対象ディレクトリを絞る
- 特定ファイルのみプレビューしたい場合はファイル引数で渡す: `mo path/to/file.md`

## Constraints

- `mo` は mise (`github:k1LoW/mo`) で管理されている
- `mo` がパスに見つからない場合は `mise install` を案内する
