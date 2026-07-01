---
name: approve-and-merge
description: GitLab MR の Approve・Merge・関連 Issue のステータスラベル更新を一括実行する。「approve & merge」「マージして」「MR をマージして Issue も更新して」等で使用。
---

# Approve and Merge

## Overview

GitLab MR の Approve → Merge → 関連 Issue のステータスラベル更新を一括で行う。

## When to Use

- MR をマージしてよい状態になったとき
- 「approve & merge」「マージして」「MR を通して」等の指示があったとき

## 引数

- MR 番号または MR URL。省略時は同一セッション内で直近に操作（`review-mr` 等）した MR を対象とする。
- `--status <label>`: Issue に付与するステータスラベル（デフォルト: `status::StgReady`）
- `--no-issue`: Issue のステータス更新をスキップ

## Instructions

### 1. MR の状態確認

MR の以下を確認し、問題があればユーザーに報告して確認を取る:

- パイプラインが success であること
- 未解決のディスカッションがないこと
- コンフリクトがないこと

### 2. Approve

```bash
glab api -X POST "projects/<project_path>/merge_requests/<MR番号>/approve"
```

### 3. Merge

```bash
glab api -X PUT "projects/<project_path>/merge_requests/<MR番号>/merge" \
  -f should_remove_source_branch=true
```

### 4. 関連 Issue のステータス更新

#### Issue の特定

MR タイトルから `<project-short>#<番号>` パターンで Issue 番号を抽出する。
見つからない場合は MR の description からも検索する。
それでも見つからない場合はユーザーに確認する。

#### Issue プロジェクトの特定

- `account-service#XXXX` → `eseikatsu/es-account/account-service`
- `backlog#XXXX` → `eseikatsu/ebone-client/backlog`（Work Item）
- 他のパターンが出てきた場合はユーザーに確認する

#### ラベル更新

現在の `status::*` ラベルを外し、新しいステータスラベルを付与する。

**通常の Issue の場合:**

```bash
glab api -X PUT "projects/<issue_project_path>/issues/<Issue番号>" \
  -f "add_labels=<新ステータス>" \
  -f "remove_labels=<現ステータス>"
```

**Work Item（backlog 等）の場合:**

Work Item も Issues API で操作可能:

```bash
glab api -X PUT "projects/<issue_project_path>/issues/<Issue番号>" \
  -f "add_labels=<新ステータス>" \
  -f "remove_labels=<現ステータス>"
```

### 5. 結果報告

以下をまとめて報告する:

- MR: Approve & Merge 済み
- Issue: ステータス更新結果（旧ラベル → 新ラベル）

## Examples

### 基本的な使い方

```
/approve-and-merge 1533
```

→ MR !1533 を Approve & Merge し、関連 Issue のステータスを `status::StgReady` に更新

### ステータスを指定

```
/approve-and-merge 1533 --status "status::完了"
```

### Issue 更新をスキップ

```
/approve-and-merge 1533 --no-issue
```

## Guidelines

- Approve・Merge は他メンバーに影響する操作のため、MR の状態確認は必ず行う
- パイプラインが失敗中・未解決ディスカッションありの場合はユーザーに確認を取ってから進める
- git コマンドは直列で実行すること（並列実行禁止）
- Issue のステータスラベルは `status::*` 形式で、既存の status ラベルを外してから新しいものを付ける
