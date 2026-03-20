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
同梱の `parse-issue.cs` でパースする。

```bash
# 基本情報 + description
dotnet ~/.config/claude-code/skills/redmine-api/parse-issue.cs <保存先ファイルパス>

# journals（コメント履歴）も含める（C# 版は journals があれば自動表示）
dotnet ~/.config/claude-code/skills/redmine-api/parse-issue.cs <保存先ファイルパス>
```

### JSON 構造

```
[{type: "text", text: "<JSON string>"}]
  → JsonDocument.Parse(array[0].text).RootElement.GetProperty("data").GetProperty("issue")
```

`text` は JSON 文字列なので `JsonDocument.Parse()` で二重パースが必要。

## Guidelines

- `getIssue` はまず **journals なし**（`queryParams: {}`）で取得する。description だけで十分な場合が多い
- journals が必要な場合のみ `include: ["journals"]` を付けて再取得する。レスポンスが巨大になりファイル保存される可能性が高い
- description の更新は全文上書き。既存内容を `getIssue` で取得してから追記すること
