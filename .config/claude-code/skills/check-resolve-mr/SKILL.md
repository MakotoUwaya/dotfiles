---
name: check-resolve-mr
description: Use when MR review comments have been addressed and need verification and resolution. 「確認して resolve」「resolve して」「修正されたか確認して」で使用。review-mr の後続操作。
---

# check-resolve-mr

## Overview

GitLab MR の自分が投稿した未解決ディスカッションを最新差分と突き合わせ、対応済みなら Resolve する。`review-mr` の後続操作。

## When to Use

- `review-mr` でレビューコメント投稿後、MR に修正コミットが追加されたとき
- 「resolve して」「確認して解決して」「修正されたか確認して」等の指示

## Arguments

MR 番号または MR URL。省略時は同一セッション内で直近に操作（`review-mr` 等）した MR を対象とする。

## Instructions

### 1. 情報収集（並列）

- 最新差分: `glab mr diff <MR番号>`
- ノート一覧: MCP `get_merge_request_notes`（`first: 100`）

### 2. 未解決ディスカッションの抽出

取得したノートから以下の条件でフィルタ:

- `resolvable: true` かつ `resolved: false`
- author が自分（`makoto.uwaya`）

対象がなければ「未解決のディスカッションはありません」と報告して終了。

### 3. 各ディスカッションの対応確認

各未解決ディスカッションについて:

1. コメントの指摘内容を把握
2. 最新差分で指摘が反映されているかを確認
3. 判定: **対応済み** / **未対応**（部分対応含む）

### 4. Resolve と報告

**対応済み** → Resolve:

```bash
glab api "projects/:id/merge_requests/<MR番号>/discussions/<discussion_id>" \
  --method PUT --raw-field "resolved=true"
```

**未対応** → 未対応の内容と理由をユーザーに報告。

最後に結果サマリーを出す:

- Resolved: N 件
- 未対応: N 件（理由付き）

## Guidelines

- 自分（`makoto.uwaya`）が author のディスカッションのみ Resolve する。他のレビュアーのディスカッションには触れない
- Resolve 前にユーザーへの確認は不要（対応済みの判定が明確なため）。判断に迷う場合のみユーザーに確認する
- GitLab API の操作詳細は `gitlab-api` スキルを参照
