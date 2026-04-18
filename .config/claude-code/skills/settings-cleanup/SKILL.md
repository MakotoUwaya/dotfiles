---
name: settings-cleanup
description: >
  settings.local.json の permissions.allow エントリを監査・整理する。
  一時的なパス固定エントリ、不正構文のエントリ、重複エントリを検出し、
  ユーザー承認のもとクリーンアップする。
  「settings cleanup」「パーミッション整理」「settings.local 整理」で使用。
---

# Settings Cleanup

プロジェクトの `.claude/settings.local.json` にある `permissions.allow` エントリを監査・整理する。

## ワークフロー

### Step 1: 読み取りと分類

`.claude/settings.local.json` を Read で読み、`permissions.allow` の各エントリを以下の4カテゴリに分類する。

#### PERMANENT（保持）

以下のパターンに該当するエントリ:

- MCP ツール許可: `mcp__*`
- 標準 git コマンド: `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git status:*)`, `Bash(git push:*)` 等
- 言語ランタイム: `Bash(node:*)`, `Bash(python3:*)`, `Bash(dotnet:*)`
- 標準ユーティリティ: `Bash(ls:*)`, `Bash(curl:*)`, `Bash(rg:*)`, `Bash(test:*)`, `Bash(cat:*)`
- WebFetch ドメイン: `WebFetch(domain:*)`
- WebSearch
- dotnet スキルスクリプト: `Bash(dotnet ~/.config/claude-code/skills/...)`, `Bash(dotnet .claude/skills/...)`
- difit コマンド: `Bash(difit .:*)`
- gws コマンド: `Bash(gws *:*)`
- Read パターン: `Read(//home/.../**)`
- クリップボード: `Bash(/mnt/c/Windows/System32/clip.exe:*)`、`Bash(iconv:*)`
- glab コマンド: `Bash(glab *:*)`
- npm コマンド: `Bash(npm run:*)`

#### TEMPORARY（削除候補）

以下のパターンに該当するエントリ:

- ハードコード絶対パスを含む `Bash(find ...)` や `Bash(grep ...)` コマンド
- `.claude/projects/` 配下の一時パスを含むエントリ
- `tool-results/` パスを含むエントリ
- 特定の JSON キーを操作する `Bash(jq ...)` コマンド
- 特定ファイルパスを含む `Bash(dotnet-script ...)` コマンド
- `/tmp/` ファイルを操作する `Bash(mv /tmp/...)` コマンド

#### MALFORMED（削除推奨）

以下のパターンに該当するエントリ:

- シェルループ断片: `Bash(while IFS= ...)`, `Bash(do echo ...)`, `Bash(done)`, `Bash(for dir:*)`, `Bash(do)`
- 不完全なコマンド: `Bash(echo "=== $dir ===")`
- 単体の `Bash(yes)`
- TZ プレフィックス付きコマンド: `Bash(TZ=Asia/Tokyo date ...)`（`Bash(date:*)` に統合可）

#### DUPLICATE（統合候補）

- ワイルドカード版と個別フラグ付きエントリが両方ある場合は個別版を削除
- 例: `Bash(cmd --flag1)` と `Bash(cmd --flag2)` は `Bash(cmd:*)` で統合可能

### Step 2: 分類結果の表示

4カテゴリそれぞれのエントリ一覧をテーブルで表示する:

```markdown
## 分類結果

### PERMANENT（保持: N件）
| # | エントリ |
|---|---------|
| 1 | ... |

### TEMPORARY（削除候補: N件）
| # | エントリ | 理由 |
|---|---------|------|
| 1 | ... | ハードコードパス |

### MALFORMED（削除推奨: N件）
| # | エントリ | 理由 |
|---|---------|------|
| 1 | Bash(do) | シェルループ断片 |

### DUPLICATE（統合候補: N件）
| # | エントリ | 統合先 |
|---|---------|--------|
| 1 | Bash(foo --flag) | Bash(foo:*) |

**Before**: XXX 件 → **After**: YYY 件（ZZZ 件削除予定）
```

### Step 3: ユーザー確認

AskUserQuestion で確認:
- 「上記の削除候補を確認してください。個別にスキップしたいエントリがあれば番号で指定してください。問題なければ『OK』と入力してください。」

### Step 4: クリーンアップ実行

1. ユーザー承認後、PERMANENT エントリのみを残して `settings.local.json` を書き換え
2. `permissions` 以外のフィールド（`additionalDirectories`, `enableAllProjectMcpServers`）はそのまま保持
3. エントリをカテゴリ内でアルファベット順にソート

### Step 5: 検証

- 書き換え後の `settings.local.json` を Read して JSON として valid であることを確認
- Before/After のエントリ数を報告

## 注意事項

- `permissions` 以外のトップレベルフィールドは一切変更しない
- 判断に迷うエントリはユーザーに個別確認する
- 作業前に `git status` で未コミットの変更がないことを確認する（settings.local.json は .gitignore 対象だが念のため）
