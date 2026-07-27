---
name: skill-creator
description: 汎用的な作業パターンを発見した際に、再利用可能なClaude Codeスキルを新規生成する。作業完了時の振り返りや、繰り返し使えるワークフロー・ドメイン知識をスキル化する時に使用。既存スキルが古い・動かない場合の改善は skill-refiner、作成後の品質検証は skill-checker（本スキルは新規作成専用）。
---

# Skill Creator - スキル自動生成

## Overview

作業中に発見した汎用的なパターンを、再利用可能なClaude Codeスキルとして保存する。
これにより、同じ作業を繰り返す際の品質と効率が向上する。

## When to Use

以下の条件を満たす場合、スキル化を検討せよ：

1. **再利用性**: 他のプロジェクトでも使えるパターン
2. **複雑性**: 単純すぎず、手順や知識が必要なもの
3. **安定性**: 頻繁に変わらない手順やルール
4. **価値**: スキル化することで明確なメリットがある
5. **振り返り**: タスク完了後に「スキル化できるパターンはないか」を確認する

## Skill Structure

生成するスキルは以下の構造に従う：

```
skill-name/
├── SKILL.md          # 必須
├── scripts/          # オプション（実行スクリプト）
└── resources/        # オプション（参照ファイル）
```

## SKILL.md Template

```markdown
---
name: {skill-name}
description: {いつこのスキルを使うか、具体的なユースケースを明記}
---

# {Skill Name}

## Overview
{このスキルが何をするか}

## When to Use
{どういう状況で使うか、トリガーとなるキーワードや状況}

## Instructions
{具体的な手順}

## Examples
{入力と出力の例}

## Guidelines
{守るべきルール、注意点}
```

## Instructions

1. パターンの特定
   - 何が汎用的か
   - どこで再利用できるか

2. スキル名の決定
   - kebab-case を使用（例: api-error-handler）
   - 動詞+名詞 or 名詞+名詞

3. description の記述（最重要）
   - Claude がいつこのスキルを使うか判断する材料
   - 具体的なユースケース、ファイルタイプ、アクション動詞を含める
   - 悪い例: "ドキュメント処理スキル"
   - 良い例: "PDFからテーブルを抽出しCSVに変換する。データ分析ワークフローで使用。"

4. Instructions の記述
   - 明確な手順
   - 判断基準
   - エッジケースの対処

5. サブディレクトリの判断
   - `scripts/`: 実行可能なシェルスクリプトや C# コードがある場合に作成。SKILL.md 内でパスを参照すること
   - `resources/`: 参照用データ（テンプレート、設定例、ソース別手順等）がある場合に作成。SKILL.md 内で用途を明記すること
   - スキルが SKILL.md 単体で完結するなら、サブディレクトリは作らない

6. 保存
   - パス: ~/.claude/skills/{skill-name}/
   - 既存スキルと名前が被らないか確認

## Examples

### Example 1: SKILL.md 単体で完結するスキル

```markdown
---
name: meeting-notes-formatter
description: 議事録を標準フォーマットに変換する。参加者、決定事項、アクションアイテムを抽出・整理。会議後のドキュメント作成時に使用。
---

# Meeting Notes Formatter

## Overview
会議の生メモや音声書き起こしから、標準フォーマットの議事録を生成する。

## When to Use
- 会議後に議事録を作成するとき
- 「議事録」「meeting notes」で呼び出し

## Instructions
1. 入力テキストから参加者・日時・議題を抽出する
2. 決定事項とアクションアイテムを分離する
3. 標準テンプレートに整形して出力する

## Examples
（入力→出力の具体例）

## Guidelines
- アクションアイテムには必ず担当者と期限を付ける
```

### Example 2: scripts/ を持つスキル

```
excel-diff/
├── SKILL.md        # C# コードをインライン記述、scripts/ は不要
```

```
storage-cleanup/
├── SKILL.md        # scan/clean の呼び出し手順
└── scripts/        # scan.ps1, clean.ps1, scan.sh, clean.sh
    └── (SKILL.md で参照)
```

scripts/ を作る判断基準: コードが 50 行超、または bash/PowerShell 両対応で分岐が複雑な場合。短いコードは SKILL.md にインライン記述で十分。

## Guidelines

- このスキルは指示を受けた時、またはスキルとしての汎化が可能な時に使用する
- スキル生成時は以下の形式で報告：
  - 「スキルを生成しました。(New skill created!)」
  - スキル名: {name}
  - 用途: {description}
  - 保存先: {path}
