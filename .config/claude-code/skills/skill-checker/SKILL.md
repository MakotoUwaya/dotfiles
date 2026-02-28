---
name: skill-checker
description: Claude Code の SKILL.md を検証し、構文・命名・description の品質をチェックする。スキル追加・修正時のレビュー工程で使用。
---

# Skill Checker - スキル品質検証

## Overview

SKILL.md の品質を検証し、Claude が正しくスキルを認識・使用できるかチェックする。

## When to Use

以下の場合にこのスキルを必ず使用する：

- 新しい SKILL.md を作成したとき
- 既存スキルの description を変更したとき
- スキル数が増え、品質ばらつきが出始めたとき
- レビュー工程を自動化したいとき

## Check Targets

このスキルは、以下を対象にチェックを行う：

- ~/.claude/skills/ 以下に存在するすべてのスキル
- 新規作成された SKILL.md
- 既存スキルの修正差分（description / 構造変更を含む）

## Validation Rules

以下のルールに違反している場合、**修正が必要**と判断する。

### 1. Frontmatter Validation（必須）

- SKILL.md の先頭に YAML Frontmatter が存在する
- `---` で開始・終了している
- 必須キーが存在する
  - `name`
  - `description`

**NG例**
- Frontmatter が存在しない
- `description` が空、または抽象的すぎる

---

### 2. name ルール

- kebab-case であること
- 英小文字と `-` のみを使用
- 動作や用途が推測できる名前であること

**NG例**
- `SkillChecker`
- `checker_skill`
- `misc`

---

### 3. description 品質チェック（最重要）

description は以下をすべて満たす必要がある：

- **いつ使うか** が明確
- **何をするか** が具体的
- **どの文脈か**（ファイル種別・作業工程など）が含まれている

最低限含めるべき要素：
- 対象（例: APIレスポンス / Markdown / CSV）
- アクション（例: 検証する / 変換する / 整形する）
- 使用シーン（例: 開発時 / レビュー時 / バッチ処理）

**NG例**
```
description: スキルのチェック
```

**OK例**
```
description: Claude Code の SKILL.md を検証し、構文・命名・description の品質をチェックする。スキル追加・修正時のレビュー工程で使用。
```

---

### 4. セクション構成チェック

SKILL.md 本文に以下のセクションが存在すること：

- `## Overview`
- `## When to Use`
- `## Instructions`
- `## Examples`
- `## Guidelines`

不足している場合は **Warning** を出す。

---

### 5. Instructions の具体性

- 箇条書き、または番号付き手順で書かれている
- 判断条件（if / when / unless）が含まれている
- 曖昧語のみで構成されていない

**NG例**
```
状況に応じて適切に対応する
```

---

### 6. Examples の実在性

- 入力例と出力例がセットで書かれている
- 抽象プレースホルダのみになっていない

**NG例**
```
Input: XXX
Output: YYY
```

---

### 7. ディレクトリ構造チェック

- SKILL.md がルートに存在する
- `scripts/`, `resources/` が存在する場合：
  - SKILL.md から参照されている
  - 役割が明記されている

---

## Judgment Levels

チェック結果は以下の 3 段階で判定する：

- ✅ **PASS**: すべての必須ルールを満たしている
- ⚠️ **WARNING**: 品質向上の余地あり（description / Examples など）
- ❌ **FAIL**: 必須要件違反（Frontmatter / name / description）

---

## Output Format

結果は必ず以下の形式で出力する：

```
Skill Check Result: {PASS | WARNING | FAIL}

- Skill Name: {name}
- Issues:
  - [LEVEL] 内容
  - [LEVEL] 内容
- Suggested Fixes:
  - 修正案
```

## Guidelines

- 判断は **厳しめ** に行う
- 「なんとなく使えそう」は FAIL 寄りで評価
- description は Claude が使うための **トリガー定義** であることを忘れない
