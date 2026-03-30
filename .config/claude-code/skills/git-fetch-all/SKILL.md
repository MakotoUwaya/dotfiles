---
name: git-fetch-all
description: ghq で管理している全リポジトリの remote を一括 fetch する。「全リポ fetch」「ghq fetch」「リポジトリ最新化」で使用。
---

# Git Fetch All (ghq)

## Overview

`ghq list` で管理している全リポジトリに対して `git fetch --prune origin` を並列実行し、リモート追跡ブランチを最新化する。

## Instructions

以下のコマンドを実行する:

```bash
ghq list --full-path | xargs -P8 -I{} git -C {} fetch --prune origin
```

### オプション

- `-P8` の数値はネットワーク帯域に応じて調整可能（デフォルト 8 並列）
- ユーザーが特定のホスト（github.com, gitlab.com 等）に絞りたい場合:
  ```bash
  ghq list --full-path | grep github.com | xargs -P8 -I{} git -C {} fetch --prune origin
  ```

## Guidelines

- このスキルは fetch のみ行う。pull（merge/rebase）は行わない
- 出力が多いため、結果は簡潔に要約して報告する（更新があったリポジトリ数、削除されたブランチ数など）
- エラーが出たリポジトリがあれば個別に報告する
