---
name: difit
description: |
  コード・文書の変更後、difit コマンドでユーザーにレビューを依頼する。変更実装の完了時、「レビュー」「difit」「レビュー依頼」で使用。
  After completing the requested implementation, use the difit command to ask the user for a code review.
---

This skill requests a code review from the user using the difit command.
If the user leaves review comments, they are printed to stdout when the difit command exits.
When review comments are returned, continue work and address them.
If the server is shut down without comments, treat it as "no review comments were provided."
文書レビューなど時間がかかる見込みの場合は、フォアグラウンド実行を避ける（下記 Commands の該当項目を参照）。

# Commands

- Review the HEAD commit: `difit --clean`
- Review uncommitted changes before commit: `difit . --clean`
- Untracked ファイルがある場合: `difit . --clean --include-untracked`
  - `--include-untracked` で untracked ファイルも自動的に diff に含める
  - 対象引数が `.` または `working` のときのみ有効
- **レビューに10分以上かかる見込みの場合**: バックグラウンド起動 → コメント取得の2段構えにする
  - 起動: `difit . --background`（既定ポートは 4966）
  - 取得: `difit comment get --port 4966`（レビュー完了をユーザーが知らせてから実行）
  - 停止: TaskStop にバックグラウンドタスク ID を渡す
  - フォアグラウンド実行は Bash ツールの実行上限（最大 600 秒）で SIGTERM され、レビュー途中でサーバーが落ちる
  - サーバーが落ちてもコメントは保持されるため、`--clean` を付けずに起動し直せば拾える（`--clean` を付けると消える）

## Basic Usage

```bash
difit <target>                    # View single commit diff
difit <target> [compare-with]     # Compare two commits/branches
```

## Single commit review

```bash
difit          # HEAD (latest) commit
difit 6f4a9b7  # Specific commit
difit feature  # Latest commit on feature branch
```

## Compare two commits

```bash
difit @ main         # Compare with main branch (@ is alias for HEAD)
difit feature main   # Compare branches
difit . origin/main  # Compare working directory with remote main
```

## Special Arguments

difit supports special keywords for common diff scenarios:

```bash
difit .        # All uncommitted changes (staging area + unstaged)
difit staged   # Staging area changes
difit working  # Unstaged changes only
```

## Useful Options

| Option | 用途 |
|--------|------|
| `--clean` | 既存コメント・viewed 状態をクリアして起動（レビュー依頼の基本） |
| `--include-untracked` | untracked ファイルも diff に含める（`.` / `working` のみ） |
| `--keep-alive` | ブラウザを閉じてもサーバーを継続（手動 Ctrl+C で停止） |
| `--background` | サーバーをバックグラウンドで起動し、接続情報を JSON で出力 |
| `--merge-base` | 比較ベースを `git merge-base` で解決して diff（Git revision モードのみ） |
| `--context <lines>` | 差分前後のコンテキスト行数を制限（`0` で変更行のみ） |
| `--pr <url>` | GitHub PR レビュー（`gh pr diff --patch` 経由、未解決の inline thread も取り込み） |
| `--comment <json>` | 起動時に初期レビューコメントを注入（thread / reply、繰り返し指定可） |

起動中のサーバーに対するコメント操作は `difit comment` サブコマンドで行う
（`add` / `get` / `resolve`）。いずれも `--port <port>` の指定が **必須**（既定ポートは 4966）。
省略すると `error: required option '--port <port>' not specified` になる。

**v5.0.0 の Breaking Change**: TUI モード (`--tui`) と `--mode <split|unified>` は削除された。
表示は Web UI のみ。

### 例: PR レビュー

```bash
difit --pr https://github.com/owner/repo/pull/123 --clean
```

### 例: feature ブランチを main からの分岐点で比較

```bash
difit feature main --merge-base
```

### 例: 初期コメント付きで起動

```bash
difit --comment '{"type":"thread","filePath":"src/example.ts","position":{"side":"new","line":10},"body":"この変更の背景は..."}'
```

# Constraints

Can only be used inside a Git-managed directory.
