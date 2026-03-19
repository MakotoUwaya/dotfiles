---
name: teamspirit-backfill-preflight
description: TeamSpirit に保留分・追加分の工数を後から登録する際のプリフライトチェック。inputWorkHours（追記）と inputWorkHoursBatch（全置換）の使い分け、実労働時間との整合性確認、description 付与を確実にする。「保留分登録」「追加登録」「工数修正」で使用。
---

# TeamSpirit 保留分工数登録 プリフライトチェック

## Overview

TeamSpirit に後から工数を追記・修正する際に、よくあるミスを防ぐためのチェックリストとワークフロー。

## When to Use

- 未アサインだったジョブの保留分を後から登録する
- 既に日次確定済みの日の工数を修正する
- 複数日分の工数を一括で追記する

## Pre-flight Checklist

### 1. 登録方式の選択

| 状況 | ツール | 理由 |
|------|--------|------|
| 既存登録に1タスク追記 | `inputWorkHours` | clearExisting=false で既存を保持 |
| 既存登録を含めて全面修正 | **`registerDayWorkHours`**（推奨） | unfixDay〜fixDay を1セッションで完結、description 必須バリデーション付き |
| 日次確定不要な全面修正 | `inputWorkHoursBatch` + `autoFixDay=false` | 後から配分変更する場合 |

**重要**: `inputWorkHours`（追記）で追加すると、**既存の合計 + 追加分** が新合計になる。サマリの合計が既に実労働時間と一致している場合、追記すると**超過する**。

### 2. 超過チェック（追記モードの場合）

```
サマリ合計 = 実労働時間 の場合:
  → 追記ではなく inputWorkHoursBatch で全タスクを再登録する
  → 追記分を含めてタスク時間を按分調整する

サマリ合計 < 実労働時間 の場合:
  → inputWorkHours で追記可能（差分の範囲内）
```

### 3. 全面再登録時の必須事項

- [ ] `getAttendance` で実労働時間を確認
- [ ] サマリファイルの全タスク合計 = 実労働時間 を検証
- [ ] 全タスクに `description` を付与（鉛筆アイコンの作業報告）
- [ ] `note`（全体の作業報告欄）を設定
- [ ] 日次確定済みの場合は先に `unfixDay` で解除

### 4. サマリファイルとの整合性

**鉄則**: サマリファイルの内容 = TeamSpirit の登録内容

- サマリを修正したら TeamSpirit も再登録
- TeamSpirit を修正したらサマリも更新
- `⚠未アサイン・未登録` マークは登録完了後に除去

## Common Mistakes

### ミス1: 二重計算

```
❌ サマリ合計 12:01（PR00008371 含む）
   + inputWorkHours で PR00008371 の 2:30 を追記
   = TeamSpirit 工数 14:31（実労働 12:01 を超過）

✅ inputWorkHoursBatch で全タスクを再登録（合計 12:01）
```

### ミス2: description 忘れ

```
❌ inputWorkHoursBatch の tasks に description を省略
   → タスク別の作業報告が空欄

✅ 全タスクに description を含める
   {"name":"...", "time":"1:00", "description":"具体的な作業内容"}
```

### ミス3: 日次確定済みの修正

```
❌ 確定済みの日に inputWorkHoursBatch → note 入力で "element is not editable" エラー

✅ registerDayWorkHours を使う（内部で自動 unfixDay → 登録 → fixDay）
   または先に unfixDay → inputWorkHoursBatch → autoFixDay=true で再確定
```

## Workflow Template

### 推奨: registerDayWorkHours を使用

```
1. getAttendance で対象日の実労働時間を確認
2. サマリファイルを読み、全タスクをリストアップ
3. 合計 = 実労働時間 を検証
4. registerDayWorkHours で全タスク（description 必須）+ note を登録
   → unfixDay / validateTotal / fixDay は自動実行される
5. サマリファイルを更新（⚠マーク除去、時間調整反映）
```

### 代替: inputWorkHoursBatch を使用（日次確定不要な場合）

```
1. getAttendance で対象日の実労働時間を確認
2. サマリファイルを読み、全タスクをリストアップ
3. 合計 = 実労働時間 を検証
4. 日次確定済みなら unfixDay
5. inputWorkHoursBatch（autoFixDay=false）で全タスク（description 付き）+ note を登録
6. サマリファイルを更新（⚠マーク除去、時間調整反映）
```
