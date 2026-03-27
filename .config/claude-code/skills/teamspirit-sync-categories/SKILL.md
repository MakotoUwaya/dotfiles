---
name: teamspirit-sync-categories
description: TeamSpirit のジョブアサイン実態と categories.md の乖離を検出・修正する。registerDayWorkHours の部分失敗を予防するためのプリフライトチェック。「カテゴリ同期」「枝番確認」「categories.md 更新」「工数登録前の確認」で使用。
---

# TeamSpirit カテゴリ同期

## Overview

`works/activity-summary/categories.md` に記載された PJ 名称・枝番マッピングが、TeamSpirit の実際のアサイン状態と乖離すると `registerDayWorkHours` が部分失敗する。このスキルは乖離を検出し、categories.md を最新化する。

## When to Use

- `registerDayWorkHours` で「タスクが見つかりません」エラーが発生した
- PJ の名称変更や枝番の追加・削除が行われた
- 工数登録前に categories.md の正確性を確認したい
- 定期メンテナンス（月1回程度）

## Instructions

### Step 1. 現状取得

```
getAssignedJobs(day=1)
```

全アサイン済みジョブと作業分類の一覧を取得する。

### Step 2. categories.md との差分検出

`works/activity-summary/categories.md` を読み込み、以下の差分を検出する:

| 差分種別 | 検出方法 | 影響度 |
|----------|----------|--------|
| **PJ 名称変更** | getAssignedJobs の名称 ≠ categories.md の名称 | 高（登録失敗） |
| **枝番削除** | categories.md にあるが getAssignedJobs にない枝番 | 高（登録失敗） |
| **枝番追加** | getAssignedJobs にあるが categories.md にない枝番 | 低（機能的問題なし） |
| **ジョブ追加** | getAssignedJobs にあるが categories.md にないジョブ | 中（新PJ未対応） |
| **ジョブ削除** | categories.md にあるが getAssignedJobs にないジョブ | 中（終了PJ残存） |

### Step 3. categories.md 更新

差分をユーザーに提示し、承認を得てから更新する。更新対象:

1. **プロジェクト一覧テーブル**: 名称・備考（枝番数）
2. **jobId 別の枝番マッピング**: 実態に合わせて更新
3. **PJコード → タスク名マッピング**: 表示名・短縮名を更新
4. **リポジトリ → PJコード対応**: 名称を更新
5. **注意事項**: 枝番数の変更を反映

### Step 4. サマリファイルの整合性チェック（オプション）

未登録のサマリファイル（`works/activity-summary/YYYYMM/DD.md`）がある場合、そのファイル内のタスク名が更新後の categories.md と整合するか検証する。

## Known Drift Patterns

過去に発生した乖離パターン:

| パターン | 事例 | 原因 |
|----------|------|------|
| PJ 名称変更 | `売買契約アプリ プロトタイプ開発` → `営業支援 売買追客機能強化` | Zoho CRM での PJ 名更新が TS に反映 |
| 枝番大量削減 | PR00008861: 19枝番 → 5枝番 | TS 管理者によるジョブ整理 |
| 全角半角不一致 | `ＷＳＤＧ共通業務等`（categories.md）vs `WSDG共通業務等`（TS実体） | 初期記録時の転記ミス |

## Guidelines

- categories.md の更新は Git で差分管理されるため、変更履歴を追跡可能
- 枝番が削除されていた場合、過去のサマリで使っていた枝番は `addJobCategories` で再追加が可能
- PJ 名称変更は Slack の `#topic_pdm` チャンネルで共有されることが多い
- 同期後は `getAssignedJobs` で最終確認すること
