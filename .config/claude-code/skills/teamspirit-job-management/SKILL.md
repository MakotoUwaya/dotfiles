---
name: teamspirit-job-management
description: TeamSpirit のジョブアサイン・作業分類の追加・削除・並べ替えを行う際のガイド。MCP ツールの制約と安全な操作順序を定義。「ジョブ整理」「アサイン追加」「枝番追加」「ジョブ並べ替え」で使用。
---

# TeamSpirit ジョブアサイン管理ガイド

## Overview

TeamSpirit MCP サーバーのジョブアサイン関連ツールを使って、ジョブの追加・削除・カテゴリ管理・並べ替えを安全に行うためのガイド。

## Available Tools

### 一括操作ツール（推奨）

| ツール | 用途 |
|--------|------|
| `reorganizeJobs` | **削除・カテゴリ追加削除・並べ替えを1セッションで一括実行**。複数操作をまとめる場合はこちらを推奨 |

`reorganizeJobs` は JSON パラメータで宣言的にジョブの目標状態を指定する:

```json
{
  "remove": ["PR00008351"],
  "jobs": {
    "PR00007971": {
      "categories": ["700_マネジメント業務", "701_ワークフロー起票等雑務"],
      "categoryOrder": ["700_マネジメント業務", "701_ワークフロー起票等雑務"]
    }
  },
  "jobOrder": ["PR00007971", "PR00008371"]
}
```

- `remove`: 削除するジョブコード配列
- `jobs`: 各ジョブの目標カテゴリ状態（`categories` 省略=現状維持、`categoryOrder` 省略=`categories` 順）
- `jobOrder`: ジョブの表示順

### 個別ツール（単発操作向け）

| ツール | 用途 |
|--------|------|
| `getAssignedJobs` | 現在のアサイン一覧を取得 |
| `addAssignedJob` | ジョブを新規追加（copyFromJobCode でカテゴリコピー可） |
| `removeAssignedJobs` | ジョブを削除 |
| `addJobCategories` | 既存ジョブにカテゴリを追加 |
| `removeJobCategories` | ジョブからカテゴリを削除 |
| `sortAssignedJobs` | カテゴリを昇順 or 指定順にソート |
| `sortJobOrder` | ジョブの表示順を並べ替え |
| `replaceAssignedJob` | 終了済みジョブを新ジョブに置換（作業分類引き継ぎ） |

## Operation Strategy

### 複数操作をまとめて行う場合 → `reorganizeJobs`

削除・カテゴリ変更・並べ替えを1回のダイアログセッションで完結する。個別ツールを順番に呼ぶよりセッションの無駄が少ない。

### 単発操作の場合 → 個別ツール

1つの操作だけなら個別ツールを直接呼ぶ。

### 個別ツールの Safe Operation Order

`reorganizeJobs` を使わず個別ツールで操作する場合は、以下の順序で実行すること：

```
1. getAssignedJobs で現状を把握・記録
2. 不要ジョブの削除（removeAssignedJobs）
3. カテゴリの削減（removeJobCategories）
4. カテゴリの追加（addJobCategories）
5. 新規ジョブの追加（addAssignedJob）
6. カテゴリの並べ替え（sortAssignedJobs）
7. ジョブの並べ替え（sortJobOrder）★最後に実行
8. getAssignedJobs で最終確認
```

**重要**: `sortJobOrder` は「上へ」ボタンで行を移動するため、大量の移動が発生する。これを先にやると、後続の操作でテーブルの状態が変わり整合性が崩れる。**必ず最後に実行**すること。

## Known Risks

### sortJobOrder でジョブが消失するリスク

大量移動（数百回以上）の途中でジョブ行が脱落する場合がある。

**対策**:
- sortJobOrder 実行後に `getAssignedJobs` で件数を確認
- 消失していたら `addAssignedJob` で再追加
- 再追加後にもう一度 `sortJobOrder`（2回目は移動回数が少ない）

### addAssignedJob でジョブが見つからない場合

`selectJobSearchResult` はジョブコードの**完全一致**で検索結果を選択する。検索結果テーブルの列構造（td[0]=チェックボックス, td[1]=コード）に注意。

**対策**: ジョブコード（例: `PR00008371`）で検索。名前やジョブIDでは検索不可。

### カテゴリの追加は copyFromJobCode で

`addJobCategories` は既存行を複製してカテゴリを設定する。ジョブにカテゴリが1行もない場合は使えない。

**対策**: ジョブを削除→ `addAssignedJob` で `copyFromJobCode` 付きで再追加し、カテゴリのベースを作ってから不要分を `removeJobCategories` で削除。

## Categories Definition

カテゴリ定義は `works/activity-summary/categories.md` を参照。ジョブ整理後は categories.md の枝番マッピングも更新すること。

## Session Management

TeamSpirit MCP はブラウザセッションを TTL（3分）ベースでキャッシュ・再利用する。エラー時は自動で破棄・再作成される。

- セッション切れ（Google SSO リダイレクト）時は `/mcp` で teamspiritMcp を reconnect
- headless 設定: `~/.claude.json` の `mcpServers.teamspiritMcp.env.TS_HEADLESS`
- Google SSO ログインが必要な場合は `TS_HEADLESS=false` に一時変更
- エラーメッセージには類似候補上位5件が Levenshtein 距離ベースで表示される
