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
- エラーが出たリポジトリがあれば個別に報告する
- スクリプトの出力を以下の形式で報告する:
  - **対象**: n リポジトリ（Total 行から取得）
  - **更新ありリポジトリ**: `REPO:` 行ごとに見出しとして表示し、配下のブランチを全て列挙する
    - `NEW:` → 新規作成
    - `UPD:` → 更新
    - `FORCE:` → 強制更新
    - `DEL:` → 削除
    - `TAG:` → 新規タグ
  - 更新なしのリポジトリは報告不要
  - 所見（renovate ブランチの大量強制更新、リリースブランチの作成など）があればコメントを添える
- 報告完了後、セッションリネーム用コマンドを提示する: `/rename git-fetch-yyyymmdd`（日付は当日）
