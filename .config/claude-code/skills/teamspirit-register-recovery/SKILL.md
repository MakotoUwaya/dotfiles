---
name: teamspirit-register-recovery
description: registerDayWorkHours が部分失敗した際のリカバリ手順。タスク名不一致・枝番未登録などで一部タスクが登録できなかった場合に、既存の登録済みエントリを保持したまま不足分のみを追加登録する。「工数登録エラー」「タスクが見つかりません」「部分失敗」で使用。
---

# TeamSpirit 工数登録リカバリ

## Overview

`registerDayWorkHours` は全タスクを一括登録するファサードツールだが、一部タスクが失敗すると **成功分は登録済み・失敗分は未登録** の中間状態になる。このスキルは、既存エントリを破壊せずに不足分のみを追加するリカバリ手順を定義する。

## When to Use

- `registerDayWorkHours` の結果に「タスクが見つかりません」エラーが含まれている
- 検証 NG で日次確定がスキップされた
- 一部のタスクは正常に登録されている

## Recovery Workflow

### Step 1. エラー原因の特定

エラーメッセージの類似候補（Levenshtein 距離ベース上位5件）から原因を判定する。

| 原因 | 判定基準 | 対処 |
|------|----------|------|
| **枝番未登録** | 候補に同PJの別枝番はあるが、該当枝番がない | → Step 2a |
| **タスク名の誤記** | 候補に正しい名前がある（全角/半角、ONE/One 等） | → Step 2b |
| **ジョブ未アサイン** | 候補にそのPJ自体がない | → Step 2c |

### Step 2a. 枝番未登録 → addJobCategories で追加

```
1. addJobCategories(jobCode="{PJコード}", categories=["{枝番名}"], day={対象日})
2. 成功を確認
3. → Step 3 へ
```

**注意**: jobCode は PJコード（例: `PR00008861`）を使用する。jobId（`a0URC...`）では見つからない場合がある。

### Step 2b. タスク名の誤記 → 正しい名前を特定

よくある間違い:

| 誤 | 正 | 原因 |
|----|-----|------|
| `ＷＳＤＧ共通業務等`（全角） | `WSDG共通業務等`（半角） | categories.md とTS実体の乖離 |
| `売買クラウドOne` | `売買クラウドONE` | 大文字 ONE が正式 |
| `広告掲載対応開発/103` | → PJに103が無い場合あり | 枝番未登録パターン |

→ 正しいタスク名で Step 3 へ

### Step 2c. ジョブ未アサイン → addAssignedJob で追加

```
1. addAssignedJob(newJobCode="{PJコード}", copyFromJobCode="{類似PJ}")
2. 必要な枝番を addJobCategories で追加
3. → Step 3 へ
```

### Step 3. inputWorkHours で不足分のみ追加

**registerDayWorkHours を再実行しない**。既存の登録済みエントリが全クリアされてしまう。

```
inputWorkHours(
  day={対象日},
  taskName="{正しいタスク名}",
  time="{時間}",
  description="{作業内容}"
)
```

- `clearExisting` はデフォルト `false`（既存保持）
- 1タスクずつ追加する

### Step 4. 日次確定

```
fixDay(day={対象日})
```

### Step 5. サマリファイル更新

リカバリで追加したタスクに関連する注記をサマリに反映する（例: `※枝番新規追加`）。

## Critical Rules

1. **registerDayWorkHours を再実行しない** — 成功済みのエントリが全クリアされる
2. **inputWorkHours（追記モード）を使う** — clearExisting=false で既存を保持
3. **合計チェック** — 追記後の合計が実労働時間を超過しないことを確認。registerDayWorkHours で validateTotal=true だった場合、成功分 + 追記分 = 実労働時間 になるはず
4. **categories.md の更新** — 枝番を新規追加した場合は、categories.md の枝番マッピングにも反映する

## Example: 2026-03-24 のケース

```
エラー: タスク「広告掲載対応開発/103_バックログリファインメント」が見つかりません

原因: PR00008861 に 103 枝番が未登録

リカバリ:
1. addJobCategories(jobCode="PR00008861", categories=["103_バックログリファインメント"], day=24)
2. inputWorkHours(day=24, taskName="売買クラウド 広告掲載対応開発/103_バックログリファインメント", time="1:00", description="物件広告リファインメント MTG運用変更")
3. fixDay(day=24)
```
