---
name: harness-survey
description: 対象リポジトリ（es-account 配下ほか、ghq 管理下の任意リポジトリ）の AI エージェント開発ハーネス調査（ハーネス構成 + テスト現状 + Skills/Hooks/サブエージェント/ナレッジ整備状況）を実施し、account-service#4228 の G1〜G8 にマッピングした対応手順書を生成する。オプションで個人 skills・メモリの棚卸し（チーム昇格候補の洗い出し）も行う。「ハーネス調査」「harness survey」「/harness-survey <リポジトリ名>」で使用。
---

# Harness Survey - ハーネス調査と対応手順書生成

## Overview

対象リポジトリの「AI エージェント開発ハーネス」の現状（文脈・実行環境・ガードレール・検証ループ・観測性）と
テストの現状を並列サブエージェントで調査し、
account-service#4228（HOTL 統治設計）のギャップ定義 G1〜G8 / Phase 0〜7 にマッピングした対応手順書を生成する。
出力は `resources/output-format.md` に定義した共通フォーマット（§構成・H 番号粒度・スコア次元）に従い、
グループ・プロジェクト・リポジトリを問わず横断比較の可能性を保つ。

## When to Use

- #4228 の Phase 0 調査を新しいリポジトリで実施するとき
- 「ハーネス調査して」「<リポ名> の対応手順書を作って」という依頼
- 引数: 対象リポジトリ名（例: `/harness-survey esa-master`）。省略時は CWD のリポジトリを対象とする

## Instructions

### 1. 準備

1. `resources/survey-prompts.md` の「リポジトリ種別ごとの読み替え」で対象の種別
   （コード / IaC / 文書）を判定し、適用する読み替えを決める。あわせて
   `resources/target-repos.md` でリポジトリ固有事情（調査範囲の限定等）と調査状態を確認する。
   **未掲載のリポジトリ**でもユーザーへの確認は不要 — 種別判定に従ってそのまま調査を実行する
2. 対象リポジトリが CWD と異なる場合、パスを `ghq list --full-path --exact <リポジトリ名>` で解決する
   （es-account 配下に限らない。例: `squareWeb` → `~/ghq/gitlab.com/eseikatsu/es-square/squareWeb`）。
   解決できない（未 clone）場合は先にユーザーへ確認する
3. `mcp__claude_ai_GitLab__get_issue` で account-service#4228 を取得し、
   G1〜G8 のギャップ定義と 6 次元スコアカードを把握する

### 2. 並列調査

`resources/survey-prompts.md` の調査 A・調査 B のプロンプトに対象リポジトリの絶対パスを埋め込み、
**Explore サブエージェント 2 つを 1 メッセージで並列起動**する（run_in_background: false）。

- 調査 A（ハーネス構成）: 全リポジトリで実行。Skills/Hooks/サブエージェント定義・
  ナレッジ二層化の観点（output-format.md「ギャップ検出の必須観点」参照）を含む
- 調査 B（テスト現状）: コード・IaC リポジトリで実行（IaC は survey-prompts.md の
  種別別読み替えを適用）。文書リポジトリでは調査 B'（文書棚卸し）に置き換える
- 調査 C（個人環境の棚卸し）: オプション。ユーザーが「個人 skills も棚卸しして」
  「メモリの昇格候補も見て」等を求めた場合のみ、リポジトリ横断で 1 回実行する。
  削除・移設は提案のみとし、実施はユーザー確認後に行う

### 3. 手順書生成

調査結果を集約し、`resources/output-format.md` の §1〜§4 構成で手順書を書き出す。

- 保存先: スクラッチパッド（`<scratchpad>/issue-4228-<リポジトリ名>-procedure.md`）
- 事実にはファイルパスとバージョン番号を付け、推測には「要確認」と明記する
- H 番号（ギャップ）は output-format.md の「H 番号の粒度基準」に従って振り、G1〜G8 / Phase にマッピングする
- 6 次元スコアの仮スコアリングを含める
- **#4228 の対象範囲（es-account 5 リポジトリ）外のリポジトリの場合**、手順書冒頭とスコアカード節に
  「#4228 スコープ外・編入可否は要確認」の注記を入れる（例: 2026-07-06 の squareWeb 調査）

### 4. 報告とレビュー

1. 手順書のパスと要約（主要ギャップ・テスト空白・推奨着手順）をユーザーに報告する
2. **Issue への投稿はユーザー確認後に行う**。投稿時は markdown-hard-linebreak スキルで
   句点後ハード改行を整形し、#4228 のコメントまたは子 Issue として投稿する

## Examples

入力: `/harness-survey esa-apps`

出力（報告例・2026-07-04 実施分）:

```
手順書を作成しました: <scratchpad>/issue-4228-esa-apps-procedure.md
- ハーネスギャップ: H1〜H12（コミット形式 CI 未検証、カバレッジゲートなし、openapi→zod の drift チェックなし 等）
- テスト空白: esa-db-client（src 136 / test 0）、esa-hooks（52 / 4）、takken-api（16 / 0）
- 推奨着手順: ① esa-hooks + MSW 導入 → ② 生成物 drift チェック CI → ③ フロント 3 アプリの Playwright スモーク → ...
- メジャー遅れ: React 18 / MUI 5 / react-router 6 / zod 3 / Express 4 / Prisma 5 / thiserror 1 / edition 2021
#4228 への投稿は確認後に行います。
```

## Guidelines

- 調査は事実収集に徹し、サブエージェントには「事実のみを構造化して返す」よう指示する（プロンプトに記載済み）
- 横断一貫性（§構成・H 番号粒度・スコア次元）は `resources/output-format.md` の共通フォーマットで担保する。
  特定リポジトリの過去手順書を基準にしない（過去分は参考例にとどめる）
- Fable model での実行を推奨（長時間の自律実行・並列サブエージェントに強い）。
  調査開始前にタスク全体を把握してから着手し、途中でユーザーに小刻みな確認を求めない
- resources/ の分担: **種別汎用の読み替え**は `survey-prompts.md`、**リポジトリ固有事情・調査状態**は
  `target-repos.md`、**出力の基準（SSoT）**は `output-format.md`。対象リポジトリの追加・状態更新は
  target-repos.md のみを編集する（SKILL.md 本体は触らない）。
  未掲載リポジトリの単発調査では target-repos.md への追加は不要（種別判定でそのまま実行）。
  繰り返し調査するなら掲載する
