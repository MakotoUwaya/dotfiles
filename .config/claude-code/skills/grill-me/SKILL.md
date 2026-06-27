---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

# Grill Me - 設計・計画の徹底質問

## Overview

ユーザーの計画や設計について、決定木の全分岐を一つずつ解決しながら、共通理解に達するまで徹底的に質問する。

## When to Use

- ユーザーが「grill me」「突っ込んで」「ツッコミ入れて」と言ったとき
- 計画・設計のストレステストを依頼されたとき
- 意思決定の抜け漏れを洗い出したいとき

## Instructions

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If the answer options can be enumerated, present the question with the AskUserQuestion tool (include your recommended option first, labeled "(Recommended)"). Use free-text questions only when the answer cannot be enumerated.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Examples

### 質問の出し方

選択肢が列挙できる場合:

```
AskUserQuestion:
  question: "認証方式はどれを採用しますか？"
  options:
    - "OAuth 2.0 + PKCE (Recommended)" — SPA 向け標準、トークン漏洩リスクが低い
    - "API Key" — 実装が簡単だがローテーション運用が必要
    - "Session Cookie" — SSR 前提なら最もシンプル
```

選択肢が列挙できない場合（自由記述）:

```
「このサービスの想定ユーザー数は？ピーク時の同時接続数も含めて教えてください。」
```

## Guidelines

- 質問は必ず一問ずつ出す（まとめて出さない）
- 推奨案を必ず添える（「おすすめはこれ、理由はこう」）
- コードベースを読めば答えられる質問は、読んでから質問に反映する
- 依存関係がある決定は、依存元から順に解決する
