---
name: git-fetch-all
description: ghq で管理している全リポジトリの remote を一括 fetch する。「全リポ fetch」「ghq fetch」「リポジトリ最新化」で使用。
---

# Git Fetch All (ghq)

## Overview

`ghq list` で管理している全リポジトリに対して `git fetch --prune origin` を並列実行し、リモート追跡ブランチを最新化する。

## Instructions

以下のスクリプトを実行する:

```bash
bash ~/.claude/skills/git-fetch-all/fetch-all.sh
```

### オプション（引数）

- 第1引数: grep パターンでリポジトリを絞り込む（例: `github.com`）
- 第2引数: 並列数（デフォルト: 8）

```bash
# github.com のリポジトリのみ、4並列で fetch
bash ~/.claude/skills/git-fetch-all/fetch-all.sh github.com 4
```

## Guidelines

- このスキルは fetch のみ行う。pull（merge/rebase）は行わない
- 出力が多いため、結果は簡潔に要約して報告する（更新があったリポジトリ数、削除されたブランチ数など）
- エラーが出たリポジトリがあれば個別に報告する
