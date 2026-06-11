---
name: create-milestone-and-branches-for-square
description: GitLab の Square グループ (eseikatsu/es-square) で隔週水曜の定期リリース準備を行う。Group Milestone `[Square]YYYYMMDD` の作成と、squareWeb・squareMessenger の 2 プロジェクトへの `dev/YYYYMMDD` ブランチ (元 main) 作成を一括実行する。「リリースブランチ作って」「dev ブランチ作って」「milestone 作って」や、Slack のリリースリマインダーメッセージの URL を渡されたときに使用。リリース日は大型連休・緊急リリースで間隔が変わるため、作成前に必ずユーザーに日付を確認する。
model: sonnet
---

# Create Milestone and Branches for Square

## Overview

Square の隔週リリースに伴う GitLab 上の準備作業を自動化するスキル。作業は大きく 2 つ:

1. **Group Milestone 作成** — `eseikatsu/es-square` グループに `[Square]YYYYMMDD` を作成（終了予定日=リリース日）
2. **dev ブランチ作成** — `squareWeb` と `squareMessenger` の 2 プロジェクトに `dev/YYYYMMDD`（ブランチ元 `main`）を作成

GitLab MCP には milestone / branch 作成ツールが無いため、実装は **`glab api`** を使う（`gitlab-api` スキルの方針に準拠）。

## When to Use

以下のいずれかがトリガー:

- 「リリースブランチ作って」「dev ブランチ作って」「(Square の) milestone 作って」
- Slack のリリースリマインダーメッセージの URL（例: `https://eseikatsu.slack.com/archives/C014TNKD33Q/p...`）を渡されたとき
- 隔週水曜の定期リリース準備のタイミング

部分指定にも対応する:

- 「dev ブランチだけ」→ ブランチ作成のみ
- 「milestone だけ」→ Milestone 作成のみ
- 指定が無ければ Milestone + 両プロジェクトのブランチを一括作成

## 対象リソース（固定値）

| 種別 | 値 |
| --- | --- |
| Group | `eseikatsu/es-square` (URL-encoded: `eseikatsu%2Fes-square`) |
| Project 1 | `eseikatsu/es-square/squareWeb` (`eseikatsu%2Fes-square%2FsquareWeb`) |
| Project 2 | `eseikatsu/es-square/squareMessenger` (`eseikatsu%2Fes-square%2FsquareMessenger`) |
| Milestone 名 | `[Square]YYYYMMDD` |
| Milestone 終了予定日 (`due_date`) | リリース日 (`YYYY-MM-DD`) |
| ブランチ名 | `dev/YYYYMMDD` |
| ブランチ元 (`ref`) | `main` |

`YYYYMMDD` は **リリース日**。Milestone 名・ブランチ名・`due_date` は全て同じリリース日を使う。

## Instructions

### 前提チェック

- `glab auth status` で gitlab.com に認証済みか確認する。未認証なら `glab auth login` をユーザーに依頼する（インタラクティブなので `! glab auth login` の利用を案内）。

### Step 1: リリース日を決定する（必ずユーザー確認）

リリース日は隔週水曜が基本だが、**大型連休・緊急リリースで間隔が変わる**ため、計算値を提示した上で必ずユーザーに確認する。

1. 直近のリリース日を取得して次回候補を計算する。既存の Group Milestone から最新を取る:

   ```sh
   glab api "groups/eseikatsu%2Fes-square/milestones?per_page=20&state=active" \
     --jq '[.[] | select(.title | startswith("[Square]")) | .title] | sort | last'
   ```

   - 取得できた最新タイトル `[Square]YYYYMMDD` の日付 + 14 日を次回候補とする。
   - Milestone が無い・取れない場合は、`squareWeb` の `dev/*` ブランチ一覧からフォールバック:

     ```sh
     glab api "projects/eseikatsu%2Fes-square%2FsquareWeb/repository/branches?search=dev/&per_page=50" \
       --jq '[.[].name | select(startswith("dev/"))] | sort | last'
     ```

   - それも無ければ「今日以降の直近の水曜日」を候補にする。

2. 候補日が水曜日かどうかを `date -d <YYYY-MM-DD> +%u`（`3`=水）で検算する。

3. **AskUserQuestion** でリリース日を確認する。候補日を Recommended の先頭に置き、前後の水曜（連休ずれ・緊急リリース用）も選択肢に並べる。Other で任意の日付も受けられるようにする。

> ⚠️ ここでのユーザー確認は必須。確認せずに作成へ進まないこと。

### Step 2: Group Milestone を作成する

確定したリリース日 `YYYY-MM-DD`（および `YYYYMMDD`）で作成する。

1. 既存チェック（冪等性）:

   ```sh
   glab api "groups/eseikatsu%2Fes-square/milestones?title=%5BSquare%5DYYYYMMDD"
   ```

   既に存在すれば作成をスキップし、その旨を報告する。

2. 作成:

   ```sh
   glab api --method POST "groups/eseikatsu%2Fes-square/milestones" \
     -f "title=[Square]YYYYMMDD" \
     -f "due_date=YYYY-MM-DD"
   ```

### Step 3: dev ブランチを 2 プロジェクトに作成する

`squareWeb` と `squareMessenger` の両方に `dev/YYYYMMDD`（元 `main`）を作成する。

各プロジェクトについて:

1. 既存チェック（冪等性）:

   ```sh
   glab api "projects/<ENCODED_PROJECT>/repository/branches/dev%2FYYYYMMDD"
   ```

   200 が返れば既存。作成をスキップして報告する（404 なら未作成）。

2. 作成:

   ```sh
   glab api --method POST "projects/<ENCODED_PROJECT>/repository/branches" \
     -f "branch=dev/YYYYMMDD" \
     -f "ref=main"
   ```

`<ENCODED_PROJECT>` は `eseikatsu%2Fes-square%2FsquareWeb` / `eseikatsu%2Fes-square%2FsquareMessenger`。

### Step 4: 結果を報告する

作成した（またはスキップした）リソースをまとめて報告する:

- Milestone: `[Square]YYYYMMDD`（due_date と Web URL）
- ブランチ: `squareWeb` / `squareMessenger` の `dev/YYYYMMDD`（各 Web URL）

## Examples

リリース日 = 2026-06-24 の場合:

- Milestone: `[Square]20260624`, due_date=`2026-06-24`
- ブランチ: `squareWeb:dev/20260624`, `squareMessenger:dev/20260624`（元 `main`）

```sh
# Milestone
glab api --method POST "groups/eseikatsu%2Fes-square/milestones" \
  -f "title=[Square]20260624" -f "due_date=2026-06-24"

# squareWeb ブランチ
glab api --method POST "projects/eseikatsu%2Fes-square%2FsquareWeb/repository/branches" \
  -f "branch=dev/20260624" -f "ref=main"

# squareMessenger ブランチ
glab api --method POST "projects/eseikatsu%2Fes-square%2FsquareMessenger/repository/branches" \
  -f "branch=dev/20260624" -f "ref=main"
```

## Guidelines

- **リリース日は必ずユーザー確認**してから作成に進む（連休・緊急リリースで隔週がずれるため）。計算値は初期候補として提示するだけ。
- **冪等性**: Milestone・ブランチとも作成前に存在チェックし、既存ならスキップ。エラーで止めない。
- **URL エンコード**: グループ/プロジェクトのフルパス（`/`→`%2F`）、ブランチ名の `/`（`dev/...`→`dev%2F...`）に注意。`-f` の値（`title`, `branch`, `due_date` 等）はエンコード不要。
- **日付の一貫性**: Milestone 名・ブランチ名（`YYYYMMDD`）と `due_date`（`YYYY-MM-DD`）は同一日。表記だけ変換する。
- **MCP より glab**: branch / milestone は GitLab MCP に作成系ツールが無いため `glab api` を使う。詳細な使い分けは `gitlab-api` スキルを参照。
- 部分指定（dev ブランチのみ / milestone のみ）に応じて実行する Step を絞る。
