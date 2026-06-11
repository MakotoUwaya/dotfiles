---
name: create-milestone-and-branches-for-square
description: GitLab の Square グループ (eseikatsu/es-square) で隔週水曜の定期リリース準備を行う。Group Milestone `[Square]YYYYMMDD` の作成と、squareWeb・squareMessenger の 2 プロジェクトへの `release/YYYYMMDD` ブランチ (元=前回の release ブランチ) 作成を一括実行する。「リリースブランチ作って」「release ブランチ作って」「milestone 作って」や、Slack のリリースリマインダーメッセージの URL を渡されたときに使用。リリース日は大型連休・緊急リリースで間隔が変わるため、作成前に必ずユーザーに日付を確認する。
model: sonnet
---

# Create Milestone and Branches for Square

## Overview

Square の隔週リリースに伴う GitLab 上の準備作業を自動化するスキル。作業は大きく 2 つ:

1. **Group Milestone 作成** — `eseikatsu/es-square` グループに `[Square]YYYYMMDD` を作成（終了予定日=リリース日）
2. **release ブランチ作成** — `squareWeb` と `squareMessenger` の 2 プロジェクトに `release/YYYYMMDD`（ブランチ元=**前回の release ブランチ**）を作成

GitLab MCP には milestone / branch 作成ツールが無いため、実装は **`glab api`** を使う（`gitlab-api` スキルの方針に準拠）。

## When to Use

以下のいずれかがトリガー:

- 「リリースブランチ作って」「release ブランチ作って」「(Square の) milestone 作って」
- Slack のリリースリマインダーメッセージの URL（例: `https://eseikatsu.slack.com/archives/C014TNKD33Q/p...`）を渡されたとき
- 隔週水曜の定期リリース準備のタイミング

部分指定にも対応する:

- 「release ブランチだけ」→ ブランチ作成のみ
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
| ブランチ名 | `release/YYYYMMDD` |
| ブランチ元 (`ref`) | **前回の release ブランチ** `release/<前回のYYYYMMDD>` |

`YYYYMMDD` は **リリース日**。Milestone 名・ブランチ名・`due_date` は全て同じリリース日を使う。
ブランチ元は `main` ではなく、**前回リリースの `release/YYYYMMDD`**（= 既存の release ブランチのうち最新）を使う。

## Instructions

### 前提チェック

- `glab auth status` で gitlab.com に認証済みか確認する。未認証なら `glab auth login` をユーザーに依頼する（インタラクティブなので `! glab auth login` の利用を案内）。

### Step 1: リリース日を決定する（必ずユーザー確認）

リリース日は隔週水曜が基本だが、**大型連休・緊急リリースで間隔が変わる**ため、計算値を提示した上で必ずユーザーに確認する。

1. 直近のリリース日を取得して次回候補を計算する。既存の Group Milestone から最新を取る:

   ```sh
   glab api "groups/eseikatsu%2Fes-square/milestones?per_page=20&state=active" \
     | jq -r '[.[] | select(.title | startswith("[Square]")) | .title] | sort | last'
   ```

   - 取得できた最新タイトル `[Square]YYYYMMDD` の日付 + 14 日を次回候補とする。
   - Milestone が無い・取れない場合は、`squareWeb` の `release/*` ブランチ一覧からフォールバック:

     ```sh
     glab api "projects/eseikatsu%2Fes-square%2FsquareWeb/repository/branches?search=release/&per_page=50" \
       | jq -r '[.[].name | select(startswith("release/"))] | sort | last'
     ```

   - この最新 `release/YYYYMMDD` は **Step 3 のブランチ元**（前回 release ブランチ）としても再利用する。
   - それも無ければ「今日以降の直近の水曜日」を候補にする。

2. 候補日が水曜日かどうかを `date -d <YYYY-MM-DD> +%u`（`3`=水）で検算する。

3. **AskUserQuestion** でリリース日を確認する。候補日を Recommended の先頭に置き、前後の水曜（連休ずれ・緊急リリース用）も選択肢に並べる。Other で任意の日付も受けられるようにする。

> ⚠️ ここでのユーザー確認は必須。確認せずに作成へ進まないこと。

### Step 2: Group Milestone を作成する

確定したリリース日 `YYYY-MM-DD`（および `YYYYMMDD`）で作成する。

1. 既存チェック（冪等性）。`title=` 検索は **配列** を返すため、件数で判定する:

   ```sh
   glab api "groups/eseikatsu%2Fes-square/milestones?title=%5BSquare%5DYYYYMMDD" | jq 'length'
   ```

   `0` なら未作成（作成へ進む）。`1` 以上なら既存なので作成をスキップし、その旨を報告する。

2. 作成:

   ```sh
   glab api --method POST "groups/eseikatsu%2Fes-square/milestones" \
     -f "title=[Square]YYYYMMDD" \
     -f "due_date=YYYY-MM-DD"
   ```

### Step 3: release ブランチを 2 プロジェクトに作成する

`squareWeb` と `squareMessenger` の両方に `release/YYYYMMDD` を作成する。**ブランチ元 (`ref`) は `main` ではなく、各プロジェクトの前回 release ブランチ `release/<前回のYYYYMMDD>`**（= 既存の release ブランチのうち最新）。

各プロジェクトについて:

1. ブランチ元となる前回 release ブランチを確認する（プロジェクトごとに最新を取る。Step 1 のフォールバックで取得済みなら再利用可）:

   ```sh
   glab api "projects/<ENCODED_PROJECT>/repository/branches?search=release/&per_page=50" \
     | jq -r '[.[].name | select(startswith("release/"))] | sort | last'
   ```

2. 既存チェック（冪等性）:

   ```sh
   glab api "projects/<ENCODED_PROJECT>/repository/branches/release%2FYYYYMMDD" 2>/dev/null \
     | jq -e '.name' >/dev/null && echo "exists" || echo "not found"
   ```

   > ⚠️ 未作成のブランチに対しては `glab api` が **404 を返し exit code 5（非0）** で終わる。`jq` に直接渡すとパースエラーになるため、上記のように `2>/dev/null` + `&&`/`||` でエラーを握りつぶす。`exists` なら作成スキップ、`not found` なら作成へ進む。

3. 作成（`ref` は手順 1 で得た前回 release ブランチ）:

   ```sh
   glab api --method POST "projects/<ENCODED_PROJECT>/repository/branches" \
     -f "branch=release/YYYYMMDD" \
     -f "ref=release/<前回のYYYYMMDD>"
   ```

`<ENCODED_PROJECT>` は `eseikatsu%2Fes-square%2FsquareWeb` / `eseikatsu%2Fes-square%2FsquareMessenger`。

### Step 4: 結果を報告する

作成した（またはスキップした）リソースをまとめて報告する:

- Milestone: `[Square]YYYYMMDD`（due_date と Web URL）
- ブランチ: `squareWeb` / `squareMessenger` の `release/YYYYMMDD`（各 Web URL）

### Step 5: Slack スレッドへ完了報告する（トリガーが Slack URL の場合）

トリガーが Slack リマインダーメッセージの URL だった場合、**そのスレッドに完了報告を返信し、チャンネルにもブロードキャストする**。

1. URL から `channel_id` と親メッセージ `ts` を抽出する。
   - 例: `https://eseikatsu.slack.com/archives/C014TNKD33Q/p1781136025519729`
   - → `channel_id=C014TNKD33Q`、`ts=1781136025.519729`（`p` の後の数値で、末尾 6 桁の前に小数点を打つ）

2. `mcp__claude_ai_Slack__slack_send_message` で投稿する:
   - `channel_id`: 抽出した channel
   - `thread_ts`: 抽出した親 ts
   - `reply_broadcast`: `true`（チャンネルにも表示）
   - `message`: Step 4 の報告内容（Milestone・両プロジェクトの `release/YYYYMMDD` の Web URL）

   > 投稿前に **AskUserQuestion** で文面の最終 OK を取ること（送信前の最終確認は必須）。

3. URL が渡されていない（CLI 起動）場合は、この Step をスキップして Step 4 の報告のみで完了とする。

## Examples

リリース日 = 2026-07-01、前回リリース = 2026-06-17 の場合:

- Milestone: `[Square]20260701`, due_date=`2026-07-01`
- ブランチ: `squareWeb:release/20260701`, `squareMessenger:release/20260701`（元 `release/20260617`）

```sh
# Milestone
glab api --method POST "groups/eseikatsu%2Fes-square/milestones" \
  -f "title=[Square]20260701" -f "due_date=2026-07-01"

# squareWeb ブランチ（元 = 前回 release ブランチ）
glab api --method POST "projects/eseikatsu%2Fes-square%2FsquareWeb/repository/branches" \
  -f "branch=release/20260701" -f "ref=release/20260617"

# squareMessenger ブランチ（元 = 前回 release ブランチ）
glab api --method POST "projects/eseikatsu%2Fes-square%2FsquareMessenger/repository/branches" \
  -f "branch=release/20260701" -f "ref=release/20260617"
```

## Guidelines

- **リリース日は必ずユーザー確認**してから作成に進む（連休・緊急リリースで隔週がずれるため）。計算値は初期候補として提示するだけ。
- **ブランチは `release/YYYYMMDD`・元は前回 release**: ブランチ名は `release/`（`dev/` ではない）。ブランチ元 (`ref`) は `main` ではなく**前回リリースの `release/YYYYMMDD`**（既存 release のうち最新）。
- **冪等性**: Milestone・ブランチとも作成前に存在チェックし、既存ならスキップ。エラーで止めない。Milestone は `title=` 検索の配列件数 (`jq 'length'`) で、ブランチは未作成時に 404 + exit code 5 になるため `2>/dev/null` + `&&`/`||` で判定する。
- **URL エンコード**: グループ/プロジェクトのフルパス（`/`→`%2F`）、ブランチ名の `/`（`release/...`→`release%2F...`）に注意。`-f` の値（`title`, `branch`, `due_date`, `ref` 等）はエンコード不要。
- **日付の一貫性**: Milestone 名・ブランチ名（`YYYYMMDD`）と `due_date`（`YYYY-MM-DD`）は同一日。表記だけ変換する。
- **MCP より glab**: branch / milestone は GitLab MCP に作成系ツールが無いため `glab api` を使う。`glab api` には `--jq` フラグが無い（`gh api` 非互換）ため、JSON 抽出は `| jq` を使う。詳細な使い分けは `gitlab-api` スキルを参照。
- 部分指定（release ブランチのみ / milestone のみ）に応じて実行する Step を絞る。
