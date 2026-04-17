---
name: markdown-hard-linebreak
description: GitLab / GitHub の MR・PR・Issue 本文およびコメントで、句点後の半角スペース 2 つ+改行（CommonMark のハード改行）を一括適用する。MR/PR レビューコメント、Issue 本文、ドラフトノート等の投稿前後の文面整形時に使用。
---

# Markdown Hard Linebreak Applier

## Overview

GitLab（GLFM）と GitHub（GFM）の Markdown レンダラーは CommonMark 準拠で、段落内の単一改行を空白として折り畳む。
日本語の句点区切りで視覚的に改行させるには、行末に **半角スペース 2 つ + 改行** を入れる必要がある（`<br>` 相当のハード改行記法）。
本スキルは、投稿前/後の Markdown テキストにハード改行を一括適用する。

## When to Use

- GitLab MR / GitHub PR の本文・レビューコメント・ドラフトノートを作成するとき
- GitLab / GitHub Issue の本文・コメントを作成するとき
- 既に投稿したコメントに改行が反映されていないとき（GET → 置換 → PUT/PATCH）
- ユーザーから「改行が入ってない」「詰まって読みにくい」と指摘されたとき

## Out of Scope

- **DocBase**: soft break でも自動で改行されるため本スキル不要（`docbase-markdown` スキル参照）
- **Redmine**: 独自フレーバーで soft break が改行扱いのため本スキル不要（`redmine-api` スキル参照）

## Instructions

### 基本の置換ルール

句点の直後が単一改行（段落末でない）のところに、半角スペース 2 つを挿入する:

```python
import re

def apply_hard_linebreak(text: str) -> str:
    return re.sub(r'。\n(?!\n)', '。  \n', text)
```

- 空行（段落末）は置換対象外（`(?!\n)` negative lookahead）
- 既にハード改行済み（`。  \n`）は変化しない
- 英文の `.` は対象外（半角ピリオドには反応しない）

### 感嘆符・疑問符も対象にする場合

```python
re.sub(r'([。！？])\n(?!\n)', r'\1  \n', text)
```

### 既存コメントへの一括適用

**GitLab ドラフトノート**:

```
GET  /projects/:id/merge_requests/:iid/draft_notes
PUT  /projects/:id/merge_requests/:iid/draft_notes/:note_id  {note: ...}
```

**GitLab ディスカッション**:

```
GET  /projects/:id/merge_requests/:iid/discussions
PUT  /projects/:id/merge_requests/:iid/discussions/:discussion_id/notes/:note_id  {body: ...}
```

**GitHub PR / Issue コメント**:

```
GET    /repos/:owner/:repo/issues/:num/comments
PATCH  /repos/:owner/:repo/issues/comments/:id  {body: ...}

GET    /repos/:owner/:repo/pulls/:num/comments
PATCH  /repos/:owner/:repo/pulls/comments/:id  {body: ...}
```

一括適用のフロー:

1. GET で対象コメント一覧を取得
2. 各コメントの本文に `apply_hard_linebreak()` を適用
3. 変化があったものだけ PUT/PATCH で更新

## Examples

### 入力

```
XX について指摘します。
YY の対応をお願いします。

ZZ は問題ありません。
```

### 出力

```
XX について指摘します。  
YY の対応をお願いします。

ZZ は問題ありません。
```

（「XX について指摘します。」「YY の対応をお願いします。」の行末にそれぞれ半角スペース 2 つが入る）

## Guidelines

- コードブロック内の `。\n` は理想的には対象外にしたいが、簡易実装ではコードブロック判定を省略する。コードブロックに句点+改行が出現することは少ないため実用上問題になりにくい
- 投稿前に適用するのが理想。投稿後の修正は GET → 置換 → PUT/PATCH で行う
- 関連: ユーザーメモリ `feedback_sentence_linebreak.md`（ルールの根拠）
