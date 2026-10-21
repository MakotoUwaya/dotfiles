---
name: fix-session-name
description: Claude デスクトップアプリ（Code タブ）で、現在のセッション名を会話内容に合った簡潔な日本語の名前に変更する。「/fix-session-name」「セッション名を付けて」「セッション名を直して」で使用。名前を引数で渡せばそのまま使う。
---

# Fix Session Name

## Overview

会話の主題から簡潔なセッション名を考え、`mcp__ccd_session_mgmt__set_session_title` で現在のセッション名を変更する。

## When to Use

- `/fix-session-name` で呼び出されたとき（引数があればそれを名前にする）
- 「セッション名を付けて」「セッション名を直して」と頼まれたとき
- 自動で付いた名前（「Code review MR」など）が内容と合っていないとき

## Instructions

1. ツールが未ロードなら `ToolSearch` で `select:mcp__ccd_session_mgmt__set_session_title` を読み込む
   - 見つからない場合は、デスクトップアプリ以外の環境なので変更できない旨を伝えて終了する
2. 名前を決める
   - 引数があれば、それをそのまま使う
   - 引数がなければ、会話の主題から名前を考える（下の Guidelines に従う）
3. `set_session_title` を `session_id: "self"` で呼ぶ
4. 変更後の名前を 1 行で伝える

## Examples

| 会話の内容 | 名前 |
|---|---|
| MR 4540 のコードレビュー（築年月の判定修正） | MR !4540 レビュー（アットホーム売買 築年月の精度比較） |
| backlog#1008 の実装 | backlog#1008 importer の手動ステージングアップ対応 |
| Zoho チケットの調査 | tech_1895 調査（アットホーム土地面積エラー） |

## Guidelines

- 日本語で、40 文字程度までに収める
- MR・Issue・チケット番号があれば先頭に置く（`MR !4540`、`backlog#1008`、`tech_1895`）
- 作業の種類（レビュー・実装・調査など）と対象が分かるようにし、括弧で主題を補う
- ユーザーが自分で付けた名前を変えるときは、アプリが承認を求める。拒否されたら再試行しない
