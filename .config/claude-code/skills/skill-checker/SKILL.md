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

## Instructions

以下の手順でスキルを検証する:

1. `~/.claude/skills/` 配下の全スキルディレクトリを列挙する
2. 各スキルの `SKILL.md` を読み込む
3. 下記 Validation Rules の各ルール（1〜8）で検証する
4. Judgment Levels に基づき PASS / WARNING / FAIL を判定する
5. Output Format に従いレポートを出力する
6. 全スキルの検証完了後、総合サマリを出力する

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

#### リファレンス型スキルの例外

記法ルール集やコマンドリファレンスなど、**手順よりも参照情報が主体のスキル**は以下を許容する：

- `## Instructions` が無くても WARNING としない（本文自体が参照手順を兼ねるため）
- `## Examples` が無くても WARNING としない（記法例やコマンド例がセクション外に散在していれば十分）

リファレンス型かどうかの判断基準：
- description に「記法」「リファレンス」「コマンド集」等の語が含まれる
- 本文が主にテーブル・コードブロックの羅列で構成されている
- 手順（1→2→3）ではなく、項目の並列列挙が中心

#### 日本語見出しの例外

英語の標準セクション名と同等の役割を持つ日本語見出しは、対応するセクションが存在するものとみなす（欠落 WARNING としない）：

| 標準セクション | 同等とみなす日本語見出しの例 |
|---|---|
| `## Overview` | 概要 / 用途 / 背景 |
| `## When to Use` | 使いどころ / 対象 / トリガー |
| `## Instructions` | ワークフロー / 手順 / 実行方法 / プロセス / Step 1〜N |
| `## Examples` | 例 / 出力例 / 実行例 / Before・After |
| `## Guidelines` | 注意 / 注意事項 / 運用ルール / Notes |

機械的な見出し名の照合だけで判定せず、**本文の役割**（手順が番号付きで書かれているか、例が実在するか）で判断する。

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

### 7. description と本文の整合性チェック

description の記述と本文（Instructions / Examples / Guidelines）の内容が矛盾していないことを検証する。

チェック観点：
- description で「読み取り専用」「参照のみ」と記述しているのに、本文に書き込み・変更操作の例がある → **FAIL**
- description で「○○時に使用」と限定しているのに、本文がその範囲を超えた手順を含む → **WARNING**
- description に記載されたアクション（検証する / 変換する等）が、本文の Instructions で実際に手順化されていない → **WARNING**

**NG例**
```
description: GitLab CLI の読み取り操作専用リファレンス
## Examples に git push や MR 作成の例が含まれている
→ description と本文が矛盾
```

---

### 8. ディレクトリ構造チェック

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

## Examples

### 検証結果の例

```
Skill Check Result: WARNING

- Skill Name: my-skill
- Issues:
  - [WARNING] `## Instructions` セクションが存在しない
  - [WARNING] `## Examples` セクションが存在しない
- Suggested Fixes:
  - 具体的な手順を番号付きで記述した `## Instructions` セクションを追加する
  - 入力例と出力例のペアを含む `## Examples` セクションを追加する
```

### 総合サマリの例

```
合計: 11 件中 3 件 PASS / 8 件 WARNING / 0 件 FAIL
```

## Guidelines

- 判断は **厳しめ** に行う
- 「なんとなく使えそう」は FAIL 寄りで評価
- description は Claude が使うための **トリガー定義** であることを忘れない
