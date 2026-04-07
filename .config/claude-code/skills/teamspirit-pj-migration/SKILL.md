---
name: teamspirit-pj-migration
description: TeamSpirit の終了済みPJを新PJに移行する。四半期ごとのコストコード切替、categories.md 更新、サマリファイルの旧PJコード置換を一括実行。「PJ移行」「コストコード切替」「ジョブ置換」で使用。
---

# TeamSpirit PJ Migration

## Overview

四半期ごとに発生する TeamSpirit のPJコード切替を一括実行する。
終了済みPJの検出 → 新PJコードの特定 → ジョブ置換 → 関連ファイル更新を行う。

## When to Use

- 四半期の変わり目（1月/4月/7月/10月）
- `getAssignedJobs` で「(終了)」マークのPJが見つかった場合
- `registerDayWorkHours` でタスク名が見つからないエラーが発生し、PJ終了が原因の場合

## Instructions

### Step 1: 終了済みPJの検出

`getAssignedJobs` を実行し、名称に「(終了)」を含むPJを一覧化する。

### Step 2: 新PJコードの特定

**ユーザーにPRコードを直接聞かない。** 以下の手順で自動特定する:

1. Salesforce レポートから有効ジョブ一覧を取得
   - URL: https://e-seikatsu.lightning.force.com/lightning/r/Report/00O2u000000KUubEAG/view?queryScope=userFolders
   - ブラウザ MCP ツールでアクセスし、レポートデータを取得
2. 終了PJの名称キーワード（「売買クラウドOne」「賃貸クラウド 要望対応」等）で類似する新PJを検索
3. 一意に特定できた場合 → そのまま使用
4. 候補が複数ある場合 → AskUserQuestion で3択程度に絞って提示
5. 候補がない場合 → ユーザーに確認

### Step 3: ジョブ置換の実行

`replaceAssignedJob` を **1件ずつ順次** 実行する（並列禁止）。

```
replaceAssignedJob(oldJobCode: "PR00008821", newJobCode: "PR00009111")
```

- 作業分類（枝番）は自動引き継ぎされる
- ただし一部の枝番（700_マネジメント等）が引き継がれない場合がある → Step 4 で確認

### Step 4: 置換結果の確認

`getAssignedJobs` を実行し、以下を確認:
- 旧PJが消え、新PJが追加されていること
- 引き継がれた枝番の確認（旧PJと比較して欠けがないか）
- 欠けがある場合はユーザーに報告

### Step 5: categories.md の更新

`works/activity-summary/categories.md` を更新:

1. **プロジェクト一覧**: 旧PJ行を削除し、新PJ行を追加
2. **jobId 別の枝番マッピング**: 旧PJセクションを削除し、新PJセクションを追加
3. **リポジトリ → PJコード対応**: リポジトリのマッピング先を新PJに変更
4. **PJコード → タスク名マッピング**: 新PJの表示名と短縮名を追加
5. **枝番の登録状況メモ**: 引き継ぎ漏れの枝番を記載

**旧PJ情報は残さない**（Git 履歴で追える）。

### Step 6: サマリファイルの更新

当月の `works/activity-summary/YYYYMM/*.md` 内の旧PJコードを新PJコードに置換する。

- `grep` で対象ファイルを特定
- 保留マーク（⚠）がある場合は解除

### Step 7: TeamSpirit 保留分の登録

旧PJ終了により保留されていた工数がある場合、新PJコードで TeamSpirit に登録する。

## Guidelines

- **同名タスクの集約**: `inputWorkHoursBatch` で同名タスク（「通常業務」等）を複数行で指定すると一部しか登録されない。必ず1行に集約し description に内訳を記載する
- **順次実行**: `replaceAssignedJob` は1件ずつ順次実行（TeamSpirit ブラウザ操作のため並列不可）
- **Git 操作はメインエージェント**: サブエージェントに git add/commit を委任しない
