---
name: memory-organizer
description: >
  MEMORY.md と詳細ファイルを多層構造化・抽象化する。
  frontmatter 欠如、インライン内容、カテゴリ未分類、索引タイトルの抽象性、相互リンク欠如を検出し、
  AI が効率的に recall できる索引+詳細の二層構造に整理する。
  「memory 整理」「MEMORY.md 整理」「メモリ構造化」「memory organizer」で使用。
---

# Memory Organizer

## Overview

プロジェクトの `~/.claude/projects/<project>/memory/` にある MEMORY.md と詳細ファイルを、
「索引は常に読み、詳細は必要なときだけ読む」二層構造の原則に基づいて整理する。

## When to Use

- 「memory 整理」「MEMORY.md を整理して」「メモリ構造化」
- memory ファイルが増えてきて整理したいとき
- 新しいプロジェクトで memory の土台を作りたいとき

## Instructions

### Step 1: memory ディレクトリの特定と読み取り

1. カレントディレクトリのパスから対応する memory ディレクトリを特定する
   - パス変換ルール: CWD のパス区切りを `--` に、`/` と `:` を `-` に変換
   - 例: `C:\Users\100508\ghq\github.com\Foo\bar` → `~/.claude/projects/C--Users-100508-ghq-github-com-Foo-bar/memory/`
2. `MEMORY.md`（索引）を Read する
3. 同ディレクトリの全 `.md` ファイル（MEMORY.md 以外）を Glob → Read する

### Step 2: 5つの観点で診断

各ファイルを以下の観点でチェックし、問題を収集する。

#### (a) frontmatter 欠如

詳細ファイルに以下の frontmatter が揃っているか確認:

```yaml
---
name: kebab-case-slug
description: 1行要約（AI の関連判定に使われる。具体的なツール名・関数名・キーワードを含める）
metadata:
  type: user | feedback | project | reference
---
```

- `name` がない → ファイル名から kebab-case slug を生成
- `description` がない → ファイル内容から1行要約を生成
- `type` がない → 内容から推定（手順・場所 → reference、やり方の指針 → feedback、ユーザー情報 → user、プロジェクト状況 → project）

#### (b) インライン内容

MEMORY.md に2行以上の実質的な内容（箇条書き・コードブロック等）が直書きされているエントリを検出。
索引は「1行 = 1メモ」が原則。詳細は別ファイルに分離すべき。

#### (c) カテゴリ未分類

MEMORY.md のエントリがフラットに並んでいる場合、内容に基づくカテゴリ分類を提案する。
カテゴリ名は技術領域（例: Git, Neovim, Docker, CI/CD）に基づいて決定する。

#### (d) 索引タイトルの抽象性

索引の見出しが抽象的で AI にヒットしにくいものを検出し、改善案を提案する。

改善の方向:
- 具体的なツール名・関数名・コマンド名を含める
- エラーメッセージのキーワードを含める
- AI が検索しそうな語彙に寄せる

例:
- NG: `conform.nvim` → OK: `conform.nvim lsp_format オプション`
- NG: `認証の設定` → OK: `git push 認証 (Windows=Credential Manager / WSL=PAT+direnv)`

#### (e) 相互リンク欠如

関連する詳細ファイル間に `[[name]]` リンクがない場合を検出し、追加を提案する。
同じツール・技術領域に属するファイルは相互リンクすべき。

### Step 3: 診断結果の表示

検出結果をカテゴリごとにテーブルで表示する:

```markdown
## 診断結果

### (a) frontmatter 欠如（N件）
| ファイル | 不足項目 | 提案値 |
|---------|---------|--------|
| neovim.md | name, description, type | name: neovim-plugin-pitfalls, type: reference |

### (b) インライン内容（N件）
| 索引エントリ | 行数 | 提案 |
|-------------|------|------|
| Git Push | 3行 | git-push-auth.md に分離 |

### (c) カテゴリ提案
| カテゴリ | 含まれるエントリ |
|---------|----------------|
| Git / バージョン管理 | git-push-auth, github-operations |

### (d) 索引タイトル改善（N件）
| 現在 | 改善案 |
|------|--------|
| conform.nvim | conform.nvim lsp_format オプション — v8 で非推奨 API 変更 |

### (e) 相互リンク追加（N件）
| ファイル | 追加リンク先 |
|---------|-------------|
| neovim.md | [[mason-troubleshooting]], [[conform-lsp-format]] |

### stale 警告（N件）
| ファイル | 経過日数 | 対応 |
|---------|---------|------|
| neovim.md | 137日 | 内容が現在のコードと一致するか要検証 |

**変更概要**: ファイル追加 N件、frontmatter 修正 N件、MEMORY.md 書き換え
```

### Step 4: ユーザー確認

AskUserQuestion で確認:
- 「上記の整理案を確認してください。スキップしたい項目があれば番号で指定してください。問題なければ『OK』で進めます。」

### Step 5: 整理の実行

ユーザー承認後、以下の順で実行する。

1. **インライン内容の分離**: MEMORY.md から抽出し、新しい詳細ファイルを Write で作成
2. **frontmatter の追加**: 既存ファイルに Edit で frontmatter を追加
3. **相互リンクの追加**: 関連ファイルの本文冒頭に `関連: [[name]]` 行を Edit で追加
4. **MEMORY.md の書き換え**: カテゴリ分類 + AI フレンドリーなタイトル + 1行フック形式に Write で更新

### Step 6: 完了報告

Before/After を簡潔に報告する:

```markdown
## 完了

- **Before**: 索引 N行（フラット）、詳細 N ファイル（frontmatter なし M件）
- **After**: 索引 N行（Kカテゴリ）、詳細 N ファイル（frontmatter 100%）、相互リンク M箇所追加
```

## 索引エントリのフォーマット規約

MEMORY.md の各エントリは以下の形式に統一する:

```markdown
- [AI検索しやすいタイトル (具体的なツール名/関数名)](detail-file.md) — 1行のフック文
```

- タイトルに具体的なツール名・コマンド名・キーワードを含める
- フック文は「なぜこの memory を読むべきか」が一瞬でわかる内容
- 200行を超えないよう、エントリは簡潔に保つ

## frontmatter の type 判定基準

| type | 内容の特徴 | 例 |
|------|-----------|-----|
| user | ユーザーの役割・好み・スキル | 「Go 歴10年、React 初心者」 |
| feedback | やり方の指針・修正指示 | 「テスト DB をモックしない」 |
| project | 進行中の取り組み・判断 | 「マージフリーズ 3/5 から」 |
| reference | 手順・場所・外部リソース | 「git push は PAT + direnv で」 |

## Examples

### Before: フラットな索引 + frontmatter なし

**MEMORY.md（索引）:**
```markdown
# Memory

## Git Push

- **Windows 環境**: Credential Manager が設定済みのため `git push` だけでOK
- **WSL 環境**: `.claude/rules/git-push.md` に従い、PAT + direnv で push

## Neovim プラグイン

- 詳細は [neovim.md](neovim.md) を参照

## conform.nvim

- v8 以降で `lsp_fallback = true` は非推奨 → `lsp_format = 'fallback'` を使う
```

**neovim.md（詳細ファイル・frontmatter なし）:**
```markdown
# Neovim プラグイン知見

## markdown-preview.nvim
- `build = "cd app && npm install"` は yarn.lock を変更しエラーの原因になる
...
```

### 診断結果

```markdown
### (a) frontmatter 欠如（1件）
| ファイル | 不足項目 | 提案値 |
|---------|---------|--------|
| neovim.md | name, description, type | name: neovim-plugin-pitfalls, type: reference |

### (b) インライン内容（2件）
| 索引エントリ | 行数 | 提案 |
|-------------|------|------|
| Git Push | 2行 | git-push-auth.md に分離 |
| conform.nvim | 1行 | conform-lsp-format.md に分離 |

### (c) カテゴリ提案
| カテゴリ | 含まれるエントリ |
|---------|----------------|
| Git / バージョン管理 | git-push-auth |
| Neovim | neovim-plugin-pitfalls, conform-lsp-format |

### (d) 索引タイトル改善（1件）
| 現在 | 改善案 |
|------|--------|
| conform.nvim | conform.nvim lsp_format オプション — v8 で非推奨 API 変更 |

**変更概要**: ファイル追加 2件、frontmatter 修正 1件、MEMORY.md 書き換え
```

### After: カテゴリ分類 + AI フレンドリーな索引

**MEMORY.md（索引）:**
```markdown
# Memory

## Git / バージョン管理

- [git push 認証 (Windows=Credential Manager / WSL=PAT+direnv)](git-push-auth.md) — OS ごとに認証方式が異なる

## Neovim

- [プラグインの落とし穴 (markdown-preview build / lazy.nvim cmd+opts)](neovim.md) — 設定変更前に確認
- [conform.nvim lsp_format オプション](conform-lsp-format.md) — v8 で lsp_fallback → lsp_format = 'fallback'
```

**neovim.md（frontmatter + 相互リンク付き）:**
```markdown
---
name: neovim-plugin-pitfalls
description: Neovim プラグインの落とし穴 — markdown-preview build 方式、lazy.nvim cmd+opts 関係
metadata:
  type: reference
---

# Neovim プラグイン知見

関連: [[conform-lsp-format]]

## markdown-preview.nvim
...
```

**conform-lsp-format.md（新規作成）:**
```markdown
---
name: conform-lsp-format
description: conform.nvim v8 で lsp_fallback が非推奨 — lsp_format = 'fallback' を使う
metadata:
  type: feedback
---

conform.nvim v8 以降、`lsp_fallback = true` は非推奨。`lsp_format = 'fallback'` を使う。

**Why:** API が変更され、旧オプション名では警告が出る。
**How to apply:** conform.nvim の format 設定を書く際、lsp_fallback ではなく lsp_format を使う。
```

## 注意事項

- memory ディレクトリが存在しない場合はエラーメッセージを出して終了する
- MEMORY.md が存在しない場合は「新規作成モード」として、既存の詳細ファイルから索引を生成する
- 既に整理済み（全ファイルに frontmatter あり、カテゴリ分類済み）の場合は「整理不要」と報告して終了する
- ファイルの内容自体（ナレッジの正確性）は変更しない。構造の整理のみ行う
