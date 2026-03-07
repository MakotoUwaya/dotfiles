---
name: redmine-api
description: Redmine MCP ツール (mcp__redmine__*) を使用する際に自動適用される。Markdown 記法、画像添付、レスポンスパース方法を提供する。
user-invocable: false
---

# Redmine MCP API ガイド

## Overview

Redmine MCP ツール (`mcp__redmine__*`) 共通の記法・レスポンス処理をまとめる。

## When to Use

- Redmine のチケット情報を取得・更新するとき
- MCP ツールのレスポンスがファイルに保存されたとき

## Markdown 記法

Redmine は **Markdown** 記法（Textile ではない）。

- 画像サムネイル: `{{thumbnail(filename.png, size=500)}}`
- コードブロック: ` ```lang ... ``` `
- テーブル: `| col1 | col2 |` 形式

## 画像添付

```
mcp__redmine__uploadAttachmentFromLocalFile  →  token を取得
mcp__redmine__updateIssue  →  uploads[] に token を指定して説明欄に {{thumbnail()}} を記述
```

## レスポンスがファイルに保存された場合

MCP レスポンスが大きい場合、Claude Code がローカルファイルに保存する。
同梱の `parse_issue.py` でパースする。

```bash
# 基本情報 + description
python ~/.config/claude-code/skills/redmine-api/parse_issue.py <保存先ファイルパス>

# journals（コメント履歴）も含める
python ~/.config/claude-code/skills/redmine-api/parse_issue.py <保存先ファイルパス> --journals
```

### JSON 構造

```
[{type: "text", text: "<JSON string>"}]
  → json.loads(data[0]['text'])['data']['issue']
```

`text` は JSON 文字列なので `json.loads()` で二重パースが必要。

## Guidelines

- `getIssue` はまず **journals なし**（`queryParams: {}`）で取得する。description だけで十分な場合が多い
- journals が必要な場合のみ `include: ["journals"]` を付けて再取得する。レスポンスが巨大になりファイル保存される可能性が高い
- description の更新は全文上書き。既存内容を `getIssue` で取得してから追記すること
