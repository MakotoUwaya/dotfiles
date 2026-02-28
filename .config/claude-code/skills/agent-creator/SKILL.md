---
name: agent-creator
description: Claude Code の SubAgent 定義ファイル (.md) を生成する際の仕様リファレンス。frontmatter フィールド、ツール一覧、設計パターン、プロンプト設計ガイドラインを提供。SubAgent 作成・レビュー時に使用。
user-invocable: false
---

# Agent Creator - SubAgent 仕様リファレンス

## Overview

Claude Code の SubAgent 定義ファイル (.md) を作成するための包括的な仕様リファレンス。frontmatter の全フィールド、利用可能なツール、モデル選択肢、設計パターン、プロンプト設計ガイドラインを1ファイルに集約。

## When to Use

- 新しい SubAgent を作成するとき
- 既存の SubAgent を修正・レビューするとき
- SubAgent の frontmatter 仕様を確認したいとき
- 適切なツールやモデルの選択に迷ったとき

---

## SubAgent 定義ファイルの基本構造

```markdown
---
name: agent-name
description: いつ・何を・どの文脈で使うか
tools: Read, Glob, Grep
model: inherit
---

ここにシステムプロンプトを記述する。
```

- ファイル形式: Markdown (.md)
- frontmatter: YAML（`---` で囲む）
- 本文: システムプロンプト（Markdown 記法可）

---

## Frontmatter フィールド一覧

| フィールド | 必須 | 型 | デフォルト | 説明 |
|-----------|:---:|-----|-----------|------|
| `name` | ✓ | string | - | `sub-ag-` プレフィックス付き kebab-case。一意の識別子 |
| `description` | ✓ | string | - | Claude がこのエージェントに委譲するタイミングの説明 |
| `tools` | - | string/array | 全ツール継承 | 使用可能ツールの許可リスト |
| `disallowedTools` | - | string/array | なし | 除外するツールの拒否リスト |
| `model` | - | string | `inherit` | 使用モデル |
| `maxTurns` | - | integer | 無制限 | agentic ターン数の上限 |
| `skills` | - | array | なし | 注入するスキル名の配列 |
| `memory` | - | string | なし | 永続メモリスコープ |
| `permissionMode` | - | string | `default` | パーミッションモード |
| `mcpServers` | - | object | なし | MCP サーバ設定 |
| `hooks` | - | object | なし | ライフサイクルフック |

---

## tools で指定可能な値

### コアツール

| ツール名 | 用途 | 読取専用 |
|---------|------|:-------:|
| `Read` | ファイル読み取り | ✓ |
| `Glob` | ファイルパターンマッチング | ✓ |
| `Grep` | ファイル内容検索 | ✓ |
| `Write` | ファイル書き込み（新規作成） | - |
| `Edit` | ファイル編集（既存ファイル） | - |
| `Bash` | ターミナルコマンド実行 | - |
| `WebFetch` | Web ページ取得 | ✓ |
| `WebSearch` | Web 検索 | ✓ |
| `Task` | subagent の生成 | - |

### Task ツールの制限指定

```yaml
# 特定の subagent のみ生成可能
tools: Task(worker, researcher), Read, Bash

# 全 subagent 生成可能
tools: Task, Read, Bash

# subagent 生成を禁止（Task を含めない）
tools: Read, Bash
```

### 指定方法

```yaml
# カンマ区切り（文字列）
tools: Read, Glob, Grep, Bash

# 配列形式
tools:
  - Read
  - Glob
  - Grep
  - Bash
```

---

## model の選択肢

| 値 | 説明 | 推奨用途 |
|---|------|---------|
| `haiku` | 高速・低コスト | 単純な読み取り、パターンマッチ、定型処理 |
| `sonnet` | バランス型 | コードレビュー、一般的な開発タスク |
| `opus` | 最高性能 | 複雑な設計、アーキテクチャ判断、創造的タスク |
| `inherit` | 親と同じモデル | デフォルト。ほとんどのケースで適切 |

---

## memory スコープ

| スコープ | 保存先 | VCS | 用途 |
|---------|-------|:---:|------|
| `user` | `~/.claude/agent-memory/{name}/` | - | 全プロジェクト横断の学習 |
| `project` | `.claude/agent-memory/{name}/` | ✓ | プロジェクト固有の知識 |
| `local` | `.claude/agent-memory-local/{name}/` | - | ローカル専用 |

---

## permissionMode

| モード | 動作 |
|--------|------|
| `default` | 標準的なパーミッション確認 |
| `acceptEdits` | ファイル編集を自動承認 |
| `dontAsk` | パーミッション確認を自動拒否 |
| `bypassPermissions` | 全確認スキップ（要注意） |
| `plan` | プランモード（読み取り専用探索） |

---

## 配置先と優先順位

| 優先度 | 場所 | スコープ |
|:-----:|------|---------|
| 1 | `--agents` CLI フラグ | セッション限定 |
| 2 | `.claude/agents/` | 現在のプロジェクト |
| 3 | `~/.claude/agents/` | 全プロジェクト共通 |
| 4 | プラグインの `agents/` | プラグイン有効時 |

同名の subagent が複数箇所に存在する場合、優先度の高い方が使用される。

---

## Instructions

SubAgent を作成する際は、以下の手順で進める:

1. **用途の定義**: エージェントの責任範囲と専門性を明確にする
2. **tools の選定**: 最小権限の原則に基づき、必要なツールのみ付与する
3. **model の選定**: タスクの複雑度に応じて haiku / sonnet / opus / inherit から選択する
4. **プロンプト作成**: 役割定義 → 手順 → 出力形式 → 注意事項の順で記述する
5. **配置**: `.claude/agents/`（プロジェクト）または `~/.claude/agents/`（全プロジェクト共通）に保存する
6. **検証**: 実際のタスクで動作を確認し、maxTurns やツール権限を調整する

---

## 設計パターン

### 1. 読み取り専用パターン

コードベースの調査・分析に使用。安全で副作用なし。

```markdown
---
name: sub-ag-code-analyzer
description: コードベースの構造分析と品質レポート生成。コードの理解や調査に使用
tools: Read, Glob, Grep
model: haiku
maxTurns: 15
---

コードベースを分析し、構造・依存関係・品質の観点からレポートを生成してください。

手順:
1. 対象ディレクトリの構造を Glob で把握
2. 主要ファイルを Read で確認
3. パターンや問題を Grep で検索
4. 結果をレポート形式で出力
```

### 2. 編集可能パターン

コード生成・修正を行う。Write/Edit を含む。

```markdown
---
name: sub-ag-test-generator
description: テストファイルの自動生成。新規コード作成後のテスト追加に使用
tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
maxTurns: 20
---

対象コードを分析し、テストファイルを生成してください。

手順:
1. 対象ファイルを Read で確認
2. テストフレームワークの設定を確認
3. テストファイルを Write で作成
4. Bash でテストを実行して動作確認
```

### 3. Skill プリロード型パターン

既存の Skill から専門知識を注入。

```markdown
---
name: sub-ag-api-developer
description: API エンドポイントの実装。REST API 開発時に使用
tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
skills:
  - api-conventions
  - error-handling
---

API 開発の専任者として、チーム規約に従ったエンドポイントを実装します。
skills で注入された規約を必ず参照してください。
```

### 4. Hook 付きパターン

ツール実行前のバリデーションを追加。

```markdown
---
name: sub-ag-safe-deployer
description: デプロイメント操作の安全な実行。本番環境へのデプロイ時に使用
tools: Read, Bash, Glob
model: sonnet
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-deploy.sh"
---

デプロイメントを安全に実行します。
全ての Bash コマンドは事前にバリデーションされます。
```

### 5. メモリ永続型パターン

セッション間で学習を保持。

```markdown
---
name: sub-ag-project-guide
description: プロジェクトの知識を蓄積・提供。プロジェクト固有の質問や新メンバーのオンボーディングに使用
tools: Read, Glob, Grep
model: inherit
memory: project
---

プロジェクトの知識ベースとして機能します。
重要な決定事項、アーキテクチャ選択、規約をメモリに記録し、
質問に対して蓄積された知識から回答します。
```

---

## プロンプト設計ガイドライン

### 構成の推奨順序

1. **役割定義** — エージェントの専門性と責任範囲
2. **手順** — 具体的なステップ（番号付き）
3. **出力形式** — 期待する出力のフォーマット
4. **注意事項** — 制約、禁止事項、エッジケース

### 良いプロンプトの特徴

- 具体的な手順が番号付きで記載されている
- 判断条件（if/when/unless）が明示されている
- 出力形式が定義されている
- エッジケースへの対応が記載されている

### プロンプト例

```
あなたは [役割] です。[責任範囲] を担当します。

## 手順

1. [具体的なステップ1]
2. [具体的なステップ2]
3. 条件分岐がある場合:
   - [条件A] → [アクションA]
   - [条件B] → [アクションB]

## 出力形式

[期待する出力のフォーマット]

## 注意事項

- [制約1]
- [禁止事項]
```

---

## アンチパターン

| パターン | 問題点 | 改善策 |
|---------|--------|--------|
| 抽象的な指示のみ | 「適切に対応して」では判断基準がない | 具体的な手順と判断条件を記載 |
| 過度に長いプロンプト | トークン消費が多く処理が遅い | 500行以内に簡潔にまとめる |
| ツールの過剰付与 | 不要なツールがあると意図しない操作のリスク | 最小権限の原則で必要なツールのみ |
| description が曖昧 | Claude が適切なタイミングで選択できない | 対象・アクション・使用シーンを含める |
| maxTurns 未設定 | 無限ループのリスク | 適切な上限を設定（15-30程度） |
| model の不適切な選択 | コスト超過 or 品質不足 | タスク複雑度に応じて選択 |

---

## Examples

### コードレビュアー

```markdown
---
name: sub-ag-code-reviewer
description: コード変更の品質レビュー。PR 作成前やコード変更後のレビューに使用
tools: Read, Glob, Grep
model: sonnet
maxTurns: 15
---

シニアコードレビュアーとして、コード変更をレビューしてください。

## レビュー観点

1. **正確性**: ロジックにバグがないか
2. **可読性**: 命名、構造、コメントは適切か
3. **セキュリティ**: OWASP Top 10 に該当する問題がないか
4. **パフォーマンス**: 明らかな性能問題がないか

## 出力形式

### レビュー結果

- **総合評価**: LGTM / 要修正 / 要議論
- **指摘事項**:
  - [重要度] ファイル:行番号 - 内容
- **改善提案**: （任意）
```

### テストランナー

```markdown
---
name: sub-ag-test-runner
description: テストの実行と結果分析。テスト失敗時の原因調査、テストカバレッジの確認に使用
tools: Read, Bash, Glob, Grep
model: haiku
maxTurns: 20
---

テスト実行の専門エージェントです。

## 手順

1. テストフレームワークの設定を確認（package.json, pytest.ini 等）
2. 指定されたテストを Bash で実行
3. 失敗したテストがあれば:
   - エラーメッセージを分析
   - 関連するソースコードを Read で確認
   - 原因と修正方針を報告
4. 全テスト通過なら結果サマリを報告

## 出力形式

- **実行結果**: PASS / FAIL
- **テスト数**: 成功 X / 失敗 Y / スキップ Z
- **失敗詳細**: （失敗時のみ）
```

### ドキュメント生成器

```markdown
---
name: sub-ag-doc-generator
description: コードからドキュメントを自動生成。API ドキュメント、README、関数リファレンスの作成に使用
tools: Read, Write, Glob, Grep
model: sonnet
maxTurns: 20
---

コードベースからドキュメントを生成する専門エージェントです。

## 手順

1. 対象コードを Read で分析
2. 公開 API、関数シグネチャ、型定義を抽出
3. 既存ドキュメントがあれば Read で確認し、スタイルを踏襲
4. ドキュメントを Write で生成

## ドキュメント構成

- 概要
- インストール / セットアップ
- 使い方（コード例付き）
- API リファレンス
- 設定オプション
```

---

## Guidelines

- **最小権限の原則**: 必要最小限のツールのみ付与する
- **description は具体的に**: 対象・アクション・使用シーンを必ず含める
- **maxTurns を設定**: 無限ループ防止のため 15-30 を推奨
- **プロンプトは簡潔に**: 500行以内を目標。長すぎるとトークン消費が増大
- **model はタスクに応じて選択**: 単純タスクは haiku、複雑タスクは opus
- **既存パターンを活用**: 5つの設計パターンから最適なものを選択
