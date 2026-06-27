---
name: commit-and-push
description: コード変更のコミットとプッシュを一括実行する。「commit & push」「コミットして」「push して」等の指示で使用。
---

# Commit and Push

## Overview

変更内容を確認し、適切なコミットメッセージを生成してコミット・プッシュまで一括で行う。

## Instructions

以下の手順を **順番に** 実行する。`git add` と `git commit` は必ず別々の Bash 呼び出しで実行すること。

### 1. 状態確認（並列実行可）

- `git status` — 変更・未追跡ファイルの確認
- `git diff` — staged / unstaged の差分確認
- `git log --oneline -5` — 直近のコミットメッセージスタイル確認

### 2. コミット単位の分割

変更差分を目的別に分類し、**目的ごとに別コミット** にする。混ぜてはいけない。

- 変更の「意図」が異なるものは別コミットにする
- 例: 新機能追加 + 設定変更 + バグ修正 → 3コミット
- 後から `git log` で変更意図を追えることを最優先にする

### 3. コミット対象の判断

- 今回のタスクに関連するファイルのみをステージングする
- タスクと無関係な既存の変更は含めない
- `.env`、認証情報など秘密情報を含むファイルは除外する

### 4. ステージング

```bash
git add <対象ファイル1> <対象ファイル2> ...
```

- `git add -A` や `git add .` は使わない
- 結果を確認してから次へ進む

### 5. コミット

- `git log` の直近コミットに合わせたスタイルでメッセージを作成する
- 「何を変えたか」より「なぜ変えたか」を重視する

```bash
git commit -m "$(cat <<'EOF'
<簡潔な要約>

<必要に応じて補足説明>
EOF
)"
```

### 6. プッシュ

```bash
git push
```

- リモートブランチが未設定の場合は `git push -u origin <branch>` を使う
- force push は行わない（ユーザーが明示的に指示した場合のみ）

## Examples

### 単一コミット

差分: `works/activity-summary/202606/26.md` を新規追加

```bash
git add works/activity-summary/202606/26.md
```
```bash
git commit -m "$(cat <<'EOF'
6/26 アクティビティサマリを追加
EOF
)"
```

### 分割コミット

差分: SKILL.md の修正 + 新規スクリプト追加

```bash
git add .claude/skills/alert-triage/SKILL.md
```
```bash
git commit -m "$(cat <<'EOF'
alert-triage: GCP 調査手順にログフィルタ例を追記
EOF
)"
```
```bash
git add scripts/fetch_project_monitor.cjs
```
```bash
git commit -m "$(cat <<'EOF'
Splunk project-monitor 実績取得スクリプトを追加
EOF
)"
```

## Guidelines

- `git add` と `git commit` を `&&` で繋げない
- CWD のリポジトリに対して `git -C` を使わない
- 変更がない場合は空コミットせず、その旨を伝える
